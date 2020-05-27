//
//  DBLiveClient.swift
//  
//
//  Created by Mike Richards on 5/20/20.
//

import Foundation
import SocketIO

@objc
public enum DBLiveClientStatus: Int {
	case notConnected = 0
	case connecting = 1
	case connected = 2
}

open class DBLiveClient: NSObject {
	
	public private(set) var status: DBLiveClientStatus = .notConnected
	
	private let appKey: String
	private let logger: DBLiveLogger
	
	private var api: DBLiveAPI?
	private var content: DBLiveContent?
	private var handlers: [DBLiveEventHandler<[String: Any]>] = []
	private var keys: [String: DBLiveKey] = [:]
	private var setEnv: String?
	private var socket: DBLiveSocket? {
		didSet {
			for key in keys {
				key.value.socket = socket
			}
		}
	}

	@objc
	public init(appKey: String) {
		self.appKey = appKey
		logger = DBLiveLogger("DBLiveClient(\(appKey))")
		
		super.init()
	}
	
	@objc
	@discardableResult
	public func connect(callback: (() -> ())? = nil) -> DBLiveClient {
		return connect(timeout: 0, callback: callback)
	}
	
	@objc
	@discardableResult
	open func connect(timeout: Double, callback: (() -> ())? = nil) -> DBLiveClient {
		assert(timeout >= 0, "Invalid timeout: \(timeout)")

		guard status == .notConnected else {
			if status == .connecting {
				if let callback = callback {
					once("connect") { _ in
						callback()
					}
				}
			}
			else if status == .connected {
				logger.warn("Cannot call 'connect' more than once.")
				callback?()
			}
			else {
				logger.error("Unhandled status '\(status)'")
			}

			return self
		}
		
		status = .connecting
		
		once("connect") { [weak self] _ in
			self?.status = .connected
			callback?()
		}

		let api = DBLiveAPI(appKey: appKey, timeout: timeout)
		self.api = api
		
		logger.debug("Connecting to API")
		
		api.initCall { [weak self] result, error in
			guard let this = self else { return }
			
			if let error = error {
				this.status = .notConnected
				this.logger.error("API Connection Error: \(error)")
				return this.handleEvent("error", data: ["error": error])
			}
			
			guard let result = result else {
				this.status = .notConnected
				return
			}
			
			guard let contentUrl = result.contentUrl else {
				this.status = .notConnected
				this.logger.error("No contentDomain was returned from init API call")
				return this.handleEvent("error", data: ["error": DBLiveError.connectionTimeout])
			}
			
			this.setEnv = result.setEnv
			this.connectSocket(url: result.socketUrl)
			this.content = DBLiveContent(url: contentUrl, socket: this.socket!)
		}
		
		return self
	}
	
	@objc
	open func get(_ key: String, callback: @escaping (String?) -> ()) {
		guard status == .connected else {
			connect { [weak self] in
				DispatchQueue.main.async {
					self?.get(key, callback: callback)
				}
			}
			
			return
		}
		
		if let value = content!.getFromCache(key) {
			callback(value)
		}

		content!.get(key) { result in
			DispatchQueue.main.async {
				callback(result)
			}
		}
	}
	
	@objc
	@discardableResult
	public func getAndListen(_ key: String, handler: @escaping (String?) -> ()) -> DBLiveKeyEventListener {
		get(key, callback: handler)

		return self.key(key).onChanged(handler: handler)
	}
	
	open func getJson(_ key: String, callback: @escaping([String: Any]?) -> ()) {
		guard status == .connected else {
			connect { [weak self] in
				self?.getJson(key, callback: callback)
			}
			
			return
		}
		
		if let cachedValue = content!.getFromCache(key),
			let cachedData = cachedValue.data(using: .utf8),
			let cachedObj = try? JSONSerialization.jsonObject(with: cachedData, options: []) as? [String: Any]
		{
			callback(cachedObj)
		}
		
		content!.get(key) { result in
			DispatchQueue.main.async {
				guard let result = result?.data(using: .utf8) else { return callback(nil) }
			
				callback(try? JSONSerialization.jsonObject(with: result, options: []) as? [String: Any])
			}
		}
	}
	
	@objc
	@discardableResult
	public func getJsonAndListen(_ key: String, callback: @escaping ([String: Any]?) -> ()) -> DBLiveKeyEventListener {
		getJson(key, callback: callback)
		
		return self.key(key).onChanged { result in
			DispatchQueue.main.async {
				guard let result = result?.data(using: .utf8) else { return callback(nil) }

				callback(try? JSONSerialization.jsonObject(with: result, options: []) as? [String: Any])
			}
		}
	}
			
	@objc
	open func off(id: UUID) {
		logger.debug("Removing handler \(id)")
		
		handlers = handlers.filter { $0.id != id }
	}
	
	@objc
	@discardableResult
	open func on(_ event: String, once: Bool = false, handler: @escaping DBLiveCallback<[String: Any]>) -> UUID {
		let eventHandler = DBLiveEventHandler(event, once: once, handler: handler)
		
		handlers.append(eventHandler)
		
		return eventHandler.id
	}
	
	@objc
	@discardableResult
	open func once(_ event: String, handler: @escaping DBLiveCallback<[String: Any]>) -> UUID {
		return on(event, once: true, handler: handler)
	}
	
	@objc
	@discardableResult
	open func onError(handler: @escaping (DBLiveError) -> ()) -> UUID {
		return on("error") { data in
			guard let error = data["error"] as? DBLiveError else { return }
			
			handler(error)
		}
	}
	
	@objc
	open func set(_ key: String, value: String, contentType: String = "text/plain", callback: @escaping (Bool) -> ()) {
		guard status == .connected else {
			connect { [weak self] in
				self?.set(key, value: value, contentType: contentType, callback: callback)
			}
			
			return
		}
				
		if (setEnv == "socket") {
			socket!.put(key, value: value, contentType: contentType) { result in
				return callback(result.versionId != nil)
			}
		}
		else {
			api!.put(key, value: value, contentType: contentType) { [weak self] (result, error) in
				let logger = self?.logger

				if let error = error {
					logger?.debug("Failed to set '\(key)' to '\(value)': \(error)")
					return callback(false)
				}

				return callback(result?.versionId != nil)
			}
		}
		
		DispatchQueue.global(qos: .background).async { [weak self] in
			guard let this = self else { return }
			
			this.handleEvent("key:\(key)", data: [
				"action": "changed",
				"key": key,
				"value": value
			])
		}
	}
	
	public func set(_ key: String, value: [String: Any], callback: @escaping (Bool) -> ()) {
		guard let value = try? JSONSerialization.data(withJSONObject: value) else {
			return callback(false)
		}
		
		set(key, value: String(data: value, encoding: .utf8)!, contentType: "application/json", callback: callback)
	}
	
	internal func handleEvent(_ event: String, data: [String: Any]) {
		logger.debug("handleEvent(\(event), \(data)")
		
		for eventHandler in handlers where eventHandler.event == event && eventHandler.isActive {
			if eventHandler.once {
				eventHandler.isActive = false
			}

			DispatchQueue.global(qos: .background).async {
				eventHandler.handler(data)
			}
		}
	}
	
	internal func key(_ key: String) -> DBLiveKey {
		let dbLiveKey = keys[key] ?? DBLiveKey(key: key, client: self, socket: socket)
		keys[key] = dbLiveKey
		
		return dbLiveKey
	}
	
	private func connectSocket(url: URL) {
		logger.debug("Connecting to Socket")
		
		socket = DBLiveSocket(url: url, appKey: appKey, client: self)
	}
		
	deinit {
		socket?.dispose()
	}
	
}
