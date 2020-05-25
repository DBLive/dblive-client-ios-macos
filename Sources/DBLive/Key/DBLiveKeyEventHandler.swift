//
//  DBLiveKeyEventHandler.swift
//  
//
//  Created by Mike Richards on 5/24/20.
//

import Foundation

class DBLiveKeyEventHandler: NSObject {
	
	public let handler: DBLiveCallback<String?>
	public let action: String
	public let id = UUID()
	
	init(_ action: String, handler: @escaping DBLiveCallback<String?>) {
		self.action = action
		self.handler = handler
	}
	
}
