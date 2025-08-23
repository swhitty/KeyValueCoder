//
//  KeyValueDecoder.swift
//  KeyValueCoder
//
//  Created by Simon Whitty on 16/17/2023.
//  Copyright 2023 Simon Whitty
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/swhitty/KeyValueCoder
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

/// Top level encoder that converts `[String: Any]`, `[Any]` or `Any` into `Codable` types.
public struct KeyValueDecoder: Sendable {

    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey: any Sendable]

    /// The strategy to use for decoding Date types.
    public var dateDecodingStrategy: DateDecodingStrategy = .date

    /// The strategy to use for decoding BinaryInteger types. Defaults to `.exact` for lossless conversion between types.
    public var intDecodingStrategy: IntDecodingStrategy = .exact

    /// The strategy to use for decoding each types keys.
    public var keyDecodingStrategy: KeyDecodingStrategy = .useDefaultKeys

    /// The strategy to use for decoding `nil`. Defaults to `Optional<Any>.none` which can be decoded to any optional type.
    public var nilDecodingStrategy: NilDecodingStrategy = .default

    /// Initializes `self` with default strategy.
    public init () {
        self.userInfo = [:]
    }

    ///
    /// Decodes any loosely typed key value  into a `Decodable` type.
    /// - Parameters:
    ///   - type: The `Decodable` type to decode.
    ///   - value: The value to decode. May be `[Any]`, `[String: Any]` or any supported primitive `Bool`,
    ///            `String`, `Int`, `UInt`, `URL`, `Data` or `Decimal`.
    /// - Returns: The decoded instance of `type`.
    ///
    /// - Throws: `DecodingError` if a value cannot be decoded. The context will contain a keyPath of the failed property.
    public func decode<T: Decodable>(_ type: T.Type = T.self, from value: Any) throws -> T {
        let container = SingleContainer(
            value: value,
            codingPath: [],
            userInfo: userInfo,
            strategy: strategy
        )
        return try container.decode(type)
    }

    /// Strategy used to decode nil values.
    public typealias NilDecodingStrategy = NilCodingStrategy

    public enum IntDecodingStrategy: Sendable {
        /// Decodes all number types with lossless conversion or throws error.
        case exact

        /// Decodes all floating point numbers using the provided rounding rule.
        case rounding(rule: FloatingPointRoundingRule)

        /// Clamps all integers to their min / max.
        /// Floating point conversions are also clamped, rounded when a rule is provided
        case clamping(roundingRule: FloatingPointRoundingRule?)
    }

    /// Strategy to determine how to decode a type’s coding keys from String values.
    public enum KeyDecodingStrategy: Sendable {
        /// A key decoding strategy that converts snake-case keys to camel-case keys.
        case convertFromSnakeCase

        /// A key encoding strategy that doesn’t change key names during encoding.
        case useDefaultKeys
    }

    public enum DateDecodingStrategy: Sendable {

        /// Decodes dates by casting from Any.
        case date

        /// Decodes dates in terms of milliseconds since midnight UTC on January 1st, 1970.
        case millisecondsSince1970

        /// Decodes dates in terms of seconds since midnight UTC on January 1st, 1970.
        case secondsSince1970

        /// Decodes dates from Any using a closure
        case custom(@Sendable (Any) throws -> Date)

        /// Decodes dates from ISO8601 strings.
        static func iso8601(options: ISO8601DateFormatter.Options = [.withInternetDateTime]) -> Self {
            .custom {
                guard let string = $0 as? String else {
                    throw Error("Expected String but found \(type(of: $0))")
                }
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = options
                guard let date = formatter.date(from: string) else {
                    throw Error("Failed to decode Date from ISO8601 string \(string)")
                }
                return date
            }
        }
    }

    struct Error: LocalizedError {
        var errorDescription: String?
        init(_ message: String) {
            self.errorDescription = message
        }
    }
}

#if canImport(Combine)
import Combine
extension KeyValueDecoder: TopLevelDecoder {
    public typealias Input = Any
}
#endif

extension KeyValueDecoder {

    static func makePlistCompatible() -> KeyValueDecoder {
        var decoder = KeyValueDecoder()
        decoder.nilDecodingStrategy = .stringNull
        return decoder
    }
}

private extension KeyValueDecoder {

