import Foundation
import WepinCommon

/// JSON-RPC 클라이언트 클래스
public class JsonRpcClient {
    private let rpcUrl: String
    private let session: URLSession
    private var requestId: Int = 0
    
    /// 초기화
    /// - Parameter rpcUrl: RPC 서버 URL
    public init(rpc: JsonRpcUrl) {
        if (rpc.type == "internal") {
            self.rpcUrl = "https://gateway.wepin.io" + rpc.url
        } else {
            self.rpcUrl = rpc.url
        }
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    /// JSON-RPC 호출을 수행하는 메서드
    /// - Parameters:
    ///   - method: 호출할 RPC 메서드 이름
    ///   - params: 메서드에 전달할 파라미터 (기본값: nil)
    /// - Returns: 호출 결과
    public func call<T>(_ method: String, _ params: [Any]? = nil) async throws -> T {
        do {
            let response = try await makeRpcRequest(method: method, params: params)
            guard let result = response as? T else {
                throw WepinError.parsingFailed("Could not convert result to expected type")
            }
            return result
        } catch {
            if let wepinError = error as? WepinError {
                throw wepinError
            } else {
                throw WepinError.networkError(error.localizedDescription)
            }
        }
    }
    
    /// 실제 RPC 요청을 수행하는 내부 메서드
    private func makeRpcRequest(method: String, params: [Any]?) async throws -> Any {
        guard let url = URL(string: rpcUrl) else {
//            throw WepinErro - error 추가 필요
            throw WepinError.unknown("Invalid Url")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 요청 본문 생성
        let requestBody: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": method,
            "params": params ?? []  // null이면 빈 배열
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // 네트워크 요청 수행
        let (data, response) = try await session.data(for: request)
        
        // HTTP 응답 확인
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WepinError.networkError("Invalid HTTP response")
        }
        
        if httpResponse.statusCode != 200 {
            throw WepinError.networkError("RPC request failed with code: \(httpResponse.statusCode)")
        }
        
        // JSON 응답 파싱
        guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw WepinError.parsingFailed("Invalid JSON response")
        }
        
        // 에러 응답 확인
        if let error = jsonResponse["error"] as? [String: Any] {
            let code = error["code"] as? Int ?? -1
            let message = error["message"] as? String ?? "Unknown error"
            throw JsonRpcException(message: message, code: code)
        }
        
        // 결과 확인
        guard jsonResponse.keys.contains("result") else {
            throw JsonRpcException(message: "No result field in response")
        }
        
        return jsonResponse["result"] ?? NSNull()
    }
}

/// JSON-RPC 에러 처리를 위한 예외 클래스
public class JsonRpcException: Error {
    public let message: String
    public let code: Int
    
    public init(message: String, code: Int = -1) {
        self.message = message
        self.code = code
    }
    
    public var localizedDescription: String {
        return "JSON-RPC Error: \(message) (Code: \(code))"
    }
}

// WepinError에 관련 오류 타입 추가 (이미 존재한다면 생략)
extension WepinError {
    public static func jsonRpcError(_ message: String, code: Int = -1) -> WepinError {
        return .networkError("JSON-RPC Error: \(message) (Code: \(code))")
    }
}
