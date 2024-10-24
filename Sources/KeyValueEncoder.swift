//
//  KeyValueEncoder.swift
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

/// Top level encoder that converts `Codable` instances into loosely typed `[String: Any]`, `[Any]` or `Any`.
public final class KeyValueEncoder {

    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey: Any]

    /// The strategy to use for encoding `nil`. Defaults to `Optional<Any>.none` which can be cast to any optional type.
    public var nilEncodingStrategy: NilEncodingStrategy = .default

    /// Initializes `self` with default strategies.
    public init () {
        self.userInfo = [:]
    }

    /// Encodes a value into a loosely typed key value type. May be a container `[Any]`, `[String: Any]`
    /// or any supported plist primitive `Bool`, `String`, `Int`, `UInt`, `URL`, `Data` or `Decimal`.
    /// - Parameter value: The `Encodable` value to encode.
    /// - Returns: The encoded value.
    public func encode<T>(_ value: T) throws -> Any? where T: Encodable {
        try encodeValue(value).getValue(strategy: nilEncodingStrategy)
    }

    /// Strategy used to encode nil values.
    public typealias NilEncodingStrategy = NilCodingStrategy
}

/// Strategy used to encode and decode nil values.
public enum NilCodingStrategy {
    /// `nil` values are removed
    case removed

    /// `nil` values are substituted with a placeholder value
    case placeholder(Any, isNull: (Any) -> Bool)

    /// `nil` values are substituted with `Optional<Any>.none`. Can be cast to any optional type.
    public static var `default`: NilCodingStrategy { .placeholder(Optional<Any>.none as Any, isNull: isOptionalNone) }

    /// `nil` values are substituted with `"$null"` placeholder string. Compatible with `PropertyListEncoder`.
    public static var stringNull: NilCodingStrategy { .placeholder("$null", isNull: { ($0 as? String == "$null") }) }

    /// `nil` values are substituted with `"NSNull()"`. Compatible with `JSONSerialization`.
    public static var nsNull: NilCodingStrategy { .placeholder(NSNull(), isNull: { $0 is NSNull }) }
}

extension KeyValueEncoder {

    static func makePlistCompatible() -> KeyValueEncoder {
        let encoder = KeyValueEncoder()
        encoder.nilEncodingStrategy = .stringNull
        return encoder
    }

    enum EncodedValue {
        case null
        case value(Any)
        case provider(() throws -> EncodedValue)

        func getValue(strategy: NilEncodingStrategy) throws -> Any? {
            switch self {
            case .null:
                return strategy.value
            case let .value(val):
                return val
            case let .provider(closure):
                return try closure().getValue(strategy: strategy)
            }
        }
    }

    func encodeValue<T: Encodable>(_ value: T) throws -> EncodedValue{
        try Encoder(userInfo: userInfo, nilEncodingStrategy: nilEncodingStrategy).encodeToValue(value)
    }
}

extension KeyValueEncoder.NilEncodingStrategy {

    public func isNull(_ value: Any?) -> Bool {
        guard let value else { return true }
        return isNull(value)
    }

    public func isNull(_ value: Any) -> Bool {
        switch self {
        case .removed:
            return Self.isOptionalNone(value)
        case .placeholder(_, isNull: let closure):
            return closure(value)
        }
    }

    static func isOptionalNone(_ value: Any) -> Bool {
        if Mirror(reflecting: value).displayStyle == .optional,
           case Optional<Any>.none = value {
            return true
        } else {
            return false
        }
    }
}

private extension KeyValueEncoder.NilEncodingStrategy {

    var value: Any? {
        switch self {
        case .removed: return nil
        case .placeholder(let value, _): return value
        }
    }
}

private extension KeyValueEncoder {

    final class Encoder: Swift.Encoder {

        let codingPath: [any CodingKey]
        let userInfo: [CodingUserInfoKey: Any]
        let nilEncodingStrategy: NilEncodingStrategy

        init(codingPath: [any CodingKey] = [], userInfo: [CodingUserInfoKey: Any], nilEncodingStrategy: NilEncodingStrategy) {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.nilEncodingStrategy = nilEncodingStrategy
        }

