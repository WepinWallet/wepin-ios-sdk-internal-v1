//
//  WepinStorage.swift
//  WepinStorage
//
//  Created by iotrust on 6/13/24.
//

import Foundation
import Security

public class WepinStorage {
    public static let shared = WepinStorage()
    
    private var appId: String = ""
    private var sdkType: String = ""
    private let prevSevicePrefix: String = "wepin" + (Bundle.main.bundleIdentifier ?? "")
    private let cookie_name = "wepin:auth:"
    private var prevServiceId: String = ""
    
    private let wepinStorageManager = WepinStorageManager()
    
    
    public func initManager(appId: String, sdkType: String? = "ios") {
        self.appId = appId
        self.sdkType = sdkType ?? "ios"
        if(sdkType == "flutter") {
            self.prevServiceId = "flutter_secure_storage_service"
        } else if(sdkType == "react") {
            self.prevServiceId = "wepin" + (Bundle.main.bundleIdentifier ?? "")
        } else {
            self.prevServiceId = prevSevicePrefix + appId
        }
        
        migrateOldStorage()
        
        let hasLoginInfo = getStorage(key: "wepin:connectUser", type: StorageDataType.WepinToken.self) != nil
//        print("hasLoginInfo: \(hasLoginInfo)")
        
        let installState = AppInstallTracker.detectInstallState(hasLoginInfo: hasLoginInfo)
//        print("🚀 앱 상태: \(installState)")
        
        switch installState {
        case .firstInstall, .reInstall:
            deleteAllStorage()
        case .update, .normalRun:
            break // 아무것도 하지 않음
        }
        
        AppInstallTracker.prepareInstallIdIfNeeded()
    }
    
    // 앱이 처음 실행되는지 확인하는 함수
    func isFirstLaunchAfterReinstall() -> Bool {
        let key = "wepin_\(Bundle.main.bundleIdentifier ?? "default")"
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: key)
        
