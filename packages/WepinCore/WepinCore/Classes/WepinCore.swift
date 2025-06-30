import Foundation
import WepinCommon

public class WepinCore {
    public static let shared = WepinCore()
    
    // MARK: - Properties
    private var _initialized: Bool = false
    private var appKey: String = ""
    private var domain: String = ""
    private var sdkType: String = ""
    private var version: String = ""
    
    private init() {}
    
    // MARK: - Initialization
    public func initialize(appId: String, appKey: String, domain: String, sdkType: String, version: String) async throws {
        if _initialized { return }
        
        self.appKey = appKey
        self.domain = domain
        self.sdkType = sdkType
        self.version = version
        
        // Initialize Storage component
        WepinStorage.shared.initManager(appId: appId, sdkType: sdkType)
        
        // Initialize Session component
        WepinSessionManager.shared.initialize(appId: appId, sdkType: sdkType)
        do {
            try WepinNetwork.shared.initialize(appKey: appKey, domain: domain, sdkType: sdkType, version: version)
            
            async let appInfoTask = WepinNetwork.shared.getAppInfo()
            async let firebaseConfigTask = WepinNetwork.shared.getFirebaseConfig()
            
            let (_, firebaseKey) = try await (appInfoTask, firebaseConfigTask)
            // Initialize Firebase Network
            WepinFirebaseNetwork.shared.initialize(firebaseKey: firebaseKey)
        } catch {
            self.finalize()
            throw error
        }
        
        _initialized = true
    }
    
    public func createJsonRpcClient(rpc: JsonRpcUrl) -> JsonRpcClient {
        return JsonRpcClient(rpc: rpc)
    }
    
    public func finalize() {
        // Finalize all components
        WepinStorage.shared.deleteAllStorage()
        WepinSessionManager.shared.finalize()
        WepinNetwork.shared.finalize()
        WepinFirebaseNetwork.shared.finalize()
        
        appKey = ""
        domain = ""
        sdkType = ""
        version = ""
        _initialized = false
    }
    
    public func isInitialized() -> Bool {
        return _initialized
    }
    
    // MARK: - Convenience accessors
    
    // Network access
    public var network: WepinNetwork {
        return WepinNetwork.shared
    }
    
    public var firebaseNetwork: WepinFirebaseNetwork {
        return WepinFirebaseNetwork.shared
    }
    
    // Session access
    public var session: WepinSessionManager {
        return WepinSessionManager.shared
    }
    
    // Storage access
    public var storage: WepinStorage {
        return WepinStorage.shared
    }
    
    // Connection state
    public var isConnected: Bool {
        return NetworkMonitor.shared.isConnected
    }
}
