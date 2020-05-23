import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
		testCase(DBLiveClientTests.allTests),
        testCase(DBLiveTests.allTests),
    ]
}
#endif
