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
	
	private weak var client: DBLiveClient?
	private var clientKeyListener: UUID?
	private var listeners: [DBLiveKeyEventListener] = []
	private weak var socket: DBLiveSocket?
	
	private var isWatching: Bool {
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
	
	init(key: String, client: DBLiveClient, socket: DBLiveSocket) {
		self.key = key
		self.client = client
		self.socket = socket
		
		isWatching = true
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
			version = data["version"] as? String,
			versionKey = version != nil ? "\(key)-\(version!)" : key
		
		if action == "changed" {
			client?.get(versionKey, callback: { [weak self] value in
				guard let this = self else { return }
				
				this.emitToListeners(action: "changed", value: value)
			})
		}
		else if action == "deleted" {
			emitToListeners(action: "changed", value: nil)
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