        if hasLaunchedBefore {
            return false
        } else {
            UserDefaults.standard.set(true, forKey: key)
            return true
        }
    }
    
    func isFirstLaunchOfCurrentVersion() -> Bool {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
        let key = "wepin_version_check_key"
        let savedVersion = UserDefaults.standard.string(forKey: key)
        
        if savedVersion == currentVersion {
            return false // 이미 이 버전에서 실행한 적 있음
        } else {
            // 새 버전으로 업데이트되었거나 처음 실행임
            UserDefaults.standard.set(currentVersion, forKey: key)
            return true
        }
    }
    
    //Migration Logic
    private func migrateOldStorage() {
        guard getStorage(key: "migration") as? String != "true" else { return }
        if sdkType == "react" {
            reactPrevStorageReadAll()
        } else {
            prevStorageReadAll()
        }
        setStorage(key: "migration", data: "true")
        _ = getAllStorage()
        prevDeleteAll()
    }
    
    private func prevStorageReadAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: prevServiceId,
            kSecReturnAttributes as String: kCFBooleanTrue!,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        var items: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &items)
        guard status == errSecSuccess, let itemArray = items as? [[String: Any]] else {
            print("Error reading from keychain: \(status)")
            return
        }
        
        let WEPIN_KEY_PREFIX = "wepin_store_" + appId + "_"
        
        itemArray.forEach { item in
            if var key = item[kSecAttrAccount as String] as? String,
               let data = item[kSecValueData as String] as? Data {
                if(key.starts(with: WEPIN_KEY_PREFIX)) {
                    key = key.replacingOccurrences(of: WEPIN_KEY_PREFIX, with: "")
                }
                setStorage(key: key, data: data)
            }
        }
        
        for item in itemArray {
            if let key = item[kSecAttrAccount as String] as? String,
               let data = item[kSecValueData as String] as? Data {
                
                // JSON 문자열을 딕셔너리로 변환
                let jsonString = String(data: data, encoding: .utf8) ?? "{}"
                do {
                    if let jsonData = jsonString.data(using: .utf8),
                       let dictionary = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                        for (dictKey, value) in dictionary {
                            // 각 값 타입에 따른 처리
                            if let dataValue = value as? Data {
                                setStorage(key: dictKey, data: dataValue)
                            } else if let stringValue = value as? String {
                                setStorage(key: dictKey, data: stringValue)
                            } else if let dictValue = value as? [String: Any] {
                                do {
                                    let jsonData = try JSONSerialization.data(withJSONObject: dictValue, options: [])
                                    setStorage(key: dictKey, data: jsonData)
                                } catch {
                                    print("Failed to convert Dictionary to JSON: \(error)")
                                }
                            } else {
                                print("Unsupported data type \(dictKey) = \(value)")
                            }
                        }
                    } else {
                        print("Not supported data type: \(jsonString)")
                    }
                } catch {
                    print("JSON parsing error: \(error)")
                }
            }
        }
    }
    
    private func reactPrevStorageReadAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: prevServiceId,
            kSecReturnAttributes as String: kCFBooleanTrue!,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        var items: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &items)
        guard status == errSecSuccess, let itemArray = items as? [[String: Any]] else {
            print("Error reading React style from keychain: \(status)")
            return
        }
        for item in itemArray {
                if let key = item[kSecAttrAccount as String] as? String,
                   key.hasPrefix(cookie_name),
                   let data = item[kSecValueData as String] as? Data {
                    // React Native 방식에서는 appId가 키에 포함됨
                    var reactAppId = String(key.dropFirst(cookie_name.count))
                    
                    // JSON 문자열을 딕셔너리로 변환
                    let jsonString = String(data: data, encoding: .utf8) ?? "{}"
                    do {
                        if let jsonData = jsonString.data(using: .utf8),
                           let dictionary = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                            for (dictKey, value) in dictionary {
                                // 각 값 타입에 따른 처리
                                if let dataValue = value as? Data {
                                    setStorage(key: dictKey, data: dataValue)
                                } else if let stringValue = value as? String {
                                    setStorage(key: dictKey, data: stringValue)
                                } else if let dictValue = value as? [String: Any] {
                                    do {
                                        let jsonData = try JSONSerialization.data(withJSONObject: dictValue, options: [])
                                        setStorage(key: dictKey, data: jsonData)
                                    } catch {
                                        print("Failed to convert Dictionary to JSON: \(error)")
                                    }
                                } else {
                                    print("Unsupported data type \(dictKey) = \(value)")
                                }
                            }
                        } else {
                            print("Not supported data type: \(jsonString)")
                        }
                    }
                }
            }
    }
    
    private func prevDeleteAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: prevServiceId
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess {
            print("Error deleting from keychain: \(status)")
        }
    }
    
    private func encodeData<T: Codable>(value: T) -> Data? {
        // Dictionary 타입인 경우 (JSON으로 변환)
        if let jsonValue = value as? [String: Any] {
            return try? JSONSerialization.data(withJSONObject: jsonValue, options: [])
        }
        
        // String 타입인 경우
        if let stringValue = value as? String {
            return stringValue.data(using: .utf8)
        }
        
        // Data 타입인 경우
        if let dataValue = value as? Data {
            return dataValue
        }
        
        
        
        // Int 타입인 경우 (바이트 배열로 변환)
        if let intValue = value as? Int {
            var intData = intValue
            return Data(bytes: &intData, count: MemoryLayout.size(ofValue: intData))
        }
        
        // Codable 타입인 경우 (JSON으로 변환)
        do {
            return try JSONEncoder().encode(value)
        } catch {
            return nil
        }
        
        
        // 변환할 수 없는 경우 nil 반환
        //        return nil
    }
    
    func decodeData(data: Data) -> Any? {
        
        // Data를 JSON으로 변환 시도
        if let jsonValue = try? JSONSerialization.jsonObject(with: data, options: []),
           let dictionaryValue = jsonValue as? [String: Any] {
//            print("jsonValue: \(jsonValue)")
//            print("dictionaryValue: \(dictionaryValue)")
            return dictionaryValue
        }
        
        // Data를 Int로 변환 시도
        if data.count == MemoryLayout<Int>.size {
            var intValue: Int = 0
            _ = withUnsafeMutableBytes(of: &intValue) { data.copyBytes(to: $0) }
//            print("intValue: \(intValue)")
            return intValue
        }
        
        // Data를 String으로 변환 시도
        if let stringValue = String(data: data, encoding: .utf8) {
//            print("stringValue: \(stringValue)")
            return stringValue
        }
        
        // 변환할 수 없는 경우 nil 반환
        return nil
    }
    public func setStorage<T: Codable&Any>(key: String, data: T) {
        let keychainData = encodeData(value: data)
//        print("🚀 setStorage key: \(key)")
//        print("🚀 setStorage data: \(keychainData)")
        wepinStorageManager.write(appId: appId, key: key, data: keychainData!)
    }
    
    public func getStorage<T: Decodable>(key: String, type: T.Type) -> T? {
        guard  let data = wepinStorageManager.read(appId: appId, key: key) else {
                        print("Error fetching data from keychain")
            return nil
        }
        
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        } catch let decodeError as DecodingError {
            switch decodeError {
            case .typeMismatch(let type, let context):
                print("❌ Type mismatch: \(type), context: \(context)")
            case .valueNotFound(let type, let context):
                print("❌ Value not found: \(type), context: \(context)")
            case .keyNotFound(let key, let context):
                print("❌ Key not found: \(key), context: \(context)")
            case .dataCorrupted(let context):
                print("❌ Data corrupted: \(context)")
            @unknown default:
                print("❌ Unknown decoding error: \(decodeError)")
            }
        } catch {
            print("❌ Other decoding error: \(error.localizedDescription)")
        }
        
        return nil
    }
    public func getStorage(key: String) -> Any? {
                print("🚀 getStorage key: \(key)")
        
        guard  let data = wepinStorageManager.read(appId: appId, key: key) else {
            print("Error fetching data from keychain: data")
            return nil
        }
        
        //        print("🚀 getStorage data: \(data)")
        return decodeData(data: data)
        //        return try? JSONSerialization.jsonObject(with: data, options: [])
    }
    
    public func deleteStorage(key: String) {
        wepinStorageManager.delete(appId: appId, key: key)
    }
    
    public func setAllStorage(data: [String: Codable&Any]) {
        for (key, value) in data {
            setStorage(key: key, data: value)
        }
    }
    
    public func getAllStorage() -> [String: Any] {
        return wepinStorageManager.readAll(appId: appId).reduce(into: [:]) { result, item in
            //            print("🚀 getAllStorage item.key: \(item.key)")
            //            print("🚀 getAllStorage item.value: \(item.value)")
            if let data = item.value {
                result[item.key] = decodeData(data: data)
            }
        }
    }
    
    public func deleteAllStorage() {
        wepinStorageManager.deleteAll()
        // for 마이그레이션& restore test
        //        AppInstallTracker.deleteInstallIdFromKeychain()
        // test 시 해당 내용 주석
        setStorage(key: "migration", data: "true")
    }
}

