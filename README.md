[![Build](https://github.com/swhitty/KeyValueCoder/actions/workflows/build.yml/badge.svg)](https://github.com/swhitty/KeyValueCoder/actions/workflows/build.yml)
[![CodeCov](https://codecov.io/gh/swhitty/KeyValueCoder/branch/main/graphs/badge.svg)](https://codecov.io/gh/swhitty/KeyValueCoder/branch/main)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fswhitty%2FKeyValueCoder%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/swhitty/KeyValueCoder)
[![Swift 6.0](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fswhitty%2FKeyValueCoder%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/swhitty/KeyValueCoder)

# KeyValueCoder
A Swift library for serializing `Codable` types to and from `Any` and `UserDefaults`.

## Usage

[`RawRepresentable`](https://developer.apple.com/documentation/swift/rawrepresentable) types are encoded to their raw value:

```swift
// "fish"
let any = try KeyValueEncoder().encode(Food(rawValue: "fish"))
```

[`Collection`](https://developer.apple.com/documentation/swift/collection) types are encoded to `[Any]`:

```swift
// ["fish", "chips"]
let any = try KeyValueEncoder().encode(["fish", "chips"])
```

Structs and classes are encoded to `[String: Any]`:

```swift
struct User: Codable {
   var id: Int
   var name: String
}

// ["id": 1, "name": "Herbert"]
let any = try KeyValueEncoder().encode(User(id: 1, name: "Herbert"))
```

Decode values from `Any`:

```swift
let food = try KeyValueDecoder().decode(Food.self, from: "fish")

let meals = try KeyValueDecoder().decode([String].self, from: ["fish", "chips"])

let user = try KeyValueDecoder().decode(User.self, from: ["id": 1, "name": "Herbert"])
```

[`DecodingError`](https://developer.apple.com/documentation/swift/decodingerror) is thrown when decoding fails. [`Context`](https://developer.apple.com/documentation/swift/decodingerror/context) includes a keyPath to the failed property.

```swift
// throws DecodingError.typeMismatch 'Expected String at SELF[1], found Int'
let meals = try KeyValueDecoder().decode([String].self, from: ["fish", 1])

// throws DecodingError.valueNotFound 'Expected String at SELF[1].name, found nil'
let user = try KeyValueDecoder().decode(User.self, from: [["id": 1, "name": "Herbert"], ["id:" 2])

// throws DecodingError.typeMismatch 'Int at SELF[2], cannot be exactly represented by UInt8'
let ascii = try KeyValueDecoder().decode([UInt8].self, from: [10, 100, 1000])
```


## Date Encoding/Decoding Strategy

The encoding of `Date` can be adjusted by setting the strategy.  

By default `Date` instances are encoded by simply casting to `Any` but this adjusted by setting the strategy.  

The default strategy casts to `Any` leaving the instance unchanged:

```swift
var encoder = KeyValueEncoder()
encoder.dateEncodingStrategy = .date

// Date()
let any = try encoder.encode(Date())
```

ISO8601 compatible strings can be used:

```swift
encoder.dateEncodingStrategy = .iso8601()

// "1970-01-01T00:00:00Z"
let any = try encoder.encode(Date(timeIntervalSince1970: 0))
```

Epochs are also supported using `.secondsSince1970` and `millisecondsSince1970`.

## Nil Encoding/Decoding Strategy

The encoding of `Optional.none` can be adjusted by setting the strategy.  

The default strategy preserves `Optional.none`:

```swift
var encoder = KeyValueEncoder()
encoder.nilEncodingStrategy = .default

// [1, 2, nil, 3]
let any = try encoder.encode([1, 2, Int?.none, 3])
```

Compatibility with [`PropertyListEncoder`](https://developer.apple.com/documentation/foundation/propertylistencoder) is preserved using a placeholder string:

```swift
encoder.nilEncodingStrategy = .stringNull

// [1, 2, "$null", 3]
let any = try encoder.encode([1, 2, Int?.none, 3])
```

Compatibility with [`JSONSerialization`](https://developer.apple.com/documentation/foundation/jsonserialization) is preserved using [`NSNull`](https://developer.apple.com/documentation/foundation/nsnull):

```swift
encoder.nilEncodingStrategy = .nsNull

// [1, 2, NSNull(), 3]
let any = try encoder.encode([1, 2, Int?.none, 3])
```

Nil values can also be completely removed:

```swift
encoder.nilEncodingStrategy = .removed

// [1, 2, 3]
let any = try encoder.encode([1, 2, Int?.none, 3])
```

## Int Decoding Strategy

The decoding of [`BinaryInteger`](https://developer.apple.com/documentation/swift/binaryinteger) types (`Int`, `UInt` etc) can be adjusted via `intDecodingStrategy`.

The default strategy `IntDecodingStrategy.exact` ensures the source value is exactly represented by the decoded type allowing floating point values with no fractional part to be decoded:

```swift
// [10, 20, -30, 50]
let values = try KeyValueDecoder().decode([Int8].self, from: [10, 20.0, -30.0, Int64(50)])

// throws DecodingError.typeMismatch because 1000 cannot be exactly represented by Int8
_ = try KeyValueDecoder().decode(Int8.self, from: 1000])
```

Values with a fractional part can also be decoded to integers by rounding with any [`FloatingPointRoundingRule`](https://developer.apple.com/documentation/swift/floatingpointroundingrule):

```swift
var decoder = KeyValueDecoder()
decoder.intDecodingStrategy = .rounding(rule: .toNearestOrAwayFromZero)

// [10, -21, 50]
let values = try decoder.decode([Int].self, from: [10.1, -20.9, 50.00001]),
```

Values can also be clamped to the representable range:

```swift
var decoder = KeyValueDecoder()
decoder.intDecodingStrategy = .clamping(roundingRule: .toNearestOrAwayFromZero)

// [10, 21, 127, -128]
let values = try decoder.decode([Int8].self, from: [10, 20.5, 1000, -Double.infinity])
```

## Key Strategy

Keys can be encoded to snake_case by setting the strategy:

```swift
var encoder = KeyValueEncoder()
encoder.keyEncodingStrategy = .convertToSnakeCase

// ["first_name": "fish", "surname": "chips"]
let dict = try encoder.encode(Person(firstName: "fish", surname: "chips))
```

And decoded from snake_case:

```swift
var decoder = KeyValueDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase

let person = try decoder.decode(Person.self, from: dict)
```

## UserDefaults
Encode and decode [`Codable`](https://developer.apple.com/documentation/swift/codable) types with [`UserDefaults`](https://developer.apple.com/documentation/foundation/userdefaults):

```swift
try UserDefaults.standard.encode(
  User(id: "1", name: "Herbert"), 
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
  "owner": ["id": 1, "name": "Herbert"],
  "url": URL(string: "fish.com"),
  "duration": [0, 1000000000]
]
```

Decode values from the defaults:

```swift
let owner = try UserDefaults.standard.decode(Person.self, forKey: "owner")

let url = try UserDefaults.standard.decode(URL.self, forKey: "url") 

let duration = try UserDefaults.standard.decode(Duration.self, forKey: "duration")
```
