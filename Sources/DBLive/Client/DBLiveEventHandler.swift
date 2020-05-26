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
	
	init(_ event: String, handler: @escaping DBLiveCallback<T>) {
		self.event = event
		self.handler = handler
	}
}
