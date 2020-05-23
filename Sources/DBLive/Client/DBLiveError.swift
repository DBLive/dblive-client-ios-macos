//
//  DBLiveError.swift
//  
//
//  Created by Mike Richards on 5/21/20.
//

import Foundation

@objcMembers
open class DBLiveError: NSObject {
	
	let code: String
	let errorDescription: String
	
	var error: Error?
	
	private init(code: String, errorDescription: String, error: Error? = nil) {
		self.code = code
		self.errorDescription = errorDescription
		self.error = error
	}
	
	convenience init?(json: [String: Any]?) {
		guard let json = json, let error = json["error"] as? [String: String] else { return nil }
		
		self.init(code: error["code"]!, errorDescription: error["description"]!)
	}
	
	func withError(error: Error?) -> DBLiveError {
		self.error = error
		return self
	}
	
	override open var description: String {
		get { return "[\"code\":\"\(code)\",\"errorDescription\":\"\(errorDescription)\"]" }
	}
	
	static var connectionTimeout: DBLiveError {
		get { return DBLiveError(code: "connection-timeout", errorDescription: "Failed to connect to DBLive services within specified timeout. Is there internet connection?") }
	}

	static var unknownError: DBLiveError {
		get { return DBLiveError(code: "unknown-error", errorDescription: "An unexpected condition occurred which could not be handled.") }
	}
	
	static func connectionError(_ error: Error?) -> DBLiveError {
		return DBLiveError(code: "connection-error", errorDescription: "An unexpected error occurred. Check the 'error' property for more details.", error: error)
	}

}