    struct DecodingStrategy {
        var optionals: NilDecodingStrategy
        var integers: IntDecodingStrategy
        var keys: KeyDecodingStrategy
        var dates: DateDecodingStrategy
    }

    var strategy: DecodingStrategy {
        DecodingStrategy(
            optionals: nilDecodingStrategy,
            integers: intDecodingStrategy,
            keys: keyDecodingStrategy,
            dates: dateDecodingStrategy
        )
    }

    struct Decoder: Swift.Decoder {

        private let container: SingleContainer
        let codingPath: [any CodingKey]
        let userInfo: [CodingUserInfoKey: Any]

        init(container: SingleContainer) {
            self.container = container
            self.codingPath = container.codingPath
            self.userInfo = container.userInfo
        }

        func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
            let keyed = try KeyedContainer<Key>(
                codingPath: codingPath,
                storage: container.decode([String: Any].self),
                userInfo: userInfo,
                strategy: container.strategy
            )
            return KeyedDecodingContainer(keyed)
        }

        func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
            let storage = try container.decode([Any].self)
            return UnkeyedContainer(
                codingPath: codingPath,
                storage: storage,
                userInfo: userInfo,
                strategy: container.strategy
            )
        }

        func singleValueContainer() throws -> any SingleValueDecodingContainer {
            container
        }
    }

    struct SingleContainer: SingleValueDecodingContainer {

        let codingPath: [any CodingKey]
        let userInfo: [CodingUserInfoKey: Any]
        let strategy: DecodingStrategy

        private var value: Any

        init(
            value: Any,
            codingPath: [any CodingKey],
            userInfo: [CodingUserInfoKey: Any],
            strategy: DecodingStrategy
        ) {
            self.value = value
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.strategy = strategy
        }

        func decodeNil() -> Bool {
            strategy.optionals.isNull(value)
        }

        private var valueDescription: String {
            strategy.optionals.isNull(value) ? "nil" : String(describing: type(of: value))
        }

        func getValue<T>(of type: T.Type = T.self) throws -> T {
            guard let value = self.value as? T else {
                let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(type) at \(codingPath.makeKeyPath()), found \(valueDescription)")
                if decodeNil() {
                    throw DecodingError.valueNotFound(type, context)
                } else {
                    throw DecodingError.typeMismatch(type, context)
                }
            }
            return value
        }

        func getBinaryInteger<T: BinaryInteger>(of type: T.Type = T.self) throws -> T {
            if let binaryInt = value as? any BinaryInteger {
                guard let val = T(from: binaryInt, using: strategy.integers) else {
                    let context = DecodingError.Context(codingPath: codingPath, debugDescription: "\(valueDescription) at \(codingPath.makeKeyPath()), cannot be exactly represented by \(type)")
                    throw DecodingError.typeMismatch(type, context)
                }
                return val
            } else if let int64 = (value as? NSNumber)?.getInt64Value() {
                guard let val = T(from: int64, using: strategy.integers) else {
                    let context = DecodingError.Context(codingPath: codingPath, debugDescription: "\(valueDescription) at \(codingPath.makeKeyPath()), cannot be exactly represented by \(type)")
                    throw DecodingError.typeMismatch(type, context)
                }
                return val
            } else if let double = (value as? NSNumber)?.getDoubleValue() {
                guard let val = T(from: double, using: strategy.integers) else {
                    let context = DecodingError.Context(codingPath: codingPath, debugDescription: "\(valueDescription) at \(codingPath.makeKeyPath()), cannot be exactly represented by \(type)")
                    throw DecodingError.typeMismatch(type, context)
                }
                return val
            } else {
                let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Expected BinaryInteger at \(codingPath.makeKeyPath()), found \(valueDescription)")
                if decodeNil() {
                    throw DecodingError.valueNotFound(type, context)
                } else {
                    throw DecodingError.typeMismatch(type, context)
                }
            }
        }

        func decode(_ type: Bool.Type) throws -> Bool {
            try getValue()
        }

        func decode(_ type: String.Type) throws -> String {
            try getValue()
        }

        func decode(_ type: Double.Type) throws -> Double {
            if let double = (value as? NSNumber)?.getDoubleValue() {
                return double
            } else if let int64 = try? getBinaryInteger(of: Int64.self) {
                return Double(int64)
            } else if let uint64 = try? getBinaryInteger(of: UInt64.self) {
                return Double(uint64)
            } else {
                return try getValue()
            }
        }

        func decode(_ type: Float.Type) throws -> Float {
            if let double = (value as? NSNumber)?.getDoubleValue() {
                return Float(double)
            } else if let int64 = try? getBinaryInteger(of: Int64.self) {
                return Float(int64)
            } else if let uint64 = try? getBinaryInteger(of: UInt64.self) {
                return Float(uint64)
            } else {
                return try getValue()
            }
        }

        func decode(_ type: Int.Type) throws -> Int {
            try getBinaryInteger()
        }

        func decode(_ type: Int8.Type) throws -> Int8 {
            try getBinaryInteger()
        }

        func decode(_ type: Int16.Type) throws -> Int16 {
            try getBinaryInteger()
        }

        func decode(_ type: Int32.Type) throws -> Int32 {
            try getBinaryInteger()
        }

        func decode(_ type: Int64.Type) throws -> Int64 {
            try getBinaryInteger()
        }

        func decode(_ type: UInt.Type) throws -> UInt {
            try getBinaryInteger()
        }

        func decode(_ type: UInt8.Type) throws -> UInt8 {
            try getBinaryInteger()
        }

        func decode(_ type: UInt16.Type) throws -> UInt16 {
            try getBinaryInteger()
        }

        func decode(_ type: UInt32.Type) throws -> UInt32 {
            try getBinaryInteger()
        }

        func decode(_ type: UInt64.Type) throws -> UInt64 {
            try getBinaryInteger()
        }

        func decode(_ type: [Any].Type) throws -> [Any] {
            try getValue()
        }

        func decode(_ type: [String: Any].Type) throws -> [String: Any] {
            try getValue()
        }

        func decode(_ type: URL.Type) throws -> URL {
            if let string = value as? String,
               !string.isEmpty,
               let url = URL(string: string) {
                return url
            }
            return try getValue()
        }

        func decode(_ type: Decimal.Type) throws -> Decimal {
            if let double = (value as? NSNumber)?.getDoubleValue(), !(value is Decimal) {
                return Decimal(double)
            } else if let int64 = try? getBinaryInteger(of: Int64.self) {
                return Decimal(int64)
            } else if let uint64 = try? getBinaryInteger(of: UInt64.self) {
                return Decimal(uint64)
            } else {
                return try getValue()
            }
        }

        func decode(_ type: Date.Type) throws -> Date {
            switch strategy.dates {
            case .date:
                return try getValue()
            case .millisecondsSince1970:
                return try Date(timeIntervalSince1970: TimeInterval(decode(Int.self)) / 1000)

            case .secondsSince1970:
                return try Date(timeIntervalSince1970: TimeInterval(decode(Int.self)))

            case .custom(let transform):
                do {
                    return try transform(self.value)
                } catch {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: error.localizedDescription))
                }
            }
        }

        func decode(_ type: Data.Type) throws -> Data {
            try getValue()
        }

        func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
            if type == Date.self || type == NSDate.self {
                return try decode(Date.self) as! T
            }

            if type == Data.self || type == NSData.self {
                return try decode(Data.self) as! T
            }

            if type == Decimal.self || type == NSDecimalNumber.self {
                return try decode(Decimal.self) as! T
            }

            if type == URL.self || type == NSURL.self {
                return try decode(URL.self) as! T
            }

            return try T(from: Decoder(container: self))
        }
    }

    struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {

        let storage: [String: Any]
        let codingPath: [any CodingKey]
        private let userInfo: [CodingUserInfoKey: Any]
        private let strategy: DecodingStrategy

        init(
            codingPath: [any CodingKey],
            storage: [String: Any],
            userInfo: [CodingUserInfoKey: Any],
            strategy: DecodingStrategy
        ) {
            self.codingPath = codingPath
            self.storage = storage
            self.userInfo = userInfo
            self.strategy = strategy
        }

        var allKeys: [Key] {
            return storage.keys.compactMap {
                Key(stringValue: $0)
            }
        }

        func getValue<T: Decodable>(of type: T.Type = T.self, for key: Key) throws -> T {
            try container(for: key).decode(type)
        }

        func container(for key: Key) throws -> SingleContainer {
            let path = codingPath.appending(key: key)
            let kkk = strategy.keys.makeStorageKey(for: key.stringValue)
            guard let value = storage[kkk] else {
                let keyPath = codingPath.makeKeyPath(appending: key)
                let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Dictionary does not contain key \(keyPath)")
                throw DecodingError.keyNotFound(key, context)
            }
            return SingleContainer(
                value: value,
                codingPath: path,
                userInfo: userInfo,
                strategy: strategy
            )
        }

        func contains(_ key: Key) -> Bool {
            return storage[strategy.keys.makeStorageKey(for: key.stringValue)] != nil
        }

        func decodeNil(forKey key: Key) throws -> Bool {
            try container(for: key).decodeNil()
        }

        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
            try getValue(for: key)
        }

        func decode(_ type: String.Type, forKey key: Key) throws -> String {
            try getValue(for: key)
        }

        func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
            try getValue(for: key)
        }

        func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
            try getValue(for: key)
        }

        func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
            try getValue(for: key)
        }

        func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
            try getValue(for: key)
        }

        func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
            try getValue(for: key)
        }

        func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
            try getValue(for: key)
        }

        func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
            try getValue(for: key)
        }

        func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
            try getValue(for: key)
        }

        func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
            try getValue(for: key)
        }

        func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
            try getValue(for: key)
        }

        func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
            try getValue(for: key)
        }

        func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
            try getValue(for: key)
        }

        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
            try getValue(for: key)
        }

        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
            let container = try container(for: key)
            let keyed = try KeyedContainer<NestedKey>(
                codingPath: container.codingPath,
                storage: container.decode([String: Any].self),
                userInfo: userInfo,
                strategy: strategy
            )
            return KeyedDecodingContainer<NestedKey>(keyed)
        }

        func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer {
            let container = try container(for: key)
            return try UnkeyedContainer(
                codingPath: container.codingPath,
                storage: container.decode([Any].self),
                userInfo: userInfo,
                strategy: strategy
            )
        }

        func superDecoder() throws -> any Swift.Decoder {
            let container = SingleContainer(
                value: storage,
                codingPath: codingPath,
                userInfo: userInfo,
                strategy: strategy
            )
            return Decoder(container: container)
        }

        func superDecoder(forKey key: Key) throws -> any Swift.Decoder {
            try Decoder(container: container(for: key))
        }
    }

    struct UnkeyedContainer: UnkeyedDecodingContainer {

        let codingPath: [any CodingKey]

        let storage: [Any]
        private let userInfo: [CodingUserInfoKey: Any]
        private let strategy: DecodingStrategy

        init(
            codingPath: [any CodingKey],
            storage: [Any],
            userInfo: [CodingUserInfoKey: Any],
            strategy: DecodingStrategy
        ) {
            self.codingPath = codingPath
            self.storage = storage
            self.userInfo = userInfo
            self.strategy = strategy
            self.currentIndex = storage.startIndex
        }

        var count: Int? {
            return storage.count
        }

        var isAtEnd: Bool {
            return currentIndex == storage.endIndex
        }

        private(set) var currentIndex: Int

        func nextContainer() throws -> SingleContainer {
            let path = codingPath.appending(index: currentIndex)
            guard isAtEnd == false else {
                let keyPath = codingPath.makeKeyPath(appending: AnyCodingKey(intValue: currentIndex))
                let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Array does not contain index \(keyPath)")
                throw DecodingError.keyNotFound(AnyCodingKey(intValue: currentIndex), context)
            }
            return SingleContainer(
                value: storage[currentIndex],
                codingPath: path,
                userInfo: userInfo,
                strategy: strategy
            )
        }

        mutating func decodeNext<T: Decodable>(of type: T.Type = T.self) throws -> T {
            let result = try nextContainer().decode(T.self)
            currentIndex = storage.index(after: currentIndex)
            return result
        }

        mutating func decodeNil() throws -> Bool {
            let result = try nextContainer().decodeNil()
            currentIndex = storage.index(after: currentIndex)
            return result
        }

        mutating func decode(_ type: Bool.Type) throws -> Bool {
            try decodeNext()
        }

        mutating func decode(_ type: String.Type) throws -> String {
            try decodeNext()
        }

        mutating func decode(_ type: Double.Type) throws -> Double {
            try decodeNext()
        }

        mutating func decode(_ type: Float.Type) throws -> Float {
            try decodeNext()
        }

        mutating func decode(_ type: Int.Type) throws -> Int {
            try decodeNext()
        }

        mutating func decode(_ type: Int8.Type) throws -> Int8 {
            try decodeNext()
        }

        mutating func decode(_ type: Int16.Type) throws -> Int16 {
            try decodeNext()
        }

        mutating func decode(_ type: Int32.Type) throws -> Int32 {
            try decodeNext()
        }

        mutating func decode(_ type: Int64.Type) throws -> Int64 {
            try decodeNext()
        }

        mutating func decode(_ type: UInt.Type) throws -> UInt {
            try decodeNext()
        }

        mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
            try decodeNext()
        }

        mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
            try decodeNext()
        }

        mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
            try decodeNext()
        }

        mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
            try decodeNext()
        }

        mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
            try decodeNext()
        }

        mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
            let result = try Decoder(container: nextContainer()).container(keyedBy: type)
            currentIndex = storage.index(after: currentIndex)
            return result
        }

        mutating func nestedUnkeyedContainer() throws -> any UnkeyedDecodingContainer {
            let result = try Decoder(container: nextContainer()).unkeyedContainer()
            currentIndex = storage.index(after: currentIndex)
            return result
        }

        mutating func superDecoder() -> any Swift.Decoder {
            let container = SingleContainer(
                value: storage,
                codingPath: codingPath,
                userInfo: userInfo,
                strategy: strategy
            )
            return Decoder(container: container)
        }
    }
}

