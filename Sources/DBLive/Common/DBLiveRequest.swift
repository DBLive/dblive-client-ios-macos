//
//  DBLiveRequest.swift
//  
//
//  Created by Mike Richards on 5/20/20.
//

import Foundation

final class DBLiveRequest
{
	let logger = DBLiveLogger("DBLiveRequest")
	
	func delete(url: URL, params: [String: Any] = [:], headers: [String: String] = [:], callback: @escaping (DBLiveRequestResult?, Error?) -> Void) {
		requestResult(url: url, method: "DELETE", params: params, headers: headers, callback: callback)
	}
	
	func deleteJson(url: URL, params: [String: Any] = [:], headers: [String: String] = [:], callback: @escaping (DBLiveJsonRequestResult?, Error?) -> Void) {
		requestJsonResult(url: url, method: "DELETE", params: params, headers: headers, callback: callback)
	}
	
	func get(url: URL, params: [String: Any] = [:], headers: [String: String] = [:], callback: @escaping (DBLiveRequestResult?, Error?) -> Void) {
		requestResult(url: url, method: "GET", params: params, headers: headers, callback: callback)
	}
	
	func getJson(url: URL, params: [String: Any] = [:], headers: [String: String] = [:], callback: @escaping (DBLiveJsonRequestResult?, Error?) -> Void) {
		requestJsonResult(url: url, method: "GET", params: params, headers: headers, callback: callback)
	}

	func post(url: URL, params: [String: Any] = [:], headers: [String: String] = [:], callback: @escaping (DBLiveRequestResult?, Error?) -> Void) {
		requestResult(url: url, method: "POST", params: params, headers: headers, callback: callback)
	}
	
	func postJson(url: URL, params: [String: Any] = [:], headers: [String: String] = [:], callback: @escaping (DBLiveJsonRequestResult?, Error?) -> Void) {
		requestJsonResult(url: url, method: "POST", params: params, headers: headers, callback: callback)
	}
	
	func put(url: URL, params: [String: Any] = [:], headers: [String: String] = [:], callback: @escaping (DBLiveRequestResult?, Error?) -> Void) {
		requestResult(url: url, method: "PUT", params: params, headers: headers, callback: callback)
	}
	
	func putJson(url: URL, params: [String: Any] = [:], headers: [String: String] = [:], callback: @escaping (DBLiveJsonRequestResult?, Error?) -> Void) {
		requestJsonResult(url: url, method: "PUT", params: params, headers: headers, callback: callback)
	}
	
	func request(url: URL, method: String = "GET", params: [String : Any] = [:], headers: [String : String] = [:], callback: @escaping (Data?, URLResponse?, Error?) -> Void) {
		var url = url
		
		// set parameters as querystring for a GET call
		if method == "GET", params.count > 0 {
			var urlComponents = URLComponents(string: url.absoluteString)!
			urlComponents.percentEncodedQuery = params.map{ "\($0)=\(($1 as? String)?.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? $1)" }.joined(separator: "&")
			url = urlComponents.url!
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = method
		request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
		
		// add headers
		for (headerName, headerValue) in headers {
			request.addValue(headerValue, forHTTPHeaderField: headerName)
		}
		
		// set parameters as a JSON request body for non-GET calls
		if method != "GET" {
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			request.httpBody = try? JSONSerialization.data(withJSONObject: params)
		}
		
		logger.debug("\(method) \(url.absoluteString) \(params)")
		
		// make call
		URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
			guard let this = self else { return }
			
			guard error == nil else { return callback(nil, nil, error) }

			guard let data = data else { return callback(nil, nil, DBLiveRequestErrors.malformedRequestData) }

			this.logger.debug("\(url.absoluteString) responded")
			
			callback(data, response, nil)
		}.resume()
	}
		
	func requestJsonResult(url: URL, method: String = "GET", params: [String: Any] = [:], headers: [String: String] = [:], callback: @escaping (DBLiveJsonRequestResult?, Error?) -> Void) {
		requestResult(url: url, method: method, params: params, headers: headers) { result, error in
			if let result = result {
				let json = try? JSONSerialization.jsonObject(with: result.data) as? [String: Any]
				
				callback(DBLiveJsonRequestResult(json: json, response: result.response), nil)
			}
			else {
				callback(nil, error ?? DBLiveRequestErrors.emptyDataResponse)
			}
		}
	}
	
	func requestResult(url: URL, method: String = "GET", params: [String: Any] = [:], headers: [String: String] = [:], callback: @escaping (DBLiveRequestResult?, Error?) -> Void) {
		request(url: url, method: method, params: params, headers: headers) { data, response, error in
			if let data = data, let response = response {
				callback(DBLiveRequestResult(data: data, response: response), nil)
			}
			else {
				callback(nil, error ?? DBLiveRequestErrors.emptyDataResponse)
			}
		}
	}
}

struct DBLiveRequestResult
{
	let data: Data
	let response: URLResponse
}

struct DBLiveJsonRequestResult
{
	let json: [String:Any]?
	let response: URLResponse
}

class DBLiveRequestErrors
{
	static var emptyDataResponse: Error {
		get { return NSError(domain: Bundle.main.bundleIdentifier!, code: 1000, userInfo: nil) }
	}

	static var malformedRequestData: Error {
		get { return NSError(domain: Bundle.main.bundleIdentifier!, code: 1001, userInfo: nil) }
	}
}
