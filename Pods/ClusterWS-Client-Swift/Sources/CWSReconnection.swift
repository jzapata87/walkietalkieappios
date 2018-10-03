//
//  CWSReconnection.swift
//  Test
//
//  Created by Roman Baitaliuk on 7/10/17.
//  Copyright © 2017 ByteKit. All rights reserved.
//

import Foundation

open class CWSReconnection {
    
    // MARK: - Properties
    
    private var mReconnectionTimer: Timer?
    private var mAutoReconnect: Bool
    private var mReconnectionAttempts: Int
    private var mReconnectionIntervalMin: Double // reconnection interval is in seconds
    private var mReconnectionIntervalMax: Double // reconnection interval is in seconds
    private var mCurrentReconnectionAttempted: Int = 0
    private let mSocket: ClusterWS
    
    // MARK: - Initialization
    
    public init(socket: ClusterWS) {
        self.mSocket = socket
        self.mAutoReconnect = false
        self.mReconnectionIntervalMin = 1.0
        self.mReconnectionIntervalMax = 5.0
        self.mReconnectionAttempts = 0
    }
}

// MARK: - Open methods

extension CWSReconnection {
    
    open func onConnected() {
        self.resetTimer()
        self.mReconnectionAttempts = 0
        self.resubscribe()
    }
    
    open func resetTimer() {
        self.mReconnectionTimer?.invalidate()
        self.mReconnectionTimer = nil
    }
    
    open func isRunning() -> Bool {
        return self.mReconnectionTimer != nil
    }
    
    open func isAutoReconnectOn() -> Bool {
        return self.mAutoReconnect
    }
    
    open func setReconnection(autoReconnect: Bool, reconnectionIntervalMin: Double? = nil, reconnectionIntervalMax: Double? = nil, reconnectionAttempts: Int? = nil) {
        self.mAutoReconnect = autoReconnect
        self.mReconnectionIntervalMin = reconnectionIntervalMin ?? self.mReconnectionIntervalMin
        self.mReconnectionIntervalMax = reconnectionIntervalMax ?? self.mReconnectionIntervalMax
        self.mReconnectionAttempts = reconnectionAttempts ?? self.mReconnectionAttempts
    }
    
    open func reconnect() {
        let max = UInt32(self.mReconnectionIntervalMax * 1000)
        let min = UInt32(self.mReconnectionIntervalMin * 1000)
        let randomNumber = arc4random_uniform(max-min)+min
        if #available(iOS 10.0, OSX 10.12, tvOS 10.0, *) {
            self.mReconnectionTimer = Timer.scheduledTimer(withTimeInterval: Double(randomNumber / 1000),
                                                           repeats: false,
                                                           block: { (timer) in
                                                            self.reconnectionBlock()
            })
        } else {
            self.mReconnectionTimer = Timer(timeInterval: Double(randomNumber / 1000),
                                            target: self, selector: #selector(reconnectionBlock),
                                            userInfo: nil,
                                            repeats: false)
            self.mReconnectionTimer?.fire()
        }
    }
}

// MARK: Private methods

extension CWSReconnection {
    
    private func resubscribe() {
        let channels = self.mSocket.getChannels()
        channels.forEach { _ = self.mSocket.subscribe($0.mChannelName) }
    }
    
    @objc private func reconnectionBlock() {
        if self.mSocket.getState() == .closed {
            self.mCurrentReconnectionAttempted += 1
            if self.mReconnectionAttempts != 0 && self.mCurrentReconnectionAttempted >= self.mReconnectionAttempts {
                self.resetTimer()
            } else {
                self.resetTimer()
                self.mSocket.connect()
            }
        }
    }
}
