//
//  KeyValueEncoder.swift
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

public final class KeyValueEncoder {

    public var userInfo: [CodingUserInfoKey: Any]

    public init () {
        self.userInfo = [:]
    }

    public func encode<T>(_ value: T) throws -> Any where T: Encodable {
        try encodeValue(value).getValue()
    }

    func encodeValue<T>(_ value: T) throws -> EncodedValue where T: Encodable {
        try Encoder(userInfo: userInfo).encodeToValue(value)
    }
}

extension KeyValueEncoder {

    enum EncodedValue {
        case null
        case value(Any)
        case provider(() throws -> EncodedValue)

        func getValue() throws -> Any {
            switch self {
            case .null:
                return Optional<Any>.none as Any
            case let .value(val):
                return val
            case let .provider(closure):
                return try closure().getValue()
            }
        }
    }
}

private extension KeyValueEncoder {

    final class Encoder: Swift.Encoder {

        let codingPath: [CodingKey]
        let userInfo: [CodingUserInfoKey: Any]

        init(codingPath: [CodingKey] = [], userInfo: [CodingUserInfoKey: Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
        }

        private(set) var container: EncodedValue? {
            didSet {
                precondition(oldValue == nil)
            }
        }

        func getEncodedValue() throws -> EncodedValue {
            guard let container else {
                let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Expected value at \(codingPath.makeKeyPath()) found nil")
                throw DecodingError.valueNotFound(Any.self, context)
            }
            return container
        }

        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
            let keyed = KeyedContainer<Key>(codingPath: codingPath, userInfo: userInfo)
            container = .provider(keyed.getEncodedValue)
            return KeyedEncodingContainer(keyed)
        }

        func unkeyedContainer() -> UnkeyedEncodingContainer {
            let unkeyed = UnkeyedContainer(codingPath: codingPath, userInfo: userInfo)
            container = .provider(unkeyed.getEncodedValue)
            return unkeyed
        }

        func singleValueContainer() -> SingleValueEncodingContainer {
            let single = SingleContainer(codingPath: codingPath, userInfo: userInfo)
            container = .provider(single.getEncodedValue)
            return single
        }

        func encodeToValue<T>(_ value: T) throws -> EncodedValue where T: Encodable {
            try value.encode(to: self)
            return try getEncodedValue()
        }
    }
}

private extension KeyValueEncoder {

    final class KeyedContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
        typealias Key = K

        let codingPath: [CodingKey]
        private let userInfo: [CodingUserInfoKey: Any]

        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
            self.codingPath = codingPath
            self.storage = [:]
            self.userInfo = userInfo
        }

        private var storage: [String: EncodedValue]

        func setValue(_ value: Any, forKey key: Key) {
            storage[key.stringValue] = .value(value)
        }

        func setValue(_ value: EncodedValue, forKey key: Key) {
            storage[key.stringValue] = value
        }

        func getEncodedValue() throws -> EncodedValue {
            try .value(storage.mapValues { try $0.getValue() })
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

            let encoder = Encoder(codingPath: codingPath.appending(key: key), userInfo: userInfo)
            try setValue(encoder.encodeToValue(value).getValue(), forKey: key)
        }

        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
            let path = codingPath.appending(key: key)
            let keyed = KeyedContainer<NestedKey>(codingPath: path, userInfo: userInfo)
            storage[key.stringValue] = .provider(keyed.getEncodedValue)
            return KeyedEncodingContainer(keyed)
        }

        func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
            let path = codingPath.appending(key: key)
            let unkeyed = UnkeyedContainer(codingPath: path, userInfo: userInfo)
            storage[key.stringValue] = .provider(unkeyed.getEncodedValue)
            return unkeyed
        }

        func superEncoder() -> Swift.Encoder {
            return superEncoder(forKey: Key(stringValue: "super")!)
        }

        func superEncoder(forKey key: Key) -> Swift.Encoder {
            let path = codingPath.appending(key: key)
            let encoder = Encoder(codingPath: path, userInfo: userInfo)
            storage[key.stringValue] = .provider(encoder.getEncodedValue)
            return encoder
        }
    }

    final class UnkeyedContainer: Swift.UnkeyedEncodingContainer {

        let codingPath: [CodingKey]
        private let userInfo: [CodingUserInfoKey: Any]

        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
        }

        private var storage: [EncodedValue] = []

        func getEncodedValue() throws -> EncodedValue {
            return try .value(storage.map { try $0.getValue() })
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

            let encoder = Encoder(codingPath: codingPath.appending(index: count), userInfo: userInfo)
            try appendValue(encoder.encodeToValue(value).getValue())
        }

        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
            let path = codingPath.appending(index: count)
            let keyed = KeyedContainer<NestedKey>(codingPath: path, userInfo: userInfo)
            storage.append(.provider(keyed.getEncodedValue))
            return KeyedEncodingContainer(keyed)
        }

        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            let path = codingPath.appending(index: count)
            let unkeyed = UnkeyedContainer(codingPath: path, userInfo: userInfo)
            storage.append(.provider(unkeyed.getEncodedValue))
            return unkeyed
        }

        func superEncoder() -> Swift.Encoder {
            let path = codingPath.appending(index: count)
            let encoder = Encoder(codingPath: path, userInfo: userInfo)
            storage.append(.provider(encoder.getEncodedValue))
            return encoder
        }
    }

    final class SingleContainer: SingleValueEncodingContainer {

        let codingPath: [CodingKey]
        private let userInfo: [CodingUserInfoKey: Any]

        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
        }

        private var value: EncodedValue?

        func getEncodedValue() throws -> EncodedValue {
            guard let value else { return .null }
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

            let encoder = Encoder(codingPath: codingPath, userInfo: userInfo)
            self.value = try .value(encoder.encodeToValue(value).getValue())
        }
    }
}

extension Array where Element == CodingKey {

    func appending(key codingKey: CodingKey) -> [CodingKey] {
        var path = self
        path.append(codingKey)
        return path
    }

    func appending(index: Int) -> [CodingKey] {
        var path = self
        path.append(AnyCodingKey(intValue: index))
        return path
    }

    func makeKeyPath(appending key: CodingKey? = nil) -> String {
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