        private(set) var container: EncodedValue? {
            didSet {
                precondition(oldValue == nil)
            }
        }

        func getEncodedValue() throws -> EncodedValue {
            guard let container else {
                return .value([String: Any]())
            }
            return container
        }

        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
            let keyed = KeyedContainer<Key>(codingPath: codingPath, userInfo: userInfo, nilEncodingStrategy: nilEncodingStrategy)
            container = .provider(keyed.getEncodedValue)
            return KeyedEncodingContainer(keyed)
        }

        func unkeyedContainer() -> any UnkeyedEncodingContainer {
            let unkeyed = UnkeyedContainer(codingPath: codingPath, userInfo: userInfo, nilEncodingStrategy: nilEncodingStrategy)
            container = .provider(unkeyed.getEncodedValue)
            return unkeyed
        }

        func singleValueContainer() -> any SingleValueEncodingContainer {
            let single = SingleContainer(codingPath: codingPath, userInfo: userInfo, nilEncodingStrategy: nilEncodingStrategy)
            container = .provider(single.getEncodedValue)
            return single
        }

        func encodeToValue<T>(_ value: T) throws -> EncodedValue where T: Encodable {
            guard let encoded = EncodedValue(value) else {
                try value.encode(to: self)
                return try getEncodedValue()
            }
            return encoded
        }
    }
}

private extension KeyValueEncoder {

    final class KeyedContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
        typealias Key = K

        let codingPath: [any CodingKey]
        private let userInfo: [CodingUserInfoKey: Any]
        private let nilEncodingStrategy: NilEncodingStrategy

        init(codingPath: [any CodingKey], userInfo: [CodingUserInfoKey: Any], nilEncodingStrategy: NilEncodingStrategy) {
            self.codingPath = codingPath
            self.storage = [:]
            self.userInfo = userInfo
            self.nilEncodingStrategy = nilEncodingStrategy
        }

        private var storage: [String: EncodedValue]

        func setValue(_ value: Any, forKey key: Key) {
            storage[key.stringValue] = .value(value)
        }

        func setValue(_ value: EncodedValue, forKey key: Key) {
            storage[key.stringValue] = value
        }

        func getEncodedValue() throws -> EncodedValue {
            try .value(storage.compactMapValues { try $0.getValue(strategy: nilEncodingStrategy) })
        }

        func encodeNil(forKey key: Key) {
            storage[key.stringValue] = .null
        }

        func encode(_ value: Bool, forKey key: Key) {
            setValue(value, forKey: key)
        }

        func encode(_ value: Int, forKey key: Key) {
            setValue(value, forKey: key)
        }

        func encode(_ value: Int8, forKey key: Key) {
            setValue(value, forKey: key)
        }

        func encode(_ value: Int16, forKey key: Key) {
            setValue(value, forKey: key)
        }

        func encode(_ value: Int32, forKey key: Key) {
            setValue(value, forKey: key)
        }

        func encode(_ value: Int64, forKey key: Key) {
            setValue(value, forKey: key)
        }

        func encode(_ value: UInt, forKey key: Key) {
            setValue(value, forKey: key)
        }

        func encode(_ value: UInt8, forKey key: Key) {
            setValue(value, forKey: key)
        }

        func encode(_ value: UInt16, forKey key: Key) {
            setValue(value, forKey: key)
        }

        func encode(_ value: UInt32, forKey key: Key) {
            setValue(value, forKey: key)
        }

        func encode(_ value: UInt64, forKey key: Key) {
            setValue(value, forKey: key)
        }

        func encode(_ value: String, forKey key: Key) {
            setValue(value, forKey: key)
        }

        func encode(_ value: Float, forKey key: Key) {
            setValue(value, forKey: key)
        }

        func encode(_ value: Double, forKey key: Key) {
            setValue(value, forKey: key)
        }

        func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
            if let val = EncodedValue(value) {
                setValue(val, forKey: key)
                return
            }

