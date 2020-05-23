//
//  DBLiveEventHandler.swift
//  
//
//  Created by Mike Richards on 5/20/20.
//

import Foundation

class DBLiveEventHandler: NSObject
{
	public let callback: DBLiveCallback
	public let event: String
	public let id = UUID()
	
	init(_ event: String, callback: @escaping DBLiveCallback) {
		self.event = event
		self.callback = callback
	}
}