extension KeyValueDecoder.KeyDecodingStrategy {

    func makeStorageKey(for key: String) -> String {
        switch self {
        case .useDefaultKeys: return key
        case .convertFromSnakeCase: return key.toSnakeCase()
        }
    }
}

extension BinaryInteger {

    init?(from source: Double, using strategy: KeyValueDecoder.IntDecodingStrategy) {
        switch strategy {
        case .exact:
            self.init(exactly: source)
        case .rounding(rule: let rule):
            self.init(exactly: source.rounded(rule))
        case .clamping(roundingRule: let rule):
           self.init(clamping: source, rule: rule)
        }
    }

    init?(from source: some BinaryInteger, using strategy: KeyValueDecoder.IntDecodingStrategy) {
        switch strategy {
        case .exact, .rounding:
            self.init(exactly: source)
        case .clamping:
            self.init(clamping: source)
        }
    }

    private init?(clamping source: Double, rule: FloatingPointRoundingRule? = nil) {
        let rounded = rule.map(source.rounded) ?? source
        if let int = Int64(exactly: rounded) {
            self.init(clamping: int)
        } else if source > Double(Int64.max) {
            self.init(clamping: Int64.max)
        } else if source < Double(Int64.min) {
            self.init(clamping: Int64.min)
        } else {
            return nil
        }
    }
}

