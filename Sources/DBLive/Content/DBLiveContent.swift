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
	private let socket: DBLiveSocket
	private let url: URL

	init(url: URL, socket: DBLiveSocket) {
		self.url = url
		self.socket = socket
		
		super.init()
	}
	
	func deleteCache(_ key: String, version: String? = nil) {
		if let version = version {
			logger.debug("delete '\(key)', version '\(version)'")
		}
		else {
			logger.debug("delete '\(key)'")
		}

		cache.delete(urlFor(key, version: version))
	}
	
	func get(_ key: String, version: String? = nil, callback: @escaping (String?) -> ()) {
		if let version = version {
			logger.debug("get '\(key)', version '\(version)'")
		}
		else {
			logger.debug("get '\(key)'")
		}
				
		let url = urlFor(key, version: version),
			cachedValue = cache.get(url)

		var headers: [String: String] = [:]

		if cachedValue != nil, let etag = cache.etag(url) {
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
				this.logger.debug("304 - Returning cached version")
				callback(String(data: cachedValue!, encoding: .utf8))
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
	
	func getFromCache(_ key: String) -> String? {
		logger.debug("getFromCache '\(key)'")
		
		let url = urlFor(key)
		
		if let value = cache.get(url) {
			logger.debug("Cache hit.")
			return String(data: value, encoding: .utf8)
		}

		return nil
	}
	
	func setCache(_ key: String, version: String? = nil, value: String, etag: String? = nil) {
		if let version = version {
			logger.debug("setCache '\(key)', version '\(version)': \(value)")
		}
		else {
			logger.debug("setCache '\(key)': \(value)")
		}
		
		let url = urlFor(key, version: version)

		cache.set(url, data: value.data(using: .utf8), etag: etag)
	}
	
	private func urlFor(_ key: String, version: String? = nil) -> URL {
		return url.appendingPathComponent(version != nil ? "\(key)-\(version!)" : key)
	}
	
}
