[![Build](https://github.com/swhitty/KeyValueCoder/actions/workflows/build.yml/badge.svg)](https://github.com/swhitty/KeyValueCoder/actions/workflows/build.yml)
[![CodeCov](https://codecov.io/gh/swhitty/KeyValueCoder/branch/main/graphs/badge.svg)](https://codecov.io/gh/swhitty/KeyValueCoder/branch/main)
[![Swift 5.8](https://img.shields.io/badge/swift-5.7%20–%205.8-red.svg?style=flat)](https://developer.apple.com/swift)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://opensource.org/licenses/MIT)
[![Twitter](https://img.shields.io/badge/twitter-@simonwhitty-blue.svg)](http://twitter.com/simonwhitty)

# KeyValueCoder
A Swift library for serializing `Codable` types to and from `Any` and `UserDefaults`.

## Usage

Keyed types are encoded to a `[String: Any]`

```swift
struct User: Codable {
   var id: Int
   var name: String
}

// Decode from [String: Any]
let user = try KeyValueEncoder().decode(
  User.self, 
  from: ["id": 99, "name": "Herbert"]
)

// Encode to [String: Any]
let dict = try KeyValueEncoder().encode(user)
```

RawRepresentable types are encoded to their raw value:

```swift
// Encode to String
let string = try KeyValueEncoder().encode(Food(rawValue: "fish"))
```

Decode values from `Any`:

```swift
let user = try KeyValuDecoder().decode(User.self, from: ["id": 99, "name": "Herbert"])

let food = try KeyValuDecoder().decode(Food.self, from: "fish")
```
## UserDefaults
Store and retrieve any `Codable` type within UserDefaults:

```swift
try UserDefaults.standard.encode(
  User(id: "99", name: "Herbert"), 
  forKey: "owner"
)

try UserDefaults.standard.encode(
  URL(string: "fish.com"), 
  forKey: "url"
)

try UserDefaults.standard.encode(
  Duration.nanoseconds(1), 
  forKey: "duration"
)
```

Values are persisted in a friendly representation of plist native types:

```swift
let defaults = UserDefaults.standard.dictionaryRepresentation()

[
  "owner": ["id": 99, "name": "Herbert"],
  "url": URL(string: "fish.com”),
  "duration": [0, 1000000000]

]
```

Decode values from the defaults:

```swift
let owner = try UserDefaults.standard.decode(Person.self, forKey: "owner")

let url = try UserDefaults.standard.decode(URL.self, forKey: "url") 

let duration = try UserDefaults.standard.decode(Duration.self, forKey: "duration")
```

[`DecodingError`](https://developer.apple.com/documentation/swift/decodingerror) is thrown when decoding fails. [`Context`](https://developer.apple.com/documentation/swift/decodingerror/context) will include a keyPath to the failed property.

```swift
UserDefaults.standard.set(
  [
      ["id": 99, "name": "Herbert"],
      ["id": 100]
  ],
  forKey: "users"
)

// throws DecodingError.valueNotFound 'Expected String at SELF[1].name, found nil'
let users = try UserDefaults.standard.decode([User].self, forKey: "users") 
```