            let encoder = Encoder(codingPath: codingPath.appending(key: key), userInfo: userInfo, nilEncodingStrategy: nilEncodingStrategy)
            if let value = try encoder.encodeToValue(value).getValue(strategy: nilEncodingStrategy) {
                setValue(value, forKey: key)
            } else {
                setValue(.null, forKey: key)
            }
        }

        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
            let path = codingPath.appending(key: key)
            let keyed = KeyedContainer<NestedKey>(codingPath: path, userInfo: userInfo, nilEncodingStrategy: nilEncodingStrategy)
            storage[key.stringValue] = .provider(keyed.getEncodedValue)
            return KeyedEncodingContainer(keyed)
        }

        func nestedUnkeyedContainer(forKey key: K) -> any UnkeyedEncodingContainer {
            let path = codingPath.appending(key: key)
            let unkeyed = UnkeyedContainer(codingPath: path, userInfo: userInfo, nilEncodingStrategy: nilEncodingStrategy)
            storage[key.stringValue] = .provider(unkeyed.getEncodedValue)
            return unkeyed
        }

        func superEncoder() -> any Swift.Encoder {
            return superEncoder(forKey: Key(stringValue: "super")!)
        }

        func superEncoder(forKey key: Key) -> any Swift.Encoder {
            let path = codingPath.appending(key: key)
            let encoder = Encoder(codingPath: path, userInfo: userInfo, nilEncodingStrategy: nilEncodingStrategy)
            storage[key.stringValue] = .provider(encoder.getEncodedValue)
            return encoder
        }
    }

    final class UnkeyedContainer: Swift.UnkeyedEncodingContainer {

        let codingPath: [any CodingKey]
        private let userInfo: [CodingUserInfoKey: Any]
        private let nilEncodingStrategy: NilEncodingStrategy

        init(codingPath: [any CodingKey], userInfo: [CodingUserInfoKey: Any], nilEncodingStrategy: NilEncodingStrategy) {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.nilEncodingStrategy = nilEncodingStrategy
        }

        private var storage: [EncodedValue] = []

        func getEncodedValue() throws -> EncodedValue {
            return try .value(storage.compactMap { try $0.getValue(strategy: nilEncodingStrategy) })
        }

        public var count: Int {
            return storage.count
        }

        func appendValue(_ value: Any) {
            storage.append(.value(value))
        }

        func appendValue(_ value: EncodedValue) {
            storage.append(value)
        }

        func encodeNil() {
            storage.append(.null)
        }

        func encode(_ value: Bool) {
            appendValue(value)
        }

        func encode(_ value: Int) {
            appendValue(value)
        }

        func encode(_ value: Int8) {
            appendValue(value)
        }

        func encode(_ value: Int16) {
            appendValue(value)
        }

        func encode(_ value: Int32) {
            appendValue(value)
        }

        func encode(_ value: Int64) {
            appendValue(value)
        }

        func encode(_ value: UInt) {
            appendValue(value)
        }

        func encode(_ value: UInt8) {
            appendValue(value)
        }

        func encode(_ value: UInt16) {
            appendValue(value)
        }

        func encode(_ value: UInt32) {
            appendValue(value)
        }

        func encode(_ value: UInt64) {
            appendValue(value)
        }

        func encode(_ value: String) {
            appendValue(value)
        }

        func encode(_ value: Float) {
            appendValue(value)
        }

        func encode(_ value: Double) {
            appendValue(value)
        }

        func encode<T: Encodable>(_ value: T) throws {
            if let val = EncodedValue(value) {
                appendValue(val)
                return
            }

            let encoder = Encoder(codingPath: codingPath.appending(index: count), userInfo: userInfo, nilEncodingStrategy: nilEncodingStrategy)
            if let value = try encoder.encodeToValue(value).getValue(strategy: nilEncodingStrategy) {
                appendValue(value)
            } else {
                appendValue(.null)
            }
        }

        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
            let path = codingPath.appending(index: count)
            let keyed = KeyedContainer<NestedKey>(codingPath: path, userInfo: userInfo, nilEncodingStrategy: nilEncodingStrategy)
            storage.append(.provider(keyed.getEncodedValue))
            return KeyedEncodingContainer(keyed)
        }

        func nestedUnkeyedContainer() -> any UnkeyedEncodingContainer {
            let path = codingPath.appending(index: count)
            let unkeyed = UnkeyedContainer(codingPath: path, userInfo: userInfo, nilEncodingStrategy: nilEncodingStrategy)
            storage.append(.provider(unkeyed.getEncodedValue))
            return unkeyed
        }

        func superEncoder() -> any Swift.Encoder {
            let path = codingPath.appending(index: count)
            let encoder = Encoder(codingPath: path, userInfo: userInfo, nilEncodingStrategy: nilEncodingStrategy)
            storage.append(.provider(encoder.getEncodedValue))
            return encoder
        }
    }

    final class SingleContainer: SingleValueEncodingContainer {

        let codingPath: [any CodingKey]
        private let userInfo: [CodingUserInfoKey: Any]
        private let nilEncodingStrategy: NilEncodingStrategy

        init(codingPath: [any CodingKey], userInfo: [CodingUserInfoKey: Any], nilEncodingStrategy: NilEncodingStrategy) {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.nilEncodingStrategy = nilEncodingStrategy
        }

        private var value: EncodedValue?

        func getEncodedValue() throws -> EncodedValue {
            guard let value else { return .value([String: Any]()) }
            return value
        }

        func encodeNil() {
            self.value = .null
        }

        func encode(_ value: Bool) {
            self.value = .value(value)
        }

        func encode(_ value: String) {
            self.value = .value(value)
        }

        func encode(_ value: Double) {
            self.value = .value(value)
        }

        func encode(_ value: Float) {
            self.value = .value(value)
        }

        func encode(_ value: Int) {
            self.value = .value(value)
        }

        func encode(_ value: Int8) {
            self.value = .value(value)
        }

        func encode(_ value: Int16) {
            self.value = .value(value)
        }

        func encode(_ value: Int32) {
            self.value = .value(value)
        }

        func encode(_ value: Int64) {
            self.value = .value(value)
        }

        func encode(_ value: UInt) {
            self.value = .value(value)
        }

        func encode(_ value: UInt8) {
            self.value = .value(value)
        }

        func encode(_ value: UInt16) {
            self.value = .value(value)
        }

        func encode(_ value: UInt32) {
            self.value = .value(value)
        }

        func encode(_ value: UInt64) {
            self.value = .value(value)
        }

        func encode<T>(_ value: T) throws where T: Encodable {
            if let encoded = EncodedValue(value) {
                self.value = encoded
                return
            }

            let encoder = Encoder(codingPath: codingPath, userInfo: userInfo, nilEncodingStrategy: nilEncodingStrategy)
            if let value = try encoder.encodeToValue(value).getValue(strategy: nilEncodingStrategy) {
                self.value = .value(value)
            } else {
                self.value = .null
            }
        }
    }
}

