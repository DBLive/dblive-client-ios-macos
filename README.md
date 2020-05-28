# DBLive
DBLive client for iOS/OSX

## Example
```swift
import DBLive

let dbLive = DBLiveClient(appKey: "+++ appKey +++")

// set key
dbLive.set("hello", value: "world")

// get key
dbLive.get("hello") { value in
	print("value: '\(value)'") // prints "value: 'world'"
}

// get and listen
let listener = dbLive.getAndListen("hello") { value in
	print("value: '\(value)'") // prints "value: 'world'" immediately
	// will print new value every time "hello" changes until "listener.isListening" is false
}

listener.isListening = true|false
```

## Installation

### Swift Package Manager
Add the project as a dependency to your App/Package.swift
```swift
// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "YourPackage",
    products: [
        .executable(name: "YourPackage", targets: ["YourTargetName"])
    ],
    dependencies: [
		.package(url: "https://github.com/DBLive/dblive-client-ios-macos", .upToNextMinor(from: "0.0.1-alpha.10"))
    ],
    targets: [
        .target(name: "YourTargetName", dependencies: ["DBLive"])
    ]
)
```

## Example
[TicTacToe - SwiftUI](https://github.com/DBLive/dblive-ios-example-tictactoe-swiftui)
