//
//  DBLiveClientTests.swift
//  
//
//  Created by Mike Richards on 5/20/20.
//

import XCTest
@testable import DBLive

let testAppKey = "+EzwYKZrXI7eKn/KRtlhURsGsjyP2e+1++vqTDQH"

final class DBLiveClientTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		
		DBLiveLogger.doLog = true
	}
	
    func testSuccessfulConnection() {
		let expectation = XCTestExpectation(description: "DBLiveClient connects successfully.")
		
		let dbLiveClient = DBLiveClient(appKey: testAppKey)
		
		dbLiveClient.on("connect") { data in
			expectation.fulfill()
		}
		
		dbLiveClient.onError { error in
			XCTFail("An error should not have been thrown when connecting with a valid appKey.")
			expectation.fulfill()
		}
				
		dbLiveClient.connect()
		
		wait(for: [expectation], timeout: 10.0)
    }
	
	func testConnectionWithBadAppKey() {
		let expectation = XCTestExpectation(description: "DBLiveClient throws error event for bad app key.")
		
		let dbLiveClient = DBLiveClient(appKey: "bad-app-key")
		
		dbLiveClient.on("connect") { data in
			XCTFail("DBLiveConnect should not connect with a bad app key.")
			expectation.fulfill()
		}
		
		dbLiveClient.onError { error in
			XCTAssertEqual(error.code, "invalid-app-key")
			expectation.fulfill()
		}
				
		dbLiveClient.connect()
		
		wait(for: [expectation], timeout: 10.0)
	}
	
	func testPut() {
		let expectation = XCTestExpectation(description: "DBLiveClient is able to put a string value")
		
		let dbLiveClient = DBLiveClient(appKey: testAppKey)
		
		dbLiveClient.on("connect") { data in
			dbLiveClient.set("hello", value: "world") { result in
				XCTAssertTrue(result)
				expectation.fulfill()
			}
		}
		
		dbLiveClient.onError { error in
			XCTFail("An error should not have been thrown when connecting with a valid appKey.")
			expectation.fulfill()
		}
				
		dbLiveClient.connect()
		
		wait(for: [expectation], timeout: 10.0)
	}

    static var allTests = [
        ("testSuccessfulConnection", testSuccessfulConnection),
		("testConnectionWithBadAppKey", testConnectionWithBadAppKey),
		("testPut", testPut)
    ]
	
}
