//
//  DBLiveEventHandler.swift
//  
//
//  Created by Mike Richards on 5/20/20.
//

import Foundation

class DBLiveEventHandler<T>: NSObject
{
	public let callback: DBLiveCallback<T>
	public let event: String
	public let id = UUID()
	
	init(_ event: String, callback: @escaping DBLiveCallback<T>) {
		self.event = event
		self.callback = callback
	}
}