public struct StorageDataType {
    public struct FirebaseWepin : Codable{
        public let idToken: String
        public let refreshToken: String
        public let provider: String
        
        public init(idToken: String, refreshToken: String, provider: String) {
            self.idToken = idToken
            self.refreshToken = refreshToken
            self.provider = provider
        }
    }
    
    public struct WepinToken : Codable{
        public let accessToken: String
        public let refreshToken: String
        
        public init(accessToken: String, refreshToken: String) {
            self.accessToken = accessToken
            self.refreshToken = refreshToken
        }
    }
    
    public struct UserStatus : Codable{
        public let loginStatus: String
        public let pinRequired: Bool?
        
        public init(loginStatus: String, pinRequired: Bool?) {
            self.loginStatus = loginStatus
            self.pinRequired = pinRequired
        }
    }
    
    public struct UserInfo : Codable{
        public let status: String
        public let userInfo: UserInfoDetails
        public let walletId: String?
        
        public init(status: String, userInfo: UserInfoDetails, walletId: String? = nil) {
            self.status = status
            self.userInfo = userInfo
            self.walletId = walletId
        }
    }
    
    public struct UserInfoDetails : Codable {
        public let userId: String
        public let email: String
        public let provider: String
        public let use2FA: Bool
        
        public init(userId: String, email: String, provider: String, use2FA: Bool) {
            self.userId = userId
            self.email = email
            self.provider = provider
            self.use2FA = use2FA
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            userId = try container.decode(String.self, forKey: .userId)
            email = try container.decode(String.self, forKey: .email)
            provider = try container.decode(String.self, forKey: .provider)
            
            // ✅ use2FA: Bool 또는 Int → Bool로 처리
            if let boolValue = try? container.decode(Bool.self, forKey: .use2FA) {
                use2FA = boolValue
            } else if let intValue = try? container.decode(Int.self, forKey: .use2FA) {
                use2FA = (intValue != 0)
            } else {
                use2FA = false // fallback default
            }
        }
        
        private enum CodingKeys: String, CodingKey {
            case userId
            case email
            case provider
            case use2FA
        }
    }
    
    public struct WepinSelectedAddress: Codable {
        public let userId: String
        public let network: String
        public var address: String
        
        public init(userId: String, network: String, address: String) {
            self.userId = userId
            self.network = network
            self.address = address
        }
    }
}

