//
//  DBLiveClientTests.swift
//  
//
//  Created by Mike Richards on 5/20/20.
//

import XCTest
@testable import DBLive

final class DBLiveClientTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		
		DBLiveLogger.doLog = true
	}
	
    func testSuccessfulConnection() {
		let expectation = XCTestExpectation(description: "DBLiveClient connects successfully.")

		DBLTestClientFactory.create(expectation: expectation) { data in
			XCTAssertEqual(data.attributeKeys.count, 0)
			expectation.fulfill()
		}
		
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
				
		DBLTestClientFactory.create(expectation: expectation) { dbLiveClient in
			dbLiveClient.set("hello", value: "world") { result in
				XCTAssertTrue(result)
				expectation.fulfill()
			}
		}
		
		wait(for: [expectation], timeout: 10.0)
	}
	
	func testGet() {
		let expectation = XCTestExpectation(description: "DBLiveClient is able to put a string value")
		
		DBLTestClientFactory.create(expectation: expectation) { dbLiveClient in
			let key = "ios-testPut-\(UUID())",
				value = "ios-testPut-value-\(UUID())"

			dbLiveClient.set(key, value: value) { result in
				XCTAssertTrue(result)
				
				dbLiveClient.get(key) { result in
					XCTAssertEqual(result, value)
					expectation.fulfill()
				}
			}
		}
		
		wait(for: [expectation], timeout: 10.0)
	}
	
	func testOnKeyChanged() {
		let expectation = XCTestExpectation(description: "DBLiveClient is able to put a string value")
		
		DBLTestClientFactory.create(expectation: expectation) { dbLiveClient in
			let key = "testOnKeyChanged",
				value = UUID().description
			
			dbLiveClient.key(key).onChanged { newValue in
				if let newValue = newValue {
					XCTAssertEqual(newValue, value)
				}
				else {
					XCTFail("newValue shouldn't be nil")
				}
				
				expectation.fulfill()
			}
			
			dbLiveClient.set(key, value: value) { result in
				XCTAssertTrue(result)
			}
		}
		
		wait(for: [expectation], timeout: 10.0)
	}

    static var allTests = [
        ("testSuccessfulConnection", testSuccessfulConnection),
		("testConnectionWithBadAppKey", testConnectionWithBadAppKey),
		("testPut", testPut),
		("testGet", testGet),
		("testOnKeyChanged", testOnKeyChanged)
    ]
	
}
