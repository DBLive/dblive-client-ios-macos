//
//  DBLiveAPI.swift
//  
//
//  Created by Mike Richards on 5/22/20.
//

import Foundation

final class DBLiveAPI: NSObject {
	
	private let appKey: String
	private let logger = DBLiveLogger("DBLiveAPI")
	private let request = DBLiveRequest()
	private let timeout: Double
	
	private var url = URL(string: "https://a.dblive.io/")!

	init(appKey: String, timeout: Double) {
		self.appKey = appKey
		self.timeout = timeout
	}
	
	func initCall(callback: @escaping (DBLiveAPIInitResult?, DBLiveError?) -> Void) {
		logger.debug("/init")
		
		var done = false
		
		request.postJson(url: self.url.appendingPathComponent("init"), params: ["appKey": appKey, "iosBundleID": Bundle.main.bundleIdentifier ?? ""]) { [weak self] result, error in
			guard let this = self, !done else { return }
			
			done = true
			
			guard error == nil, let json = result?.json else {
				let error = error != nil ? DBLiveError.connectionError(error) : DBLiveError.connectionTimeout
				this.logger.error("API Connection Error: \(error)")
				return callback(nil, error)
			}
			
			this.logger.debug("/init result: \(json)")
			
			if let error = DBLiveError(json: json) {
				return callback(nil, error)
			}
			
			if let apiDomain = json["apiDomain"] as? String, let apiUrl = URL(string: "https://\(apiDomain)/") {
				this.url = apiUrl
			}
			
			let socketDomain = json["socketDomain"] as? String
			let socketUrl = socketDomain != nil ? URL(string: "https://\(socketDomain!)/") : nil
			
			let contentDomain = json["contentDomain"] as? String
			let contentUrl = contentDomain != nil ? URL(string: "https://\(contentDomain!)/") : nil
			
			let initResult = DBLiveAPIInitResult(socketUrl: socketUrl ?? URL(string: "https://s.dblive.io/")!, contentUrl: contentUrl)
			
			callback(initResult, nil)
		}
		
		guard timeout >= 0.1 else { return }
		
		DispatchQueue.global(qos: .background).asyncAfter(deadline: DispatchTime.now() + timeout) { [weak self] in
			guard let this = self, !done else { return }
			
			done = true
			
			this.logger.debug("/init timed out")
			
			callback(nil, DBLiveError.connectionTimeout)
		}
	}
	
	func put(_ key: String, value: String, callback: @escaping (DBLiveAPIPutResult?, DBLiveError?) -> ()) {
		logger.debug("PUT /keys '\(key)'='\(value)'")
		
		var done = false
		
		request.putJson(url: self.url.appendingPathComponent("keys"), params: ["appKey": appKey, "key": key, "body": value, "content-type": "text/plain"]) { [weak self] result, error in
			guard let this = self, !done else { return }
			
			done = true
			
			guard error == nil, let json = result?.json else {
				let error = error != nil ? DBLiveError.connectionError(error) : DBLiveError.connectionTimeout
				this.logger.error("API Connection Error: \(error)")
				return callback(nil, error)
			}
			
			this.logger.debug("PUT /init '\(key)'-'\(value)' result: \(json)")
			
			if let error = DBLiveError(json: json) {
				return callback(nil, error)
			}

			let putResult = DBLiveAPIPutResult(versionId: json["versionId"] as? String)
			
			callback(putResult, nil)
		}
	}
	
}

struct DBLiveAPIInitResult
{
	let socketUrl: URL
	let contentUrl: URL?
}

struct DBLiveAPIPutResult
{
	let versionId: String?
}
