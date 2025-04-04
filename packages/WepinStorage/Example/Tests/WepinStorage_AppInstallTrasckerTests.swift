//
//  WepinStorage_AppInstallTrasckerTests.swift
//  WepinStorage
//
//  Created by musicgi on 3/11/25.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import XCTest

@testable import WepinStorage

class AppInstallTrackerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // 테스트 시작 전 Keychain, UserDefaults 초기화
        clearUserDefaults()
        clearMockKeychain()
    }

    override func tearDown() {
        clearUserDefaults()
        clearMockKeychain()
        super.tearDown()
    }

    // MARK: - Helper: 초기화용
    func clearUserDefaults() {
        UserDefaults.standard.removeObject(forKey: "wepin_app_install_tracker")
    }

    func clearMockKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "wepin_install_id_keychain"
        ]
        SecItemDelete(query as CFDictionary)
    }

    func saveMockInstallIdToKeychain() {
        let uuid = UUID().uuidString
        let data = uuid.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "wepin_install_id_keychain",
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    // MARK: - 테스트 케이스

    func test_firstInstall() {
        // Keychain 없음, UserDefaults 없음
        let result = AppInstallTracker.detectInstallState(hasLoginInfo: false)
        XCTAssertEqual(result, .firstInstall)
    }

    func test_updateFromOldApp() {
        // Keychain 있음 (로그인 정보 존재), UserDefaults 없음, installId 없음
        clearUserDefaults()
        // 로그인 정보 있음으로 가정 → hasLoginInfo = true
        let result = AppInstallTracker.detectInstallState(hasLoginInfo: true)
        XCTAssertEqual(result, .update)
    }

    func test_reInstallAfterAppDeletion() {
        // Keychain 있음 + installId 있음, UserDefaults 없음
        saveMockInstallIdToKeychain()
        clearUserDefaults()
        let result = AppInstallTracker.detectInstallState(hasLoginInfo: true)
        XCTAssertEqual(result, .reInstall)
    }

    func test_normalRunAfterTracked() {
        // UserDefaults 있음 → normalRun 예상
        UserDefaults.standard.set(true, forKey: "wepin_app_install_tracker")
        let result = AppInstallTracker.detectInstallState(hasLoginInfo: true)
        XCTAssertEqual(result, .normalRun)
    }

    func test_update_shouldCreateInstallId() {
        clearUserDefaults()
        // installId 없음
        XCTAssertNil(AppInstallTracker.getInstallIdFromKeychain())
        
        let result = AppInstallTracker.detectInstallState(hasLoginInfo: true)
        XCTAssertEqual(result, .update)

        let installId = AppInstallTracker.getInstallIdFromKeychain()
        XCTAssertNotNil(installId)
    }
}
