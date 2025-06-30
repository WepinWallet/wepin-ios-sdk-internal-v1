import UIKit
import WebKit
import SafariServices

public class WepinModal: NSObject, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
    private var webView: WKWebView?
    private var viewController: UIViewController?
    private var modalVC: UIViewController?
    private var jsProcessor: ((String, WKWebView, @escaping (String) -> Void) -> Void)?
    
    private var overlayWindow: UIWindow?
    
    private var isModalActive: Bool = false
    private var isModalClosing: Bool = false
    
    public func openModal(on parent: UIViewController?, url: String, jsProcessor: @escaping (String, WKWebView, @escaping (String) -> Void) -> Void) {
        if isModalClosing {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.openModal(on: parent, url: url, jsProcessor: jsProcessor)
            }
            return
        }
        
        if isModalActive {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if !self.isModalActive {  // 그 사이에 닫혔으면
                    self.openModal(on: parent, url: url, jsProcessor: jsProcessor)
                }
            }
            return
        }
        
        self.jsProcessor = jsProcessor
        
        DispatchQueue.main.async {
            if self.isReactNativeEnvironment() {
                self.openInWindow(url: url)
                return
            }
            
            let presentingVC: UIViewController
            
            if let parent = parent, parent.view.window != nil {
                presentingVC = parent
            } else {
                if let visibleVC = self.findVisibleViewController() {
                    presentingVC = visibleVC
                } else {
                    self.openInWindow(url: url)
                    return
                }
            }
            
            if presentingVC.presentedViewController != nil {
                self.openInWindow(url: url)
                return
            }
            self.setupAndPresentNewModal(on: presentingVC, url: url)
        }
    }
    
    // React Native 환경 감지 (단순하고 확실한 방법)
    private func isReactNativeEnvironment() -> Bool {
        // RN 앱에서는 보통 RCT 관련 클래스들이 뷰 계층에 존재
        if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
           let rootVC = keyWindow.rootViewController {
            
            let rootClassName = String(describing: type(of: rootVC))
            
            // React Native의 대표적인 클래스들 확인
            if rootClassName.contains("RCT") ||
                rootClassName.contains("React") ||
                rootClassName.contains("RN") {
                return true
            }
            
            // 뷰 계층에서 RN Modal 확인
            return hasReactNativeViewInHierarchy(keyWindow)
        }
        
        return false
    }
    
    private func hasReactNativeViewInHierarchy(_ view: UIView) -> Bool {
        let className = String(describing: type(of: view))
        
        // RN 관련 클래스명 확인
        if className.contains("RCT") || className.contains("React") {
            return true
        }
        
        // 자식 뷰들 확인 (최대 3단계까지만)
        for subview in view.subviews.prefix(10) { // 성능을 위해 최대 10개만
            if hasReactNativeViewInHierarchy(subview) {
                return true
            }
        }
        
        return false
    }
    
    public func closeModal() {
        guard isModalActive else { return }  // 이미 닫혔으면 무시
        isModalClosing = true
        
        DispatchQueue.main.async {
            self.isModalActive = false
            // 1. 웹뷰 정리 - 항상 수행
            if let webView = self.webView {
                webView.stopLoading() // 먼저 로딩 중지
                webView.configuration.userContentController.removeAllUserScripts() // 모든 스크립트 제거
                webView.configuration.userContentController.removeScriptMessageHandler(forName: "post")
                webView.removeFromSuperview()
                self.webView = nil
            }
            
            // 3. UIWindow 정리 - 존재하면 수행
            if let window = self.overlayWindow {
                window.isHidden = true
                self.overlayWindow = nil
            }
            
            // 4. 모달 정리 - 모달이 있고 다른 VC에 의해 표시된 경우에만 수행
            if let modalVC = self.modalVC,
               modalVC.presentingViewController != nil,
               self.overlayWindow == nil { // UIWindow 방식이 아닌 경우에만
                
                // 안전한 dismiss - 뷰 계층 구조 확인
                if modalVC.view.window != nil {
                    modalVC.dismiss(animated: true) {
                        self.isModalActive = false
                        self.isModalClosing = false
                    }
                } else {
                    self.isModalActive = false
                    self.isModalClosing = false
                }
            } else {
                self.isModalActive = false
                self.isModalClosing = false
            }
            
            // 5. 모달 참조 정리 - 항상 수행
            self.modalVC = nil
        }
    }
    
    // MARK: - JavaScript Handler
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "post", let body = message.body as? String {
            jsProcessor?(body, webView!) { [weak self] response in
                self?.callJavascript(method: "onResponse", args: [response])
            }
        }
    }
    
    private func findVisibleViewController() -> UIViewController? {
        // 1. 키 윈도우 찾기
        guard let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }
        
        // 2. 루트 뷰 컨트롤러 가져오기
        guard var rootVC = keyWindow.rootViewController else {
            return nil
        }
        
        // 3. 최상위 뷰 컨트롤러 찾기
        var currentVC = rootVC
        while let presentedVC = currentVC.presentedViewController {
            currentVC = presentedVC
        }
        
        // 4. 네비게이션 컨트롤러 또는 탭 바 컨트롤러 확인
        if let navVC = currentVC as? UINavigationController {
            return navVC.visibleViewController ?? navVC
        } else if let tabVC = currentVC as? UITabBarController {
            return tabVC.selectedViewController ?? tabVC
        }
        
        return currentVC
    }
    
    private func openInWindow(url: String) {
        print("Opening in UIWindow as fallback")
        
        // 기존 리소스 정리
        self.webView?.removeFromSuperview()
        self.webView = nil
        
        // 이미 윈도우가 있으면 닫기
        if let existingWindow = self.overlayWindow {
            existingWindow.isHidden = true
            self.overlayWindow = nil
        }
        
        // 윈도우 생성
        let window: UIWindow
        if #available(iOS 13.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes
                .filter({ $0.activationState == .foregroundActive })
                .first as? UIWindowScene {
                window = UIWindow(windowScene: windowScene)
            } else {
                window = UIWindow(frame: UIScreen.main.bounds)
            }
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)
        }
        
        // 최상위 레벨로 설정
        window.windowLevel = UIWindow.Level.alert + 1
        
        // 루트 뷰 컨트롤러 생성
        let rootVC = UIViewController()
        rootVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.7) // 불투명도 증가
        window.rootViewController = rootVC
        
        // 웹뷰 설정
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(self, name: "post")
        config.userContentController = contentController
        config.preferences.javaScriptEnabled = true
        config.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        self.webView = webView
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = true // 스크롤 가능하게 설정
        webView.scrollView.bounces = true
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        // 뷰에 추가
        rootVC.view.addSubview(webView)
        
        // 제약조건 설정
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: rootVC.view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: rootVC.view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: rootVC.view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: rootVC.view.bottomAnchor),
        ])
        
        // 윈도우 표시
        window.makeKeyAndVisible()
        self.overlayWindow = window
        self.modalVC = rootVC
        //                self.modalPresentedSuccessfully = true
        isModalActive = true
        print("UIWindow fallback displayed successfully")
    }
    
    private func setupAndPresentNewModal(on parent: UIViewController, url: String) {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(self, name: "post")
        config.userContentController = contentController
        config.preferences.javaScriptEnabled = true
        config.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        self.webView = webView
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        //            if #available(iOS 16.4, *) {
        //                webView.isInspectable = true
        //            }
        
        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        let modalVC = UIViewController()
        modalVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        modalVC.modalPresentationStyle = .overFullScreen//.fullScreen
        modalVC.view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: modalVC.view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: modalVC.view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: modalVC.view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: modalVC.view.bottomAnchor)
        ])
        
        parent.present(modalVC, animated: true) { [weak self] in
            self?.isModalActive = true
        }
        
        self.modalVC = modalVC
    }
    
    private func callJavascript(method: String, args: [String]) {
        let params = args.map { "'\($0.replacingOccurrences(of: "'", with: "\\'"))'" }.joined(separator: ",")
        let js = "try {\(method)(\(params));} catch (e) { console.error(e); }"
        DispatchQueue.main.async {
            self.webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }
    
    // ✅ ✅✅ window.open() 대응
    public func webView(_ webView: WKWebView,
                        createWebViewWith configuration: WKWebViewConfiguration,
                        for navigationAction: WKNavigationAction,
                        windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            print("window.open intercepted: \(url)")
            openInExternalBrowser(url: url)
        }
        return nil
    }
    
    // MARK: - Navigation Delegate (optional)
    //    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
    //                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    //        if let url = navigationAction.request.url, !url.absoluteString.hasPrefix("http") {
    //            openInExternalBrowser(url: url)
    //            decisionHandler(.cancel)
    //        } else {
    //            decisionHandler(.allow)
    //        }
    //    }
    
    //    public func openInExternalBrowser(url: URL) {
    //        if let topVC = modalVC {
    //            let safariVC = SFSafariViewController(url: url)
    //            topVC.present(safariVC, animated: true, completion: nil)
    //        }
    //    }
    
    public func openInExternalBrowser(url: URL) {
        guard let topVC = modalVC ?? UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }
        
        DispatchQueue.main.async {
            let safariVC = SFSafariViewController(url: url)
            if topVC.presentedViewController == nil {
                topVC.present(safariVC, animated: true, completion: nil)
            } else {
                topVC.presentedViewController?.present(safariVC, animated: true, completion: nil)
            }
        }
    }
}
