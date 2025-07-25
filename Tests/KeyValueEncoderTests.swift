//
//  KeyValueEncoderTests.swift
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

#if canImport(Testing)
@testable import KeyValueCoder

import Foundation
import Testing

struct KeyValueEncodedTests {

    typealias EncodedValue = KeyValueEncoder.EncodedValue

    @Test
    func singleContainer_Encodes_Bool() throws {
        #expect(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(true)
            } == .value(true)
        )

        #expect(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(false)
            } == .value(false)
        )
    }

    @Test
    func singleContainer_Encodes_Duration() throws {
        guard #available(iOS 16.0, tvOS 16.0, watchOS 9.0, *) else { return }
        #expect(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(Duration.nanoseconds(1))
            } == .value([0, 1000000000])
        )
    }

    @Test
    func singleContainer_Encodes_String() throws {
        #expect(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode("fish")
            } == .value("fish")
        )
    }

    @Test
    func singleContainer_Encodes_RawRepresentable() throws {
        #expect(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(Seafood.fish)
            } == .value("fish")
        )
    }

    @Test
    func singleContainer_Encodes_URL() throws {
        #expect(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(URL(string: "fish.com")!)
            } == .value(URL(string: "fish.com")!)
        )
    }

    @Test
    func singleContainer_Encodes_Optionals() throws {
        #expect(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encodeNil()
            } == .null
        )
        #expect(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(String?.none)
            } == .null
        )
        #expect(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(Null())
            } == .null
        )
        #expect(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(Empty())
            } == .value(NSDictionary())
        )
        #expect(
            try KeyValueEncoder.encodeSingleValue(nilEncodingStrategy: .removed) {
                try $0.encode(Null())
            } == .null
        )
    }

    @Test
    func singleContainer_Encodes_RealNumbers() throws {
        #expect(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(Float(10))
            } == .value(Float(10))
        )
        #expect(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(Double(20))
            } == .value(Double(20))
        )
    }

    @Test
    func singleContainer_Encodes_Ints() throws {
        #expect(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(Int(10))
            } == .value(Int(10))
        )
        #expect(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(Int8(20))
            } == .value(20)
        )
        #expect(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(Int16.max)
            } == .value(Int16.max)
        )
        #expect(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(Int32.max)
            } == .value(Int32.max)
        )
        #expect(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(Int64.max)
            } == .value(Int64.max)
        )
    }

    @Test
    func singleContainer_Encodes_UInts() throws {
        #expect(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(UInt(10))
            } == .value(10)
        )
        #expect(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(UInt8(20))
            } == .value(20)
        )
        #expect(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(UInt16.max)
            } == .value(UInt16.max)
        )
        #expect(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(UInt32.max)
            } == .value(UInt32.max)
        )
        #expect(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(UInt64.max)
            } == .value(UInt64.max)
        )
    }

    @Test
    func singleContainer_ReturnsEmptyObject_WhenEmpty() throws {
        #expect(
            try KeyValueEncoder.encodeSingleValue { _ in }.getValue() as? NSDictionary == [:]
        )
    }

    @Test
    func encodes() throws {
        let node = Node(id: 1,
                        name: "root",
                        descendents: [Node(id: 2), Node(id: 3)],
                        related: ["left": Node(id: 4, descendents: [Node(id: 5)]),
                                  "right": Node(id: 6)]
        )

        #expect(
            try KeyValueEncoder().encode(node) as? NSDictionary == [
                "id": 1,
                "name": "root",
                "desc": [["id": 2], ["id": 3]],
                "rel": ["left": ["id": 4, "desc": [["id": 5]] as Any],
                        "right": ["id": 6]]
            ]
        )
    }

    @Test
    func keyedContainer_Encodes_Optionals() throws {
        #expect(
            try KeyValueEncoder.encodeKeyedValue(keyedBy: AnyCodingKey.self) {
                try $0.encode(String?.none, forKey: "first")
                try $0.encode(String?.some("fish"), forKey: "second")
                try $0.encodeNil(forKey: "third")
                try $0.encode(Empty(), forKey: "fourth")
            }.getValue() as? NSDictionary == [
                "first": Optional<Any>.none as Any,
                "second": "fish",
                "third": Optional<Any>.none as Any,
                "fourth": NSDictionary()
            ]
        )
    }

    @Test
    func keyedContainer_Encodes_Bool() throws {
        let real = AllTypes(
            tBool: true,
            tArray: [AllTypes(tBool: false)]
        )

        #expect(
            try KeyValueEncoder().encode(real) as? NSDictionary == [
                "tBool": true,
                "tArray": [["tBool": false]]
            ]
        )
    }

    @Test
    func keyedContainer_Encodes_RealNumbers() throws {
        let real = AllTypes(
            tDouble: 20,
            tFloat: -10
        )

        #expect(
            try KeyValueEncoder().encode(real) as? NSDictionary == [
                "tDouble": 20,
                "tFloat": -10
            ]
        )
    }

    @Test
    func keyedContainer_Encodes_URL() throws {
        let urls = AllTypes(
            tURL: URL(string: "fish.com")
        )

        #expect(
            try KeyValueEncoder().encode(urls) as? NSDictionary == [
                "tURL": URL(string: "fish.com")!
            ]
        )
    }

    @Test
    func keyedContainer_Encodes_Ints() throws {
        let ints = AllTypes(
            tInt: 10,
            tInt8: -20,
            tInt16: 30,
            tInt32: -40,
            tInt64: .max,
            tArray: [AllTypes(tInt: -1), AllTypes(tInt: -2)],
            tDictionary: ["rel": AllTypes(tInt: -3)]
        )

        #expect(
            try KeyValueEncoder().encode(ints) as? NSDictionary == [
                "tInt": 10,
                "tInt8": -20,
                "tInt16": 30,
                "tInt32": -40,
                "tInt64": Int64.max,
                "tArray": [["tInt": -1], ["tInt": -2]],
                "tDictionary": ["rel": ["tInt": -3]]
            ]
        )
    }

    @Test
    func keyedContainer_Encodes_UInts() throws {
        let uints = AllTypes(
            tUInt: 10,
            tUInt8: 20,
            tUInt16: 30,
            tUInt32: 40,
            tUInt64: .max,
            tArray: [AllTypes(tUInt: 50), AllTypes(tUInt: 60)],
            tDictionary: ["rel": AllTypes(tUInt: 70)]
        )

        #expect(
            try KeyValueEncoder().encode(uints) as? NSDictionary == [
                "tUInt": 10,
                "tUInt8": 20,
                "tUInt16": 30,
                "tUInt32": 40,
                "tUInt64": UInt64.max,
                "tArray": [["tUInt": 50], ["tUInt": 60]],
                "tDictionary": ["rel": ["tUInt": 70]]
            ]
        )
    }

    @Test
    func keyedContainer_Encodes_NestedKeyedContainer() throws {
        #expect(
            try KeyValueEncoder.encodeKeyedValue(keyedBy: AnyCodingKey.self) {
                var nested = $0.nestedContainer(keyedBy: AnyCodingKey.self, forKey: "fish")
                try nested.encode(true, forKey: "chips")
            }.getValue() as? NSDictionary == [
                "fish": ["chips": true]
            ]
        )
    }

    @Test
    func keyedContainer_Encodes_NestedUnkeyedContainer() throws {
        #expect(
            try KeyValueEncoder.encodeKeyedValue(keyedBy: AnyCodingKey.self) {
                var nested = $0.nestedUnkeyedContainer(forKey: "fish")
                try nested.encode(true)
                try nested.encode(false)
            }.getValue() as? NSDictionary == [
                "fish": [true, false]
            ]
        )
    }

    @Test
    func keyedContainer_Encodes_SuperContainer() throws {
        #expect(
            try KeyValueEncoder.encodeKeyedValue(keyedBy: AnyCodingKey.self) {
                try Int(10).encode(to: $0.superEncoder())
            }.getValue() as? NSDictionary == [
                "super": 10
            ]
        )
    }

    @Test
    func keyedContainer_Encodes_SnakeCase() throws {
        let shrimp = SnakeNode(firstName: "shrimp", lastName: "anemone")
        let node = SnakeNode(firstName: "fish", lastName: "chips", profileURL: "drop", relNODESLink: ["ocean": shrimp])

        var encoder = KeyValueEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        #expect(
            try encoder.encode(node) as? NSDictionary == [
                "first_name": "fish",
                "surname": "chips",
                "profile_url": "drop",
                "rel_nodes_link": ["ocean": ["first_name": "shrimp", "surname": "anemone"]]
            ]
        )
    }

    @Test
    func unkeyedContainer_Encodes_Optionals() throws {
        #expect(
            try KeyValueEncoder.encodeUnkeyedValue {
                try $0.encode(String?.none)
                try $0.encode(String?.some("fish"))
                try $0.encodeNil()
                try $0.encode("chips")
                try $0.encode(Empty())
            }.getValue() as? NSArray == [
                Optional<Any>.none as Any,
                "fish",
                Optional<Any>.none as Any,
                "chips",
                NSDictionary()
            ]
        )
    }

    @Test
    func unkeyedContainer_Encodes_Bool() throws {
        #expect(
            try KeyValueEncoder.encodeUnkeyedValue {
                try $0.encode(true)
                try $0.encode(false)
            }.getValue() as? NSArray == [
                true, false
            ]
        )
    }

    @Test
    func unkeyedContainer_Encodes_RealNumbers() throws {
        #expect(
            try KeyValueEncoder.encodeUnkeyedValue {
                try $0.encode(Float(10))
                try $0.encode(Double(20))
            }.getValue() as? NSArray == [
                10, 20
            ]
        )
    }

    @Test
    func unkeyedContainer_Encodes_Ints() throws {
        #expect(
            try KeyValueEncoder.encodeUnkeyedValue {
                try $0.encode(Int(10))
                try $0.encode(Int8(-20))
                try $0.encode(Int16(30))
                try $0.encode(Int32(-40))
                try $0.encode(Int64.max)
            }.getValue() as? NSArray == [
                Int(10),
                Int8(-20),
                Int16(30),
                Int32(-40),
                Int64.max
            ]
        )
    }

    @Test
    func unkeyedContainer_Encodes_RawRepresentable() throws {
        #expect(
            try KeyValueEncoder.encodeUnkeyedValue {
                try $0.encode(Seafood.fish)
                try $0.encode(Seafood.chips)
            }.getValue() as? NSArray == [
                "fish",
                "chips"
            ]
        )
    }

    @Test
    func unkeyedContainer_Encodes_URL() throws {
        #expect(
            try KeyValueEncoder.encodeUnkeyedValue {
                try $0.encode(URL(string: "fish.com")!)
            }.getValue() as? NSArray == [
                URL(string: "fish.com")!
            ]
        )
    }

    @Test
    func unkeyedContainer_Encodes_UInts() throws {
        #expect(
            try KeyValueEncoder.encodeUnkeyedValue {
                try $0.encode(UInt(10))
                try $0.encode(UInt8(20))
                try $0.encode(UInt16(30))
                try $0.encode(UInt32(40))
                try $0.encode(UInt64.max)
            }.getValue() as? NSArray == [
                UInt(10),
                UInt8(20),
                UInt16(30),
                UInt32(40),
                UInt64.max
            ]
        )
    }

    @Test
    func unkeyedContainer_Encodes_NestedKeyedContainer() throws {
        #expect(
            try KeyValueEncoder.encodeUnkeyedValue {
                try $0.encode(10)
                var container = $0.nestedContainer(keyedBy: AnyCodingKey.self)
                try container.encode(20, forKey: "fish")
            }.getValue() as? NSArray == [
                10, ["fish": 20]
            ]
        )
    }

    @Test
    func unkeyedContainer_Encodes_NestedUnkeyedContainer() throws {
        #expect(
            try KeyValueEncoder.encodeUnkeyedValue {
                try $0.encode(10)
                var container = $0.nestedUnkeyedContainer()
                try container.encode(20)
                try container.encode(30)
            }.getValue() as? NSArray == [
                10, [20, 30]
            ]
        )
    }

    @Test
    func unkeyedContainer_Encodes_SuperContainer() throws {
        #expect(
            try KeyValueEncoder.encodeUnkeyedValue {
                try $0.encode(10)
                try Int(20).encode(to: $0.superEncoder())
            }.getValue() as? NSArray == [
                10, 20
            ]
        )
    }

    @Test
    func supportedCodableTypes() {
        #expect(
            EncodedValue.isSupportedValue(URL(string: "fish.com")!)
        )
        #expect(
            EncodedValue.isSupportedValue(Date())
        )
        #expect(
            EncodedValue.isSupportedValue(Data())
        )
        #expect(
            EncodedValue.isSupportedValue(Decimal())
        )
    }

    @Test
    func anyCodingKey() {
        #expect(
            AnyCodingKey(intValue: 9).intValue == 9
        )
        #expect(
            AnyCodingKey(intValue: 9).stringValue == "Index 9"
        )
        #expect(
            AnyCodingKey(stringValue: "fish").stringValue == "fish"
        )
    }

    @Test
    func nilEncodingStrategy_SingleContainer() throws {
        var encoder = KeyValueEncoder()

        encoder.nilEncodingStrategy = .removed
        #expect(
            try encoder.encode(Int?.none) == nil
        )

        encoder.nilEncodingStrategy = .default
        #expect(
            try encoder.encode(Int?.none) != nil
        )
        #expect(
            try encoder.encode(Int?.none) as? Int? == .none
        )

        encoder.nilEncodingStrategy = .stringNull
        #expect(
            try encoder.encode(Int?.none) as? String == "$null"
        )

        encoder.nilEncodingStrategy = .nsNull
        #expect(
            try encoder.encode(Int?.none) is NSNull
        )
    }

    @Test
    func nilEncodingStrategy_UnkeyedContainer() throws {
        var encoder = KeyValueEncoder()

        encoder.nilEncodingStrategy = .removed
        #expect(
            try encoder.encode([1, 2, Int?.none, 4]) as? [Int] == [
                1, 2, 4
            ]
        )

        encoder.nilEncodingStrategy = .default
        #expect(
            try encoder.encode([1, 2, Int?.none, 4]) as? [Int?] == [
                1, 2, nil, 4
            ]
        )

        encoder.nilEncodingStrategy = .stringNull
        #expect(
            try encoder.encode([1, Int?.none, 3, 4]) as? NSArray == [
                1, "$null", 3, 4
            ]
        )

        encoder.nilEncodingStrategy = .nsNull
        #expect(
            try encoder.encode([1, 2, 3, Int?.none]) as? NSArray == [
                1, 2, 3, NSNull()
            ]
        )
    }

    @Test
    func nilEncodingStrategy_KeyedContainer() throws {
        #expect(
            try KeyValueEncoder.encodeKeyedValue(keyedBy: AnyCodingKey.self, nilEncodingStrategy: .removed) {
                try $0.encodeNil(forKey: "fish")
                try $0.encode(Null(), forKey: "chips")
            }.getValue() as? NSDictionary == [:]
        )
        #expect(
            try KeyValueEncoder.encodeKeyedValue(keyedBy: AnyCodingKey.self, nilEncodingStrategy: .default) {
                try $0.encodeNil(forKey: "fish")
                try $0.encode(Null(), forKey: "chips")
            }.getValue() as? NSDictionary == [
                "fish": String?.none as Any,
                "chips": String?.none as Any
            ]
        )
        #expect(
            try KeyValueEncoder.encodeKeyedValue(keyedBy: AnyCodingKey.self, nilEncodingStrategy: .stringNull) {
                try $0.encodeNil(forKey: "fish")
                try $0.encode(Null(), forKey: "chips")
            }.getValue() as? NSDictionary == [
                "fish": "$null",
                "chips": "$null"
            ]
        )
        #expect(
            try KeyValueEncoder.encodeKeyedValue(keyedBy: AnyCodingKey.self, nilEncodingStrategy: .nsNull) {
                try $0.encodeNil(forKey: "fish")
                try $0.encode(Null(), forKey: "chips")
            }.getValue() as? NSDictionary == [
                "fish": NSNull(),
                "chips": NSNull()
            ]
        )
    }

