//
//  DBLiveEventHandler.swift
//  
//
//  Created by Mike Richards on 5/20/20.
//

import Foundation

class DBLiveEventHandler<T>: NSObject
{
	public let handler: DBLiveCallback<T>
	public let event: String
	public let id = UUID()
	
	internal let once: Bool
	
	public internal(set) var isActive = true
	
	init(_ event: String, once: Bool = false, handler: @escaping DBLiveCallback<T>) {
		self.event = event
		self.once = once
		self.handler = handler
	}
}
