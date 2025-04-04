//
//  ViewController.swift
//  WepinModal
//
//  Created by hyunjung on 03/10/2025.
//  Copyright (c) 2025 hyunjung. All rights reserved.
//

import UIKit
import WepinModal

class ViewController: UIViewController {
    
    let wepinModal = WepinModal()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = .white
        setupTestButtons()
    }
    
    private func setupTestButtons() {
        let openModalButton = UIButton(type: .system)
        openModalButton.setTitle("Open WepinModal", for: .normal)
        openModalButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        openModalButton.backgroundColor = UIColor.systemBlue
        openModalButton.setTitleColor(.white, for: .normal)
        openModalButton.layer.cornerRadius = 10
        openModalButton.translatesAutoresizingMaskIntoConstraints = false
        openModalButton.addTarget(self, action: #selector(openWepinModal), for: .touchUpInside)
        
        let closeModalButton = UIButton(type: .system)
        closeModalButton.setTitle("Close WepinModal", for: .normal)
        closeModalButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        closeModalButton.backgroundColor = UIColor.systemRed
        closeModalButton.setTitleColor(.white, for: .normal)
        closeModalButton.layer.cornerRadius = 10
        closeModalButton.translatesAutoresizingMaskIntoConstraints = false
        closeModalButton.addTarget(self, action: #selector(closeWepinModal), for: .touchUpInside)

        let openExternalButton = UIButton(type: .system)
        openExternalButton.setTitle("Open External Browser", for: .normal)
        openExternalButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        openExternalButton.backgroundColor = UIColor.systemGreen
        openExternalButton.setTitleColor(.white, for: .normal)
        openExternalButton.layer.cornerRadius = 10
        openExternalButton.translatesAutoresizingMaskIntoConstraints = false
        openExternalButton.addTarget(self, action: #selector(openExternalBrowser), for: .touchUpInside)

        view.addSubview(openModalButton)
        view.addSubview(closeModalButton)
        view.addSubview(openExternalButton)

        NSLayoutConstraint.activate([
            openModalButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            openModalButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            openModalButton.widthAnchor.constraint(equalToConstant: 220),
            openModalButton.heightAnchor.constraint(equalToConstant: 50),
            
            closeModalButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            closeModalButton.topAnchor.constraint(equalTo: openModalButton.bottomAnchor, constant: 20),
            closeModalButton.widthAnchor.constraint(equalToConstant: 220),
            closeModalButton.heightAnchor.constraint(equalToConstant: 50),

            openExternalButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            openExternalButton.topAnchor.constraint(equalTo: closeModalButton.bottomAnchor, constant: 20),
            openExternalButton.widthAnchor.constraint(equalToConstant: 220),
            openExternalButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    @objc private func openWepinModal() {
//        wepinModal.openModal(on: self, url: "http://192.168.0.120:8080/") { message, completion in
//            print("📥 Received from WebView:", message)
//            let response = "✅ iOS response to JS"
//            completion(response)
//        }

        // 테스트용 실제 URL
        wepinModal.openModal(on: self, url: "https://dev-v1-widget.wepin.io") { message, completion in
            print("📥 Received from WebView:", message)
            let response = "✅ iOS response to JS"
            completion(response)
        }
    }
    
    @objc private func closeWepinModal() {
        wepinModal.closeModal()
    }

    @objc private func openExternalBrowser() {
        if let url = URL(string: "https://www.google.com") {
            wepinModal.openInExternalBrowser(url: url)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

