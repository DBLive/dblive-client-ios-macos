# DBLive
DBLive client for iOS/OSX

## Usage

### Swift
```swift
import DBLive

let dbLive = DBLiveClient(appKey: "+++ appKey +++")

// set key "hello" to "world"
dbLive.set("hello", value: "world")

// get key "hello"
dbLive.get("hello") { value in
	print("hello '\(value)'") // prints "hello 'world'"
}

// get and listen to key "hello"
let listener = dbLive.getAndListen("hello") { value in
	print("hello '\(value)'") // prints "hello 'world'" immediately
	
	// this handler will be called every time "hello" changes until "listener.isListening" is false
}

// can start/stop listener by changing "isListening" on the listener
listener.isListening = true|false

// can also set, get and listen to json objects
dbLive.set("hello-json", value: [
	"hello": "world"
])

dbLive.getJson("hello-json") { value in
	let hello = value["hello"] as! String
	print("hello '\(hello)'") // prints "hello 'world'"
}

let listener = dbLive.getJsonAndListen("hello-json") { value in
	let hello = value["hello"] as! String
	print("hello '\(hello)'") // prints "hello 'world'" immediately
	
	// this handler will be called every time "hello-json" changes until "listener.isListening" is false
}

// can start/stop listener by changing "isListening" on the listener
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
