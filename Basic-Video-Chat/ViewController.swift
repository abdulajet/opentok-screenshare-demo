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
let kApiKey = ""
// Replace with your generated session ID
let kSessionId = ""
// Replace with your generated token
let kToken = ""

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
    
    var subscribers: [OTSubscriber?] = []
    var streams: [String] = []
    var sharingScreen = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .yellow
        
        view.addSubview(shareScreenButton)
        
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                shareScreenButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                shareScreenButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        }
        doConnect()
    }
    
    @objc func shareScreenTapped() {
        if sharingScreen {
            self.view.backgroundColor = .yellow
            stopScreenPublish()
        } else {
            self.view.backgroundColor = .green
            doScreenPublish()
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
            pubView.frame = CGRect(x: 0, y: 0, width: Int(self.view.bounds.width), height: kWidgetHeight)
            view.addSubview(pubView)
        }
    }
    
    fileprivate func stopScreenPublish() {
        var error: OTError?
        defer {
            processError(error)
        }
        
        session.unpublish(screenPublisher, error: &error)
        sharingScreen = false
        shareScreenButton.setTitle("Share Screen", for: .normal)
    }
    
    fileprivate func doScreenPublish() {
        var error: OTError?
        defer {
            processError(error)
        }
        
        screenPublisher.videoType = .screen
        screenPublisher.audioFallbackEnabled = false
        let cap = ScreenCapturer(withView: view)
        screenPublisher.videoCapture = cap
        
        session.publish(screenPublisher, error: &error)
        sharingScreen = true
        shareScreenButton.setTitle("Stop Sharing Screen", for: .normal)
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
        let subscriber = OTSubscriber(stream: stream, delegate: self)
        session.subscribe(subscriber!, error: &error)
        subscribers.append(subscriber)
    }
    
    fileprivate func cleanupSubscriber(subscriber: OTSubscriber?, index: Int) {
        subscriber?.view?.removeFromSuperview()
        subscribers.remove(at: index)
    }
    
    fileprivate func cleanupPublisher(name: String?) {
        if name!.contains("screen") {
            screenPublisher.view?.removeFromSuperview()
        } else {
            publisher.view?.removeFromSuperview()
        }
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
        streams.append(stream.streamId)
        if subscribers.count != streams.count {
            doSubscribe(stream)
        }
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("Session streamDestroyed: \(stream.streamId)")
        
        if streams.contains(stream.streamId) {
            for (index, subscriber) in subscribers.enumerated() {
                if (subscriber?.stream?.streamId ?? "") == stream.streamId {
                    cleanupSubscriber(subscriber: subscriber, index: index)
                }
            }
            streams.remove(at: streams.index(of: stream.streamId)!)
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
        cleanupPublisher(name: publisher.name)
        if streams.contains(stream.streamId) {
            for (index, subscriber) in subscribers.enumerated() {
                if streams.contains(subscriber?.stream?.streamId ?? "") {
                    cleanupSubscriber(subscriber: subscriber, index: index)
                }
            }
            streams.remove(at: streams.index(of: stream.streamId)!)
        }
    }
    
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print("Publisher failed: \(error.localizedDescription)")
    }
}

// MARK: - OTSubscriber delegate callbacks
extension ViewController: OTSubscriberDelegate {
    func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
        if let subsView = subscribers.last??.view {
            subsView.frame = CGRect(x: 0, y: kWidgetHeight * subscribers.count, width: Int(self.view.bounds.width), height: kWidgetHeight)
            subsView.layer.borderColor = UIColor.blue.cgColor
            subsView.layer.borderWidth = 3
            view.addSubview(subsView)
        }
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("Subscriber failed: \(error.localizedDescription)")
    }
}
