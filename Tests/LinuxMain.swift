import XCTest

import DBLiveClientTests
import DBLiveTests

var tests = [XCTestCaseEntry]()
tests += DBLiveClientTests.allTests
tests += DBLiveTests.allTests()
XCTMain(tests)
