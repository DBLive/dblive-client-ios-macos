import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
		testCase(DBLiveClientTests.allTests),
    ]
}
#endif
