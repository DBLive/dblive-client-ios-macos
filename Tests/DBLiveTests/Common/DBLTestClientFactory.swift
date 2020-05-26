//
//  DBLTestClientFactory.swift
//  
//
//  Created by Mike Richards on 5/23/20.
//

import XCTest
@testable import DBLive

final class DBLTestClientFactory
{
	static let testAppKey = "+EzwYKZrXI7eKn/KRtlhURsGsjyP2e+1++vqTDQH"
	
	@discardableResult
	static func create(expectation: XCTestExpectation, callback: ((DBLiveClient) -> Void)? = nil) -> DBLiveClient {
		let dbLiveClient = DBLiveClient(appKey: testAppKey)
		
		dbLiveClient.onError { error in
			XCTFail("An error should not have been thrown when connecting with a valid appKey.")
			expectation.fulfill()
		}
		
		if let callback = callback {
			dbLiveClient.connect {
				callback(dbLiveClient)
			}
		}
		
		return dbLiveClient
	}
}