extension Array where Element == any CodingKey {

    func appending(key codingKey: any CodingKey) -> [any CodingKey] {
        var path = self
        path.append(codingKey)
        return path
    }

    func appending(index: Int) -> [any CodingKey] {
        var path = self
        path.append(AnyCodingKey(intValue: index))
        return path
    }

    func makeKeyPath(appending key: (any CodingKey)? = nil) -> String {
        var path = map(\.keyPath)
        if let key = key {
            path.append(key.keyPath)
        }
        return "SELF\(path.joined())"
    }
}

private extension CodingKey {
    var keyPath: String {
        if let intValue = self.intValue {
            return "[\(intValue)]"
        } else {
            return ".\(stringValue)"
        }
    }
}

struct AnyCodingKey: CodingKey {
    var intValue: Int? {
        return index
    }

    var stringValue: String
    var index: Int?

    init(intValue index: Int) {
        self.index = index
        self.stringValue = "Index \(index)"
    }

    init(stringValue: String) {
        self.stringValue = stringValue
    }
}

extension KeyValueEncoder.EncodedValue {

    static func isSupportedValue(_ value: Any) -> Bool {
        switch value {
        case is Data: return true
        case is Date: return true
        case is URL: return true
        case is Decimal: return true
        default: return false
        }
    }

    init?(_ value: Any) {
        guard Self.isSupportedValue(value) else {
            return nil
        }
        self = .value(value)
    }
}
