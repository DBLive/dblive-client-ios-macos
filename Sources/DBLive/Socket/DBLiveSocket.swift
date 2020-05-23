//
//  DBLiveSocket.swift
//  
//
//  Created by Mike Richards on 5/22/20.
//

import Foundation
import SocketIO

final class DBLiveSocket: NSObject {
	
	var isConnected = false
	
	private let appKey: String
	private let logger = DBLiveLogger("DBLiveSocket")
	private let url: URL
	
	private weak var client: DBLiveClient?
	private var reconnectOnDisconnect = false
	private var socket: SocketIOClient?
	private var socketManager: SocketManager?

	init(url: URL, appKey: String, client: DBLiveClient) {
		self.url = url
		self.appKey = appKey
		self.client = client
		
		super.init()
		
		connect()
	}
	
	func dispose() {
		socketManager?.disconnect()
	}
	
	private func connect() {
		logger.debug("Connecting to socketUrl \(url.absoluteString)")
		
		socketManager = SocketManager(socketURL: url, config: [.forceNew(true), .forceWebsockets(true)])
		socket = socketManager!.defaultSocket
		
		socket!.on("connect") { [weak self] data, ack in
			guard let this = self else { return }
			this.onConnect(data: data, ack: ack)
		}
		
		socket!.on("error") { [weak self] data, ack in
			guard let this = self else { return }
			this.onError(data: data, ack: ack)
		}
		
		socket!.on("dbl-error") { [weak self] data, ack in
			guard let this = self else { return }
			this.onDBLError(data: data, ack: ack)
		}
		
		socket!.on("disconnect") { [weak self] data, ack in
			guard let this = self else { return }
			this.onDisconnect(data: data, ack: ack)
		}
		
		socket!.on("error") { [weak self] data, ack in
			guard let this = self else { return }
			this.onError(data: data, ack: ack)
		}
		
		socket!.on("reconnect") { [weak self] data, ack in
			guard let this = self else { return }
			this.onReconnect(data: data, ack: ack)
		}

		socket!.connect(timeoutAfter: 10) { [weak self] in
			guard let this = self else { return }
			this.reconnect()
		}
	}
	
	private func emitAppKey() {
		logger.debug("Approving appKey")
		
		socket?.emitWithAck("app", with: [["appKey": appKey]]).timingOut(after: 0) { [weak self] data in
			guard let this = self else { return }
			
			this.logger.debug("appKey ack: \(data)")
			
			let data = data.first as? [String: Any]
			
			if data == nil {
				this.client?.handleEvent("error", data: ["error": DBLiveError.unknownError])
			}
			else if let error = DBLiveError(json: data) {
				this.client?.handleEvent("error", data: ["error": error])
			}
			else {
				this.client?.handleEvent("connect", data: [:])
			}
		}
	}
	
	private func onConnect(data: [Any], ack: SocketAckEmitter) {
		logger.debug("connected - \(data)")
		isConnected = true
		emitAppKey()
	}
		
	private func onDBLError(data: [Any], ack: SocketAckEmitter) {
		logger.debug("dbl-error - \(data)")
		
	}
	
	private func onDisconnect(data: [Any], ack: SocketAckEmitter) {
		logger.debug("disconnected - \(data)")
		isConnected = false
		
		if reconnectOnDisconnect {
			reconnectOnDisconnect = false
			reconnect()
		}
	}
	
	private func onError(data: [Any], ack: SocketAckEmitter) {
		logger.debug("error - \(data)")
		if let msg = data.first as? String, msg == "Session ID unknown", let socket = socket {
			reconnectOnDisconnect = true
			socket.disconnect()
		}
	}
	
	private func onReconnect(data: [Any], ack: SocketAckEmitter) {
		logger.debug("reconnecting - \(data)")
		isConnected = false
	}
	
	private func reconnect() {
		logger.debug("reconnect()")
		
		socket = nil
		socketManager = nil
		
		DispatchQueue.global(qos: .background).asyncAfter(deadline: DispatchTime.now() + 1) { [weak self] in
			guard let this = self else { return }
			this.connect()
		}
	}
	
	deinit {
		dispose()
	}
	
}