#if !os(WASI)
    @Test
    func plistCompatibleEncoder() throws {
        let keyValueAny = try KeyValueEncoder.makePlistCompatible().encode([1, 2, Int?.none, 4])
        #expect(
            try PropertyListDecoder.decodeAny([Int?].self, from: keyValueAny) == [
                1, 2, Int?.none, 4
            ]
        )
    }
#endif

    @Test
    func encoder_Encodes_Dates() throws {
        var encoder = KeyValueEncoder()
        let referenceDate = Date(timeIntervalSinceReferenceDate: 0)

        encoder.dateEncodingStrategy = .date
        #expect(
            try encoder.encode(referenceDate) as? Date == referenceDate
        )

        encoder.dateEncodingStrategy = .iso8601()
        #expect(
            try encoder.encode(referenceDate) as? String == "2001-01-01T00:00:00Z"
        )

        encoder.dateEncodingStrategy = .iso8601(options: [.withInternetDateTime, .withFractionalSeconds])
        #expect(
            try encoder.encode(referenceDate) as? String == "2001-01-01T00:00:00.000Z"
        )

        encoder.dateEncodingStrategy = .millisecondsSince1970
        #expect(
            try encoder.encode(referenceDate) as? Int == 978307200000
        )

        encoder.dateEncodingStrategy = .secondsSince1970
        #expect(
            try encoder.encode(referenceDate) as? Int == 978307200
        )
    }

    @Test
    func jsonCompatibleEncoder() throws {
        let keyValueAny = try KeyValueEncoder.makeJSONCompatible().encode([1, 2, Int?.none, 4])
        #expect(
            try JSONDecoder.decodeAny([Int?].self, from: keyValueAny) == [
                1, 2, Int?.none, 4
            ]
        )
    }

    @Test
    func aa() {
        #expect(KeyValueEncoder.NilEncodingStrategy.isOptionalNone(Int?.none as Any))
        #expect(KeyValueEncoder.NilEncodingStrategy.isOptionalNone(Int??.none as Any))
    }
}

