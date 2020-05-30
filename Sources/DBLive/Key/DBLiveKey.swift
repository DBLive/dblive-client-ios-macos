//
//  DBLiveKey.swift
//  
//
//  Created by Mike Richards on 5/24/20.
//

import Foundation

final class DBLiveKey {
	
	private let key: String
	private let logger = DBLiveLogger("DBLiveKey")
	private let keyValueVersions = NSCache<NSString, NSString>()
	
	private weak var client: DBLiveClient?
	private var clientKeyListener: UUID?
	private var currentValue: String?
	private var listeners: [DBLiveKeyEventListener] = []

	internal weak var content: DBLiveContent?
	internal weak var socket: DBLiveSocket? {
		didSet { restartSocketWatch() }
	}
	
	private var isWatching = true {
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
	
	init(key: String, client: DBLiveClient, socket: DBLiveSocket?, content: DBLiveContent?) {
		self.key = key
		self.client = client
		self.socket = socket
		
		startWatching()
	}
		
	@discardableResult
	func onChanged(handler: @escaping (String?) -> ()) -> DBLiveKeyEventListener {
		let listener = DBLiveKeyEventListener("changed", handler: handler) { [weak self] in
			guard let this = self else { return }
			this.checkListenerStatus()
		}
		
		listeners.append(listener)
		
		return listener
	}
	
	private func checkListenerStatus() {
		if isWatching {
			if !listeners.contains(where: { $0.isListening }) {
				isWatching = false
			}
		}
		else {
			if listeners.contains(where: { $0.isListening }) {
				isWatching = true
			}
		}
	}
	
	private func emitToListeners(action: String, value: String?) {
		logger.debug("emitToListener(\(action), \(value ?? "nil")")
		
		for listener in listeners where listener.isListening && listener.action == action {
			DispatchQueue.global(qos: .background).async {
				listener.handler(value)
			}
		}
	}
		
	private func onKeyEvent(data: [String: Any]) {
		logger.debug("onKeyEvent(\(data)")
		
		let action = data["action"] as! String,
			etag = data["etag"] as? String,
			value = data["value"] as? String,
			version = data["version"] as? String
		
		var doEmit = true
		
		if let version = version {
			let versionKey = NSString(string: version)
			
			if let versionValue = keyValueVersions.object(forKey: versionKey) as String?, versionValue == value {
				doEmit = false
			}
			else if let value = value {
				keyValueVersions.setObject(NSString(string: value), forKey: versionKey)
			}
			else {
				keyValueVersions.removeObject(forKey: versionKey)
			}
		}
		
		if action == "changed" {
			if let value = value {
				content?.setCache(key, value: value, etag: etag)
				content?.setCache(key, version: version, value: value)
				
				if doEmit {
					currentValue = value
					emitToListeners(action: "changed", value: value)
				}
			}
			else {
				content?.get(key, version: version, callback: { [weak self] value in
					guard let this = self else { return }
					
					this.currentValue = value
					this.emitToListeners(action: "changed", value: value)
				})
			}
		}
		else if action == "deleted" {
			content?.deleteCache(key)
			content?.deleteCache(key, version: version)
			
			if doEmit {
				currentValue = nil
				emitToListeners(action: "changed", value: nil)
			}
		}
		else {
			logger.warn("No key event handler for action '\(action)'")
		}
	}
	
	private func restartSocketWatch() {
		if isWatching {
			socket?.watch(key)
			
			content?.get(key, callback: { [weak self] value in
				guard let this = self else { return }
				
				if value != this.currentValue {
					this.emitToListeners(action: "changed", value: value)
				}
			})
		}
	}
	
	private func startWatching() {
		logger.debug("startWatching()")
		
		if clientKeyListener != nil {
			stopWatching()
		}
		
		clientKeyListener = client?.on("key:\(key)", handler: { [weak self] data in
			guard let this = self else { return }
			
			this.onKeyEvent(data: data)
		})
		
		socket?.watch(key)
	}
	
	private func stopWatching() {
		logger.debug("stopWatching()")

		if let clientKeyListener = clientKeyListener {
			client?.off(id: clientKeyListener)
			self.clientKeyListener = nil
		}

		socket?.stopWatching(key)
	}
	
	deinit {
		stopWatching()
	}
}
