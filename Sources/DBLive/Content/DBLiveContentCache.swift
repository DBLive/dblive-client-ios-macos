//
//  DBLiveContentCache.swift
//  
//
//  Created by Mike Richards on 5/23/20.
//

import Foundation

class DBLiveContentCache {
	
	let logger = DBLiveLogger("DBLiveContentCache")
	
	private var cacheDirectory: URL? {
		get {
			return try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
		}
	}
	
	func delete(_ url: URL) {
		guard let localCacheUrl = self.localCacheUrl(url: url), let localCacheEtagUrl = self.localCacheEtagUrl(url: url) else { return }

		try? FileManager.default.removeItem(atPath: localCacheUrl.path)
		try? FileManager.default.removeItem(atPath: localCacheEtagUrl.path)
	}
	
	func etag(_ url: URL) -> String? {
		guard let localCacheEtagUrl = localCacheEtagUrl(url: url) else { return nil }
		
		return try? String(contentsOfFile: localCacheEtagUrl.path)
	}
	
	func get(_ url: URL) -> Data? {
		guard let localCacheUrl = localCacheUrl(url: url), cacheExists(url: localCacheUrl) else { return nil }
		
		return try? Data(contentsOf: localCacheUrl)
	}
	
	func set(_ url: URL, data: Data?, etag: String?) {
		guard let localCacheUrl = self.localCacheUrl(url: url), let localCacheEtagUrl = self.localCacheEtagUrl(url: url) else { return }
		
		if let data = data {
			try? data.write(to: localCacheUrl, options: .atomic)
			
			if let etag = etag {
				try? etag.write(to: localCacheEtagUrl, atomically: true, encoding: .utf8)
			}
			else {
				try? FileManager.default.removeItem(atPath: localCacheEtagUrl.path)
			}
		}
		else {
			try? FileManager.default.removeItem(atPath: localCacheUrl.path)
			try? FileManager.default.removeItem(atPath: localCacheEtagUrl.path)
		}
	}
	
	private func cacheExists(url: URL?) -> Bool {
		guard let url = url else { return false }
		
		return FileManager.default.fileExists(atPath: url.path)
	}

	private func convertRemoteUrlToFilename(url: URL) -> String {
		let invalidChars = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-_.").inverted
		return url.absoluteString.components(separatedBy: invalidChars).joined(separator: "").lowercased()
	}

	private func localCacheEtagUrl(url: URL) -> URL? {
		return localCacheUrl(url: url)?.appendingPathExtension("etag")
	}

	private func localCacheUrl(url: URL) -> URL? {
		let filename = convertRemoteUrlToFilename(url: url)
		return cacheDirectory?.appendingPathComponent("dblive.\(filename)")
	}
	

}