private extension KeyValueEncoder {

    static func encodeSingleValue(nilEncodingStrategy: NilEncodingStrategy = .default,
                                  with closure: (inout any SingleValueEncodingContainer) throws -> Void) throws -> EncodedValue {
        var encoder = KeyValueEncoder()
        encoder.nilEncodingStrategy = nilEncodingStrategy
        return try encoder.encodeValue {
            var container = $0.singleValueContainer()
            try closure(&container)
        }
    }

    static func encodeUnkeyedValue(with closure: (inout any UnkeyedEncodingContainer) throws -> Void) throws -> EncodedValue {
        try KeyValueEncoder().encodeValue {
            var container = $0.unkeyedContainer()
            try closure(&container)
        }
    }

    static func encodeKeyedValue<K: CodingKey>(
        keyedBy: K.Type = K.self,
        nilEncodingStrategy: NilEncodingStrategy = .default,
        with closure: @escaping (inout KeyedEncodingContainer<K>) throws -> Void
    ) throws -> EncodedValue {
        var encoder = KeyValueEncoder()
        encoder.nilEncodingStrategy = nilEncodingStrategy
        return try encoder.encodeValue {
            var container = $0.container(keyedBy: K.self)
            try closure(&container)
        }
    }

    func encodeValue(with closure: (any Encoder) throws -> Void) throws -> EncodedValue {
        try withoutActuallyEscaping(closure) {
            try self.encodeValue(StubEncoder(closure: $0))
        }
    }

