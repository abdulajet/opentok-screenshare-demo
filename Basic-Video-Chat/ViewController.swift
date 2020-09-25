//
//  ViewController.swift
//  Hello-World
//
//  Created by Roberto Perez Cubero on 11/08/16.
//  Copyright © 2016 tokbox. All rights reserved.
//

import UIKit
import OpenTok

// *** Fill the following variables using your own Project info  ***
// ***            https://tokbox.com/account/#/                  ***
// Replace with your OpenTok API key
let kApiKey = "46884024"
// Replace with your generated session ID
let kSessionId = "2_MX40Njg4NDAyNH5-MTYwMTA0OTI3MzExMn5QR3VZdk10b3N1RlhYUWlOT1dQL1lYOUZ-fg"
// Replace with your generated token
let kToken = "T1==cGFydG5lcl9pZD00Njg4NDAyNCZzaWc9MmRjMDIyMDUzMWJmOTAzYzMyNWI5NWYzMDc0ZjAyMTZlMTgwY2FkMjpzZXNzaW9uX2lkPTJfTVg0ME5qZzROREF5Tkg1LU1UWXdNVEEwT1RJM016RXhNbjVRUjNWWmRrMTBiM04xUmxoWVVXbE9UMWRRTDFsWU9VWi1mZyZjcmVhdGVfdGltZT0xNjAxMDQ5MjgzJm5vbmNlPTAuMTMzMjA0Njk2MDQ2OTk0NiZyb2xlPW1vZGVyYXRvciZleHBpcmVfdGltZT0xNjAxMTM1NjgyJmluaXRpYWxfbGF5b3V0X2NsYXNzX2xpc3Q9"

let kWidgetHeight = 240
let kWidgetWidth = 320

class ViewController: UIViewController {
    lazy var session: OTSession = {
        return OTSession(apiKey: kApiKey, sessionId: kSessionId, delegate: self)!
    }()
    
    lazy var publisher: OTPublisher = {
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        return OTPublisher(delegate: self, settings: settings)!
    }()
    
    lazy var screenPublisher: OTPublisher = {
        let settings = OTPublisherSettings()
        settings.name = "\(UIDevice.current.name) screen"
        return OTPublisher(delegate: self, settings: settings)!
    }()
    
    lazy var shareScreenButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Share Screen", for: .normal)
        button.addTarget(self, action: #selector(shareScreenTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    var subscriber: OTSubscriber?
    var screenSubscriber: OTSubscriber?
    var sharingScreen = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(stackView)
        view.addSubview(shareScreenButton)
        
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                stackView.bottomAnchor.constraint(lessThanOrEqualTo: shareScreenButton.topAnchor),
                
                shareScreenButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                shareScreenButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        }
        
        doConnect()
    }
    
    @objc func shareScreenTapped() {
        var error: OTError?
        defer {
            processError(error)
        }
        
        
        screenPublisher.videoType = .screen
        screenPublisher.audioFallbackEnabled = false
        let cap = ScreenCapturer(withView: view)
        screenPublisher.videoCapture = cap
        
        session.publish(screenPublisher, error: &error)
        
        if let pubView = screenPublisher.view {
            pubView.translatesAutoresizingMaskIntoConstraints = false
            pubView.heightAnchor.constraint(equalToConstant: CGFloat(kWidgetHeight)).isActive = true
            pubView.widthAnchor.constraint(equalToConstant: CGFloat(kWidgetWidth)).isActive = true
            stackView.addArrangedSubview(pubView)
        }
    }
    
    /**
     * Asynchronously begins the session connect process. Some time later, we will
     * expect a delegate method to call us back with the results of this action.
     */
    fileprivate func doConnect() {
        var error: OTError?
        defer {
            processError(error)
        }
        
        session.connect(withToken: kToken, error: &error)
    }
    
    /**
     * Sets up an instance of OTPublisher to use with this session. OTPubilsher
     * binds to the device camera and microphone, and will provide A/V streams
     * to the OpenTok session.
     */
    fileprivate func doPublish() {
        var error: OTError?
        defer {
            processError(error)
        }
        
        session.publish(publisher, error: &error)
        
        if let pubView = publisher.view {
            pubView.translatesAutoresizingMaskIntoConstraints = false
            pubView.heightAnchor.constraint(equalToConstant: CGFloat(kWidgetHeight)).isActive = true
            pubView.widthAnchor.constraint(equalToConstant: CGFloat(kWidgetWidth)).isActive = true
            stackView.addArrangedSubview(pubView)
        }
    }
    
    /**
     * Instantiates a subscriber for the given stream and asynchronously begins the
     * process to begin receiving A/V content for this stream. Unlike doPublish,
     * this method does not add the subscriber to the view hierarchy. Instead, we
     * add the subscriber only after it has connected and begins receiving data.
     */
    fileprivate func doSubscribe(_ stream: OTStream) {
        var error: OTError?
        defer {
            processError(error)
        }
        subscriber = OTSubscriber(stream: stream, delegate: self)
        
        session.subscribe(subscriber!, error: &error)
    }
    
    fileprivate func cleanupSubscriber() {
        subscriber?.view?.removeFromSuperview()
        screenSubscriber?.view?.removeFromSuperview()
        subscriber = nil
    }
    
    fileprivate func cleanupPublisher() {
        publisher.view?.removeFromSuperview()
    }
    
    fileprivate func processError(_ error: OTError?) {
        if let err = error {
            DispatchQueue.main.async {
                let controller = UIAlertController(title: "Error", message: err.localizedDescription, preferredStyle: .alert)
                controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(controller, animated: true, completion: nil)
            }
        }
    }
}

// MARK: - OTSession delegate callbacks
extension ViewController: OTSessionDelegate {
    func sessionDidConnect(_ session: OTSession) {
        print("Session connected")
        doPublish()
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        print("Session disconnected")
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("Session streamCreated: \(stream.streamId)")
        if subscriber == nil {
            doSubscribe(stream)
        } else {
            var error: OTError?
            defer {
                processError(error)
            }
            screenSubscriber = OTSubscriber(stream: stream, delegate: self)
            
            session.subscribe(screenSubscriber!, error: &error)
        }
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("Session streamDestroyed: \(stream.streamId)")
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            cleanupSubscriber()
        }
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("session Failed to connect: \(error.localizedDescription)")
    }
    
}

// MARK: - OTPublisher delegate callbacks
extension ViewController: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        print("Publishing")
    }
    
    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        cleanupPublisher()
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            cleanupSubscriber()
        }
    }
    
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print("Publisher failed: \(error.localizedDescription)")
    }
}

// MARK: - OTSubscriber delegate callbacks
extension ViewController: OTSubscriberDelegate {
    func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
        if let subsView = subscriber?.view {
            subsView.translatesAutoresizingMaskIntoConstraints = false
            subsView.heightAnchor.constraint(equalToConstant: CGFloat(kWidgetHeight)).isActive = true
            subsView.widthAnchor.constraint(equalToConstant: CGFloat(kWidgetWidth)).isActive = true
            stackView.addArrangedSubview(subsView)
        }
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("Subscriber failed: \(error.localizedDescription)")
    }
}