extension NSNumber {
    func getInt64Value() -> Int64? {
        guard let numberID = getNumberTypeID() else { return nil }
        switch numberID {
        case .intType, .sInt8Type, .sInt16Type, .sInt32Type, .sInt64Type, .nsIntegerType, .charType, .shortType, .longType, .longLongType:
            return int64Value
        default:
            return nil
        }
    }

    func getDoubleValue() -> Double? {
        guard let numberID = getNumberTypeID() else { return nil }
        switch numberID {
        case .doubleType, .floatType, .float32Type, .float64Type, .cgFloatType:
            return doubleValue
        default:
            return nil
        }
    }

    enum NumberTypeID: Int, Sendable {
        case sInt8Type       = 1
        case sInt16Type      = 2
        case sInt32Type      = 3
        case sInt64Type      = 4
        case float32Type     = 5
        case float64Type     = 6
        case charType        = 7
        case shortType       = 8
        case intType         = 9
        case longType        = 10
        case longLongType    = 11
        case floatType       = 12
        case doubleType      = 13
        case cfIndexType     = 14
        case nsIntegerType   = 15
        case cgFloatType     = 16
    }

    func getNumberTypeID() -> NumberTypeID? {
        // Prevent misclassifying Bool as charType
        if type(of: self) == type(of: NSNumber(value: true)) { return nil }

        switch String(cString: objCType) {
        case "c": return .charType
        case "C": return .sInt8Type
        case "s": return .shortType
        case "S": return .sInt16Type
        case "i": return .intType
        case "I": return .sInt32Type
        case "l": return .longType
        case "L": return .sInt32Type
        case "q": return .longLongType
        case "Q": return .sInt64Type
        case "f": return .floatType
        case "d": return .doubleType
        case "B": return nil
        default:  return nil
        }
    }
}