    static func makeJSONCompatible() -> KeyValueEncoder {
        var encoder = KeyValueEncoder()
        encoder.nilEncodingStrategy = .nsNull
        return encoder
    }
}

private struct StubEncoder: Encodable {
    var closure: (any Encoder) throws -> Void

    func encode(to encoder: any Encoder) throws {
        try closure(encoder)
    }
}

extension AnyCodingKey: Swift.ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(stringValue: value)
    }
}

struct Node: Codable, Equatable {
    var id: Int
    var name: String?
    var descendents: [Node]?
    var related: [String: Node]?

    enum CodingKeys: String, CodingKey {
        case id, name, descendents = "desc", related = "rel"
    }

    enum RelatedKeys: String, CodingKey {
        case left, right
    }
}

struct SnakeNode: Codable, Equatable {
    var firstName: String
    var lastName: String
    var profileURL: String?
    var relNODESLink: [String: SnakeNode]?

    enum CodingKeys: String, CodingKey {
        case firstName, profileURL, relNODESLink
        case lastName = "surname"
    }
}

extension KeyValueEncoder.EncodedValue: Swift.Equatable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        do {
            let lhsValue = try lhs.getValue()
            let rhsValue = try rhs.getValue()
            return (lhsValue as? NSObject) == (rhsValue as? NSObject)
        } catch {
            return false
        }
    }
}

