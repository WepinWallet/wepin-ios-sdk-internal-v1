//
//  ViewController.swift
//  WepinStorage
//
//  Created by hyunjung on 03/10/2025.
//  Copyright (c) 2025 hyunjung. All rights reserved.
//

import UIKit
import WepinStorage

class ViewController: UIViewController {
    let resultLabel = UILabel()
    let stackView = UIStackView()

    let appKey: String = "ak_dev_MuIgndihqglPDGHiRT4wd6G4MwZfvJeOLJn7wd36SQP"
    let appId: String = "a840783376386107736eed117085db29"
    let privateKey: String = "57baa4b03a579b2b8a9e139cf72284cd317f9c82214f40b69f9f180f6d68cbb6"
    
    
    let googleClientId: String = "914682313325-c9kqcpmh0vflkqflsgh6cp35b4ife95q.apps.googleusercontent.com"
    let appleClientId: String = "appauth.wepin"
    let discordClientId: String = "1244924865098551296"
    let naverClientId: String = "TzwZUy3ZtAK5mxOsik9P"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = .systemBackground
        setupUI()
    }
    
    private func setupUI() {
            stackView.axis = .vertical
            stackView.spacing = 12
            stackView.translatesAutoresizingMaskIntoConstraints = false

            let buttons: [(String, Selector)] = [
                ("1. Init Manager", #selector(initManager)),
                ("2. Set Storage (String)", #selector(setStorage)),
                ("3. Get Storage (String)", #selector(getStorage)),
//                ("4. Set Storage (Codable)", #selector(setCodable)),
                ("5. Get Storage (Codable)", #selector(getCodable)),
                ("6. Get All Storage", #selector(getAllStorage)),
                ("7. Delete Storage", #selector(deleteStorage)),
                ("8. Delete All Storage", #selector(deleteAllStorage))
            ]

            for (title, action) in buttons {
                let button = UIButton(type: .system)
                button.setTitle(title, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
                button.addTarget(self, action: action, for: .touchUpInside)
                button.heightAnchor.constraint(equalToConstant: 40).isActive = true
                stackView.addArrangedSubview(button)
            }

            resultLabel.text = "결과 출력 영역"
            resultLabel.numberOfLines = 0
            resultLabel.textAlignment = .center
            resultLabel.textColor = .darkGray
            resultLabel.font = UIFont.systemFont(ofSize: 15)
            stackView.addArrangedSubview(resultLabel)

            view.addSubview(stackView)
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
                stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
            ])
        }

        @objc func initManager() {
//            WepinStorage.shared.initManager(appId: appId)
            WepinStorage.shared.initManager(appId: appId, sdkType: "flutter")
//            WepinStorage.shared.initManager(appId: appId, sdkType: "ios")
            resultLabel.text = "✅ initManager 호출 완료"
        }

        @objc func setStorage() {
            WepinStorage.shared.setStorage(key: "testKey", data: "Hello Wepin!")
            resultLabel.text = "✅ String 저장 완료"
        }

        @objc func getStorage() {
            if let value = WepinStorage.shared.getStorage(key: "testKey") as? String {
                resultLabel.text = "📥 getStorage 결과: \(value)"
            } else {
                resultLabel.text = "❌ 저장된 데이터 없음"
            }
        }
//
//        @objc func setCodable() {
//            let token = StorageDataType.WepinToken(accessToken: "abc123", refreshToken: "ref456")
//            WepinStorage.shared.setStorage(key: "token", data: token)
//            resultLabel.text = "✅ Codable 저장 완료"
//        }

        @objc func getCodable() {
            if let token: StorageDataType.WepinToken = WepinStorage.shared.getStorage(key: "token", type: StorageDataType.WepinToken.self) {
                resultLabel.text = "📥 Token 결과: accessToken=\(token.accessToken), refreshToken=\(token.refreshToken)"
            } else {
                resultLabel.text = "❌ Token 가져오기 실패"
            }
        }

        @objc func getAllStorage() {
            let all = WepinStorage.shared.getAllStorage()
            resultLabel.text = "📦 전체 스토리지: \(all)"
        }

        @objc func deleteStorage() {
            WepinStorage.shared.deleteStorage(key: "testKey")
            resultLabel.text = "🗑️ testKey 삭제 완료"
        }

        @objc func deleteAllStorage() {
            WepinStorage.shared.deleteAllStorage()
            resultLabel.text = "🗑️ 전체 삭제 완료"
        }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

