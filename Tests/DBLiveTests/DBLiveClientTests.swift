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
		
		DBLiveLogger.logLevel = .debug
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
	
	func testSet() {
		let expectation = XCTestExpectation(description: "DBLiveClient is able to set a string value")
				
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
			let key = "testOnKeyChanged-\(UUID())",
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
	
	func testGetJsonAndListen() {
		let expectation = XCTestExpectation(description: "DBLiveClient is able to put a string value")
		
		DBLTestClientFactory.create(expectation: expectation) { dbLiveClient in
			let key = "testGetJsonAndListen-\(UUID())"
			
			var listener: DBLiveKeyEventListener? = nil,
				count = 0
			
			listener = dbLiveClient.getJsonAndListen(key) { result in
				count += 1
				
				if count == 1 {
					XCTAssertNil(result)
					
					dbLiveClient.set(key, value: ["hello": "world"]) { success in
						XCTAssertTrue(success)
					}
				}
				else if count == 2 {
					XCTAssertNotNil(result)
					XCTAssertEqual(result?["hello"] as? String, "world")
					
					dbLiveClient.set(key, value: ["hello2": "world2"]) { success in
						XCTAssertTrue(success)
					}
				}
				else if count == 3 {
					XCTAssertNotNil(result)
					XCTAssertEqual(result?["hello2"] as? String, "world2")
					XCTAssertNil(result?["hello"])
					
					listener!.isListening = false
					
					dbLiveClient.set(key, value: ["hello3": "world3"]) { success in
						XCTAssertTrue(success)
						expectation.fulfill()
					}
				}
				else {
					XCTFail("Listener should never be called this many times")
				}
			}
		}
		
		wait(for: [expectation], timeout: 10.0)
	}

    static var allTests = [
        ("testSuccessfulConnection", testSuccessfulConnection),
		("testConnectionWithBadAppKey", testConnectionWithBadAppKey),
		("testSet", testSet),
		("testGet", testGet),
		("testOnKeyChanged", testOnKeyChanged)
    ]
	
}
