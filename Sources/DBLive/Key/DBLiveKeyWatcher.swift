//
//  DBLiveKeyWatcher.swift
//  
//
//  Created by Mike Richards on 5/24/20.
//

import Foundation

final class DBLiveKeyWatcher {
	
	static private var keyWatcherCount: [String: Int] = [:]
	
	var isWatching: Bool {
		didSet {
			guard isWatching != oldValue else { return }
			
			if isWatching {
				startWatching()
			}
			else {
				stopWatching()
			}
		}
	}
	
	private let key: String
	private let logger = DBLiveLogger("DBLiveKeyWatcher")
	
	private weak var client: DBLiveClient?
	private var clientKeyListener: UUID?
	private var handlers: [DBLiveKeyEventHandler] = []
	private weak var socket: DBLiveSocket?
	
	init(key: String, client: DBLiveClient, socket: DBLiveSocket) {
		self.key = key
		self.client = client
		self.socket = socket
		
		isWatching = true
		startWatching()
	}
	
	@discardableResult
	func onChanged(handler: @escaping (String?) -> ()) -> UUID {
		let handler = DBLiveKeyEventHandler("changed", handler: handler)
		
		handlers.append(handler)
		
		return handler.id
	}
	
	func removeHandler(id: UUID) {
		handlers = handlers.filter { $0.id != id }
	}
	
	private func onKeyEvent(data: [String: Any]) {
		logger.debug("onKeyEvent(\(data)")
		
		let action = data["action"] as! String,
			version = data["version"] as? String,
			versionKey = version != nil ? "\(key)-\(version!)" : key
		
		if action == "changed" {
			client?.get(versionKey, callback: { [weak self] value in
				guard let this = self else { return }
			
				for handler in this.handlers where handler.action == action {
					this.logger.debug("calling handler")
					DispatchQueue.global(qos: .background).async {
						handler.handler(value)
					}
				}
			})
		}
		else {
			logger.warn("No key event handler for action '\(action)'")
		}
	}
	
	private func startWatching() {
		logger.debug("startWatching()")
		
		if clientKeyListener != nil {
			stopWatching()
		}
		
		clientKeyListener = client?.on("key:\(key)", callback: { [weak self] data in
			guard let this = self else { return }			
			
			this.onKeyEvent(data: data)
		})
		
		socket?.watch(key)
		DBLiveKeyWatcher.keyWatcherCount[key] = (DBLiveKeyWatcher.keyWatcherCount[key] ?? 0) + 1
	}
	
	private func stopWatching() {
		logger.debug("stopWatching()")

		if let clientKeyListener = clientKeyListener {
			client?.off(id: clientKeyListener)
			self.clientKeyListener = nil
		}

		DBLiveKeyWatcher.keyWatcherCount[key] = max((DBLiveKeyWatcher.keyWatcherCount[key] ?? 0) - 1, 0)
		
		if DBLiveKeyWatcher.keyWatcherCount[key] == 0 {
			socket?.stopWatching(key)
		}
	}
	
	deinit {
		stopWatching()
	}
}
