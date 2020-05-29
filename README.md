# DBLive
DBLive client for iOS/macOS

DBLive is a service that allows devices to stay synchronized in real-time. Updates to data are instantly passed to all devices within a matter of ms, even at scale across regions.

## Development
This project is in initial development. No website or admin portal are available at this time. If you would like to use this library, please contact me at [dblive@mikerichards.tech](mailto:dblive@mikerichards.tech).

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

#### Methods
`set(_ key: String, value: String)`: Sets `key` to a string value.

`set(_ key: String, value: [String: Any])`: Sets `key` to a dictionary value. The dictionary can handle any object that can be serialized into JSON.

`get(_ key: String) { (value: String?) in
}`: Gets the current **String** value of `key`

`getJson(_ key: String) { (value: [String: Any]?) in
}`: Gets the current **Dictionary** value of `key`

`getAndListen(_ key: String) { (value: String?) in 
} -> DBLiveKeyEventListener`: Gets the current **String** value of `key` returned immediately, and then listens for any updates to its value. Set the `.isListening` property of the returned `DBLiveKeyEventListener` to `false` to stop listening.

`getJsonAndListen(_ key: String) { (value: String?) in 
} -> DBLiveKeyEventListener`: Gets the current **Dictionary** value of `key` returned immediately, and then listens for any updates to its value. Set the `.isListening` property of the returned `DBLiveKeyEventListener` to `false` to stop listening.

#### Planned future functionality
  * `set` and `get` will be restricted based on appKey. Individual devices can be granted additional functionalitality via a *secret key* that can be stored securely in your backend system.
  * `lockAndSet`: Will grant a temporary lock on a key so no other device can change its value. This will help assure that setting the value will not override a `set` from another device.
  * `Int values`: Ints will have additional functionality, such as incrementing and decrementing in a way that 2 devices can simultaneously do it.

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
        .package(url: "https://github.com/DBLive/dblive-client-ios-macos", .upToNextMinor(from: "0.0.1-alpha.11"))
    ],
    targets: [
        .target(name: "YourTargetName", dependencies: ["DBLive"])
    ]
)
```

## Example
[TicTacToe - SwiftUI](https://github.com/DBLive/dblive-ios-example-tictactoe-swiftui)
