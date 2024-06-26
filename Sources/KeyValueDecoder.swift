//
//  KeyValueDecoder.swift
//  DictionaryDecoder
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
import CoreFoundation

/// Top level encoder that converts `[String: Any]`, `[Any]` or `Any` into `Codable` types.
public final class KeyValueDecoder {

    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey: Any]

    /// The strategy to use for decoding `nil`. Defaults to `Optional<Any>.none` which can be decoded to any optional type.
    public var nilDecodingStrategy: NilDecodingStrategy = .default

    /// Initializes `self` with default strategies.
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
            nilDecodingStrategy: nilDecodingStrategy
        )
        return try container.decode(type)
    }

    /// Strategy used to decode nil values.
    public typealias NilDecodingStrategy = NilCodingStrategy
}

extension KeyValueDecoder {

    static func makePlistCompatible() -> KeyValueDecoder {
        let decoder = KeyValueDecoder()
        decoder.nilDecodingStrategy = .stringNull
        return decoder
    }
}

private extension KeyValueDecoder {

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
                nilDecodingStrategy: container.nilDecodingStrategy
            )
            return KeyedDecodingContainer(keyed)
        }

        func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
            let storage = try container.decode([Any].self)
            return UnkeyedContainer(
                codingPath: codingPath,
                storage: storage,
                userInfo: userInfo,
                nilDecodingStrategy: container.nilDecodingStrategy
            )
        }

        func singleValueContainer() throws -> any SingleValueDecodingContainer {
            container
        }
    }

    struct SingleContainer: SingleValueDecodingContainer {

        let codingPath: [any CodingKey]
        let userInfo: [CodingUserInfoKey: Any]
        let nilDecodingStrategy: NilDecodingStrategy

        private var value: Any

        init(
            value: Any,
            codingPath: [any CodingKey],
            userInfo: [CodingUserInfoKey: Any],
            nilDecodingStrategy: NilDecodingStrategy
        ) {
            self.value = value
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.nilDecodingStrategy = nilDecodingStrategy
        }

        func decodeNil() -> Bool {
            nilDecodingStrategy.isNull(value)
        }

        private var valueDescription: String {
            nilDecodingStrategy.isNull(value) ? "nil" : String(describing: type(of: value))
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
                guard let val = T(exactly: binaryInt) else {
                    let context = DecodingError.Context(codingPath: codingPath, debugDescription: "\(valueDescription) at \(codingPath.makeKeyPath()), cannot be exactly represented by \(type)")
                    throw DecodingError.typeMismatch(type, context)
                }
                return val
            } else if let int64 = (value as? NSNumber)?.getInt64Value() {
                guard let val = T(exactly: int64) else {
                    let context = DecodingError.Context(codingPath: codingPath, debugDescription: "\(valueDescription) at \(codingPath.makeKeyPath()), cannot be exactly represented by \(type)")
                    throw DecodingError.typeMismatch(type, context)
                }
                return val
            } else if let double = (value as? NSNumber)?.getDoubleValue() {
                let val = T(double)
                guard Double(val) == double else {
                    let context = DecodingError.Context(codingPath: codingPath, debugDescription: "\(valueDescription) at \(codingPath.makeKeyPath()), cannot be exactly represented by \(type)")
                    throw DecodingError.typeMismatch(type, context)
                }
                return val
            }
            else {
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
               let url = URL(string: string){
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
            try getValue()
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
        private let nilDecodingStrategy: NilDecodingStrategy

        init(
            codingPath: [any CodingKey],
            storage: [String: Any],
            userInfo: [CodingUserInfoKey: Any],
            nilDecodingStrategy: NilDecodingStrategy
        ) {
            self.codingPath = codingPath
            self.storage = storage
            self.userInfo = userInfo
            self.nilDecodingStrategy = nilDecodingStrategy
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
            guard let value = storage[key.stringValue] else {
                let keyPath = codingPath.makeKeyPath(appending: key)
                let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Dictionary does not contain key \(keyPath)")
                throw DecodingError.keyNotFound(key, context)
            }
            return SingleContainer(
                value: value,
                codingPath: path,
                userInfo: userInfo,
                nilDecodingStrategy: nilDecodingStrategy
            )
        }

        func contains(_ key: Key) -> Bool {
            return storage[key.stringValue] != nil
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
                nilDecodingStrategy: nilDecodingStrategy
            )
            return KeyedDecodingContainer<NestedKey>(keyed)
        }

        func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer {
            let container = try container(for: key)
            return try UnkeyedContainer(
                codingPath: container.codingPath,
                storage: container.decode([Any].self),
                userInfo: userInfo,
                nilDecodingStrategy: nilDecodingStrategy
            )
        }

        func superDecoder() throws -> any Swift.Decoder {
            let container = SingleContainer(
                value: storage,
                codingPath: codingPath,
                userInfo: userInfo,
                nilDecodingStrategy: nilDecodingStrategy
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
        private let nilDecodingStrategy: NilDecodingStrategy

        init(
            codingPath: [any CodingKey],
            storage: [Any],
            userInfo: [CodingUserInfoKey: Any],
            nilDecodingStrategy: NilDecodingStrategy
        ) {
            self.codingPath = codingPath
            self.storage = storage
            self.userInfo = userInfo
            self.nilDecodingStrategy = nilDecodingStrategy
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
                nilDecodingStrategy: nilDecodingStrategy
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
                nilDecodingStrategy: nilDecodingStrategy
            )
            return Decoder(container: container)
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

    func getNumberTypeID() -> CFNumberType? {
        guard CFGetTypeID(self as CFTypeRef) == CFNumberGetTypeID() else { return nil }
#if canImport(Darwin)
        return CFNumberGetType(self as CFNumber)
#else
        guard type(of: self) != type(of: NSNumber(true)) else { return nil }
        switch String(cString: objCType) {
        case "c": return CFNumberType.charType
        case "s": return CFNumberType.shortType
        case "i": return CFNumberType.intType
        case "q": return CFNumberType.longLongType
        case "d": return CFNumberType.doubleType
        case "f": return CFNumberType.floatType
        case "Q": return CFNumberType.longLongType
        default: return nil
        }
#endif
    }
}