extension KeyValueEncoder.EncodedValue {

    func getValue() throws -> Any {
        try getValue(strategy: .default) as Any
    }

    func getEncodedValue() throws -> Self {
        switch self {
        case let .provider(closure):
            return try closure()
        case .null, .value:
            return self
        }
    }
}

private extension KeyValueEncoder.EncodedValue {
    static func isSupportedValue(_ value: Any) -> Bool {
        Self.makeValue(for: value, using: .default) != nil
    }
}

private extension KeyValueEncoder.EncodingStrategy {
    static let `default` = Self(
        optionals: .default,
        keys: .useDefaultKeys,
        dates: .date
    )
}

#if !os(WASI)
private extension PropertyListDecoder {
    static func decodeAny<T: Decodable>(_ type: T.Type, from value: Any?) throws -> T {
        let data = try PropertyListSerialization.data(fromPropertyList: value as Any, format: .xml, options: 0)
        return try PropertyListDecoder().decode(type, from: data)
    }
}
#endif

private extension JSONDecoder {
    static func decodeAny<T: Decodable>(_ type: T.Type, from value: Any?) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: value as Any)
        return try JSONDecoder().decode(type, from: data)
    }
}

private struct Empty: Encodable {
    func encode(to encoder: any Encoder) throws { }
}

private struct Null: Encodable {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}
#endif
