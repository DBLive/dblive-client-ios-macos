//
//  DBLiveContent.swift
//  
//
//  Created by Mike Richards on 5/23/20.
//

import Foundation

final class DBLiveContent: NSObject {
	
	private let cache = DBLiveContentCache()
	private let logger = DBLiveLogger("DBLiveContent")
	private let request = DBLiveRequest()
	private let url: URL

	init(url: URL) {
		self.url = url
		
		super.init()
	}
	
	func get(_ key: String, callback: @escaping (String?) -> ()) {
		logger.debug("get '\(key)'")
		
		let url = self.url.appendingPathComponent(key)
		
		logger.debug(url.absoluteString)
		
		if let value = cache.get(url) {
			logger.debug("Cache hit. Returning cache value first.")
			callback(String(data: value, encoding: .utf8))
		}
		
		var headers: [String: String] = [:]

		if let etag = cache.etag(url) {
			logger.debug("Local Etag: \(etag)")
			headers["If-None-Match"] = etag
		}
		
		request.get(url: url, headers: headers) { [weak self] result, error in
			guard let this = self else { return }
			
			if let error = error {
				this.logger.error("Request error \(error)")
				return
			}
			
			guard let result = result, let response = result.response as? HTTPURLResponse else {
				this.logger.error("Invalid response")
				return
			}
			
			if response.statusCode == 200 {
				let etag = response.allHeaderFields["Etag"] as? String
				this.logger.debug("New Etag: \(etag ?? "None")")
				this.cache.set(url, data: result.data, etag: etag)
				callback(String(data: result.data, encoding: .utf8))
			}
			else if response.statusCode == 304 {
				// Nothing to do
			}
			else if response.statusCode == 404 || response.statusCode == 403 {
				this.logger.debug("Key not found")
				this.cache.set(url, data: nil, etag: nil)
				callback(nil)
			}
			else {
				this.logger.warn("Unhandled response status code \(response.statusCode)")
			}
		}
	}
	
}
