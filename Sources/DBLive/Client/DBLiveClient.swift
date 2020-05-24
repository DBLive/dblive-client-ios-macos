//
//  DBLiveClient.swift
//  
//
//  Created by Mike Richards on 5/20/20.
//

import Foundation
import SocketIO

open class DBLiveClient: NSObject {
	
	private let appKey: String
	private let logger: DBLiveLogger
	
	private var api: DBLiveAPI?
	private var contentUrl: URL?
	private var handlers: [DBLiveEventHandler] = []
	private var socket: DBLiveSocket?

	@objc
	init(appKey: String) {
		self.appKey = appKey
		logger = DBLiveLogger("DBLiveClient(\(appKey))")
		
		super.init()
	}
	
	@objc
	@discardableResult
	func connect() -> DBLiveClient {
		return connect(timeout: 0)
	}
	
	@objc
	@discardableResult
	open func connect(timeout: Double) -> DBLiveClient {
		assert(timeout >= 0, "Invalid timeout: \(timeout)")

		guard api == nil else {
			logger.warn("Cannot call 'connect' more than once.")
			return self
		}

		let api = DBLiveAPI(appKey: appKey, timeout: timeout)
		self.api = api
		
		logger.debug("Connecting to API")
		
		api.initCall { [weak self] result, error in
			guard let this = self else { return }
			
			if let error = error {
				this.logger.error("API Connection Error: \(error)")
				return this.handleEvent("error", data: ["error": error])
			}
			
			guard let result = result else { return }
			
			guard let contentUrl = result.contentUrl else {
				this.logger.error("No contentDomain was returned from init API call")
				return this.handleEvent("error", data: ["error": DBLiveError.connectionTimeout])
			}
			
			this.contentUrl = contentUrl
			this.connectSocket(url: result.socketUrl)
		}
		
		return self
	}
		
	@objc
	open func handleEvent(_ event: String, data: [String: Any]) {
		logger.debug("handleEvent(\(event), \(data)")
		
		for handler in handlers where handler.event == event {
			DispatchQueue.global(qos: .background).async {
				handler.callback(data)
			}
		}
	}
	
	@objc
	@discardableResult
	open func on(_ event: String, callback: @escaping DBLiveCallback) -> UUID {
		let handler = DBLiveEventHandler(event, callback: callback)
		
		handlers.append(handler)
		
		return handler.id
	}
	
	@objc
	@discardableResult
	open func onError(callback: @escaping (DBLiveError) -> ()) -> UUID {
		return self.on("error") { data in
			guard let error = data["error"] as? DBLiveError else { return }
			
			callback(error)
		}
	}
	
	@objc
	open func set(_ key: String, value: String, callback: @escaping (Bool) -> ()) {
		assert(api != nil, "Must call 'connect' before calling 'set'")

		api!.put(key, value: value) { [weak self] (result, error) in
			guard let this = self else { return }
			
			if let error = error {
				this.logger.debug("Failed to set '\(key)' to '\(value)': \(error)")
				return callback(false)
			}
			
			return callback(result?.versionId != nil)
		}
	}
	
	private func connectSocket(url: URL) {
		logger.debug("Connecting to Socket")
		socket = DBLiveSocket(url: url, appKey: appKey, client: self)
	}
	
	deinit {
		socket?.dispose()
	}
	
}
