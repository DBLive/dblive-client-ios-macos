//
//  DBLiveKeyEventListener.swift
//  
//
//  Created by Mike Richards on 5/24/20.
//

import Foundation

class DBLiveKeyEventListener: NSObject {
	
	public let action: String
	public let handler: DBLiveCallback<String?>
	public let id = UUID()
	
	public var isListening = true {
		didSet {
			guard isListening != oldValue else { return }
			
			statusChanged()
		}
	}
	
	private let statusChanged: () -> ()
	
	init(_ action: String, handler: @escaping DBLiveCallback<String?>, statusChanged: @escaping () -> ()) {
		self.action = action
		self.handler = handler
		self.statusChanged = statusChanged
	}
	
}
