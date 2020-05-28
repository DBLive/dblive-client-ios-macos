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
	private let timeout: Double = 0
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
	
	func put(_ key: String, value: String, contentType: String = "text/plain", callback: @escaping (DBLiveAPIPutResult) -> ()) {
		guard let socket = socket else { return callback(DBLiveAPIPutResult(versionId: nil)) }
		
		let params = [
			"body": value,
			"contentType": contentType,
			"key": key,
		]
		
		socket.emitWithAck("put", with: [params]).timingOut(after: timeout) { [weak self] data in
			let logger = self?.logger
			
			logger?.debug("put ack: \(data)")
			
			if let data = data.first as? [String: Any], let versionId = data["versionId"] as? String {
				return callback(DBLiveAPIPutResult(versionId: versionId))
			}
			
			return callback(DBLiveAPIPutResult(versionId: nil))
		}
	}
	
	func stopWatching(_ key: String) {
		guard let client = client, client.status == .connected else {
			self.client?.once("connect") { _ in
				self.stopWatching(key)
			}
			
			return
		}
		
		logger.debug("stop watching key \(key)")
		socket?.emit("stop-watching", with: [["key": key]])
	}
	
	func watch(_ key: String) {
		guard let client = client, client.status == .connected else {
			self.client?.once("connect") { _ in
				self.watch(key)
			}
			
			return
		}

		logger.debug("watch key \(key)")
		socket?.emit("watch", with: [["key": key]])
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
		
		socket!.on("key") { [weak self] data, ack in
			guard let this = self else { return }
			this.onKey(data: data.first as? [String: Any] ?? [:])
		}
		
		socket!.on("reconnect") { [weak self] data, ack in
			guard let this = self else { return }
			this.onReconnect(data: data, ack: ack)
		}
		
		socket!.on("reset") { [weak self] _,_  in
			guard let this = self else { return }
			this.onReset()
		}

		socket!.connect(timeoutAfter: 10) { [weak self] in
			guard let this = self else { return }
			this.reconnect()
		}
	}
	
	private func emitAppKey() {
		logger.debug("Approving appKey")
		
		socket?.emitWithAck("app", with: [["appKey": appKey]]).timingOut(after: timeout) { [weak self] data in
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
		logger.error("socket error - \(data)")
		
		if let msg = data.first as? String, msg == "Session ID unknown", let socket = socket {
			reconnectOnDisconnect = true
			socket.disconnect()
		}
	}
	
	private func onKey(data: [String: Any]) {
		logger.debug("key - \(data)")
		
		guard let action = data["action"] as? String, let key = data["key"] as? String else { return }
		
		client?.handleEvent("key:\(key)", data: [
			"action": action,
			"etag": data["etag"] as? String as Any,
			"key": key,
			"value": data["value"] as? String as Any,
			"version": data["version"] as? String as Any
		])
	}
	
	private func onReconnect(data: [Any], ack: SocketAckEmitter) {
		logger.debug("reconnecting - \(data)")
		isConnected = false
	}
	
	private func onReset() {
		logger.debug("reset")
		client?.reset()
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


