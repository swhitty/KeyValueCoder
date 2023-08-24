//
//  KeyValueEncoderTests.swift
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

@testable import KeyValueCoder

import XCTest

final class KeyValueEncodedTests: XCTestCase {

    typealias EncodedValue = KeyValueEncoder.EncodedValue

    func testSingleContainer_Encodes_Bool() throws {
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(true)
            },
            .value(true)
        )

        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(false)
            },
            .value(false)
        )
    }

    func testSingleContainer_Encodes_Duration() throws {
        guard #available(iOS 16.0, macOS 13.0, *) else { return }
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(Duration.nanoseconds(1))
            },
            .value([0, 1000000000])
        )
    }

    func testSingleContainer_Encodes_String() throws {
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode("fish")
            },
            .value("fish")
        )
    }

    func testSingleContainer_Encodes_RawRepresentable() throws {
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(Seafood.fish)
            },
            .value("fish")
        )
    }

    func testSingleContainer_Encodes_URL() throws {
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(URL(string: "fish.com")!)
            },
            EncodedValue(URL(string: "fish.com")!)
        )
    }

    func testSingleContainer_Encodes_Optionals() throws {
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encodeNil()
            },
            .null
        )
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(String?.none)
            },
            .null
        )
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(Null())
            },
            .null
        )
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(Empty())
            },
            .value(NSDictionary())
        )
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue(nilEncodingStrategy: .removed) {
                try $0.encode(Null())
            },
            .null
        )
    }

    func testSingleContainer_Encodes_RealNumbers() throws {
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(Float(10))
            },
            .value(Float(10))
        )
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(Double(20))
            },
            .value(Double(20))
        )
    }

    func testSingleContainer_Encodes_Ints() throws {
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(Int(10))
            },
            .value(Int(10))
        )
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(Int8(20))
            },
            .value(20)
        )
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(Int16.max)
            },
            .value(Int16.max)
        )
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(Int32.max)
            },
            .value(Int32.max)
        )
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(Int64.max)
            },
            .value(Int64.max)
        )
    }

    func testSingleContainer_Encodes_UInts() throws {
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(UInt(10))
            },
            .value(10)
        )
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(UInt8(20))
            },
            .value(20)
        )
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(UInt16.max)
            },
            .value(UInt16.max)
        )
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(UInt32.max)
            },
            .value(UInt32.max)
        )
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue {
                try $0.encode(UInt64.max)
            },
            .value(UInt64.max)
        )
    }

    func testSingleContainer_ReturnsEmptyObject_WhenEmpty() throws {
        XCTAssertEqual(
            try KeyValueEncoder.encodeSingleValue { _ in }.getValue() as? NSDictionary,
            [:]
        )
    }

    func testEncodes() throws {
        let node = Node(id: 1,
             name: "root",
             descendents: [Node(id: 2), Node(id: 3)],
             related: ["left": Node(id: 4, descendents: [Node(id: 5)]),
                       "right": Node(id: 6)]
        )

        XCTAssertEqual(
            try KeyValueEncoder().encode(node) as? NSDictionary,
            [
                "id": 1,
                "name": "root",
                "desc": [["id": 2], ["id": 3]],
                "rel": ["left": ["id": 4, "desc": [["id": 5]] as Any],
                        "right": ["id": 6]],
            ]
        )
    }

    func testKeyedContainer_Encodes_Optionals() throws {
        XCTAssertEqual(
            try KeyValueEncoder.encodeKeyedValue(keyedBy: AnyCodingKey.self) {
                try $0.encode(String?.none, forKey: "first")
                try $0.encode(String?.some("fish"), forKey: "second")
                try $0.encodeNil(forKey: "third")
                try $0.encode(Empty(), forKey: "fourth")
            }.getValue() as? NSDictionary,
            [
                "first": Optional<Any>.none as Any,
                "second": "fish",
                "third": Optional<Any>.none as Any,
                "fourth": NSDictionary(),
            ]
        )
    }

    func testKeyedContainer_Encodes_Bool() {
        let real = AllTypes(
            tBool: true,
            tArray: [AllTypes(tBool: false)]
        )

        XCTAssertEqual(
            try KeyValueEncoder().encode(real) as? NSDictionary,
            [
               "tBool": true,
               "tArray": [["tBool": false]]
           ]
        )
    }

    func testKeyedContainer_Encodes_RealNumbers() {
        let real = AllTypes(
            tDouble: 20,
            tFloat: -10
        )

        XCTAssertEqual(
            try KeyValueEncoder().encode(real) as? NSDictionary,
            [
               "tDouble": 20,
               "tFloat": -10
           ]
        )
    }

    func testKeyedContainer_Encodes_URL() {
        let urls = AllTypes(
            tURL: URL(string: "fish.com")
        )

        XCTAssertEqual(
            try KeyValueEncoder().encode(urls) as? NSDictionary,
            [
               "tURL": URL(string: "fish.com")!
           ]
        )
    }

    func testKeyedContainer_Encodes_Ints() {
        let ints = AllTypes(
            tInt: 10,
            tInt8: -20,
            tInt16: 30,
            tInt32: -40,
            tInt64: .max,
            tArray: [AllTypes(tInt: -1), AllTypes(tInt: -2)],
            tDictionary: ["rel": AllTypes(tInt: -3)]
        )

        XCTAssertEqual(
            try KeyValueEncoder().encode(ints) as? NSDictionary,
            [
               "tInt": 10,
               "tInt8": -20,
               "tInt16": 30,
               "tInt32": -40,
               "tInt64": Int64.max,
               "tArray": [["tInt": -1], ["tInt": -2]],
               "tDictionary": ["rel": ["tInt": -3]],
           ]
        )
    }

    func testKeyedContainer_Encodes_UInts() {
        let uints = AllTypes(
            tUInt: 10,
            tUInt8: 20,
            tUInt16: 30,
            tUInt32: 40,
            tUInt64: .max,
            tArray: [AllTypes(tUInt: 50), AllTypes(tUInt: 60)],
            tDictionary: ["rel": AllTypes(tUInt: 70)]
        )

        XCTAssertEqual(
            try KeyValueEncoder().encode(uints) as? NSDictionary,
            [
               "tUInt": 10,
               "tUInt8": 20,
               "tUInt16": 30,
               "tUInt32": 40,
               "tUInt64": UInt64.max,
               "tArray": [["tUInt": 50], ["tUInt": 60]],
               "tDictionary": ["rel": ["tUInt": 70]],
           ]
        )
    }

    func testKeyedContainer_Encodes_NestedKeyedContainer() {
        XCTAssertEqual(
            try KeyValueEncoder.encodeKeyedValue(keyedBy: AnyCodingKey.self) {
                var nested = $0.nestedContainer(keyedBy: AnyCodingKey.self, forKey: "fish")
                try nested.encode(true, forKey: "chips")
            }.getValue() as? NSDictionary,
            [
                "fish": ["chips": true]
            ]
        )
    }

    func testKeyedContainer_Encodes_NestedUnkeyedContainer() {
        XCTAssertEqual(
            try KeyValueEncoder.encodeKeyedValue(keyedBy: AnyCodingKey.self) {
                var nested = $0.nestedUnkeyedContainer(forKey: "fish")
                try nested.encode(true)
                try nested.encode(false)
            }.getValue() as? NSDictionary,
            [
                "fish": [true, false]
            ]
        )
    }

    func testKeyedContainer_Encodes_SuperContainer() {
        XCTAssertEqual(
            try KeyValueEncoder.encodeKeyedValue(keyedBy: AnyCodingKey.self) {
                try Int(10).encode(to: $0.superEncoder())
            }.getValue() as? NSDictionary,
            [
                "super": 10
            ]
        )
    }

    func testUnkeyedContainer_Encodes_Optionals() {
        XCTAssertEqual(
            try KeyValueEncoder.encodeUnkeyedValue {
                try $0.encode(String?.none)
                try $0.encode(String?.some("fish"))
                try $0.encodeNil()
                try $0.encode("chips")
                try $0.encode(Empty())
            }.getValue() as? NSArray,
            [
                Optional<Any>.none as Any,
                "fish",
                Optional<Any>.none as Any,
                "chips",
                NSDictionary()
            ]
        )
    }

    func testUnkeyedContainer_Encodes_Bool() {
        XCTAssertEqual(
            try KeyValueEncoder.encodeUnkeyedValue {
                try $0.encode(true)
                try $0.encode(false)
            }.getValue() as? NSArray,
            [true, false]
        )
    }

    func testUnkeyedContainer_Encodes_RealNumbers() {
        XCTAssertEqual(
            try KeyValueEncoder.encodeUnkeyedValue {
                try $0.encode(Float(10))
                try $0.encode(Double(20))
            }.getValue() as? NSArray,
            [10, 20]
        )
    }

    func testUnkeyedContainer_Encodes_Ints() {
        XCTAssertEqual(
            try KeyValueEncoder.encodeUnkeyedValue {
                try $0.encode(Int(10))
                try $0.encode(Int8(-20))
                try $0.encode(Int16(30))
                try $0.encode(Int32(-40))
                try $0.encode(Int64.max)
            }.getValue() as? NSArray,
            [
                Int(10),
                Int8(-20),
                Int16(30),
                Int32(-40),
                Int64.max
            ]
        )
    }

    func testUnkeyedContainer_Encodes_RawRepresentable() throws {
        XCTAssertEqual(
            try KeyValueEncoder.encodeUnkeyedValue {
                try $0.encode(Seafood.fish)
                try $0.encode(Seafood.chips)
            }.getValue() as? NSArray,
            [
                "fish",
                "chips"
            ]
        )
    }

    func testUnkeyedContainer_Encodes_URL() throws {
        XCTAssertEqual(
            try KeyValueEncoder.encodeUnkeyedValue {
                try $0.encode(URL(string: "fish.com")!)
            }.getValue() as? NSArray,
            [
                URL(string: "fish.com")!
            ]
        )
    }

    func testUnkeyedContainer_Encodes_UInts() {
        XCTAssertEqual(
            try KeyValueEncoder.encodeUnkeyedValue {
                try $0.encode(UInt(10))
                try $0.encode(UInt8(20))
                try $0.encode(UInt16(30))
                try $0.encode(UInt32(40))
                try $0.encode(UInt64.max)
            }.getValue() as? NSArray,
            [
                UInt(10),
                UInt8(20),
                UInt16(30),
                UInt32(40),
                UInt64.max
            ]
        )
    }

    func testUnkeyedContainer_Encodes_NestedKeyedContainer() {
        XCTAssertEqual(
            try KeyValueEncoder.encodeUnkeyedValue {
                try $0.encode(10)
                var container = $0.nestedContainer(keyedBy: AnyCodingKey.self)
                try container.encode(20, forKey: "fish")
            }.getValue() as? NSArray,
            [10, ["fish": 20]]
        )
    }

    func testUnkeyedContainer_Encodes_NestedUnkeyedContainer() {
        XCTAssertEqual(
            try KeyValueEncoder.encodeUnkeyedValue {
                try $0.encode(10)
                var container = $0.nestedUnkeyedContainer()
                try container.encode(20)
                try container.encode(30)
            }.getValue() as? NSArray,
            [10, [20, 30]]
        )
    }

    func testUnkeyedContainer_Encodes_SuperContainer() {
        XCTAssertEqual(
            try KeyValueEncoder.encodeUnkeyedValue {
                try $0.encode(10)
                try Int(20).encode(to: $0.superEncoder())
            }.getValue() as? NSArray,
            [10, 20]
        )
    }

    func testSupportedCodableTypes() {
        XCTAssertTrue(
            EncodedValue.isSupportedValue(URL(string: "fish.com")!)
        )
        XCTAssertTrue(
            EncodedValue.isSupportedValue(Date())
        )
        XCTAssertTrue(
            EncodedValue.isSupportedValue(Data())
        )
        XCTAssertTrue(
            EncodedValue.isSupportedValue(Decimal())
        )
    }

    func testAnyCodingKey() {
        XCTAssertEqual(
            AnyCodingKey(intValue: 9).intValue,
            9
        )
        XCTAssertEqual(
            AnyCodingKey(intValue: 9).stringValue,
            "Index 9"
        )
        XCTAssertEqual(
            AnyCodingKey(stringValue: "fish").stringValue,
            "fish"
        )
    }

    func testNilEncodingStrategy_SingleContainer() {
        let encoder = KeyValueEncoder()

        encoder.nilEncodingStrategy = .removed
        XCTAssertNil(
            try encoder.encode(Int?.none)
        )

        encoder.nilEncodingStrategy = .default
        XCTAssertNotNil(
            try encoder.encode(Int?.none)
        )
        XCTAssertEqual(
            try encoder.encode(Int?.none) as? Int?,
            .none
        )

        encoder.nilEncodingStrategy = .stringNull
        XCTAssertEqual(
            try encoder.encode(Int?.none) as? String,
            "$null"
        )

        encoder.nilEncodingStrategy = .nsNull
        XCTAssertTrue(
            try encoder.encode(Int?.none) is NSNull
        )
    }

    func testNilEncodingStrategy_UnkeyedContainer() {
        let encoder = KeyValueEncoder()

        encoder.nilEncodingStrategy = .removed
        XCTAssertEqual(
            try encoder.encode([1, 2, Int?.none, 4]) as? [Int],
            [1, 2, 4]
        )

        encoder.nilEncodingStrategy = .default
        XCTAssertEqual(
            try encoder.encode([1, 2, Int?.none, 4]) as? [Int?],
            [1, 2, nil, 4]
        )

        encoder.nilEncodingStrategy = .stringNull
        XCTAssertEqual(
            try encoder.encode([1, Int?.none, 3, 4]) as? NSArray,
            [1, "$null", 3, 4]
        )

        encoder.nilEncodingStrategy = .nsNull
        XCTAssertEqual(
            try encoder.encode([1, 2, 3, Int?.none]) as? NSArray,
            [1, 2, 3, NSNull()]
        )
    }

    func testNilEncodingStrategy_KeyedContainer() {
        XCTAssertEqual(
            try KeyValueEncoder.encodeKeyedValue(keyedBy: AnyCodingKey.self, nilEncodingStrategy: .removed) {
                try $0.encodeNil(forKey: "fish")
                try $0.encode(Null(), forKey: "chips")
            }.getValue() as? NSDictionary,
            [:]
        )
        XCTAssertEqual(
            try KeyValueEncoder.encodeKeyedValue(keyedBy: AnyCodingKey.self, nilEncodingStrategy: .default) {
                try $0.encodeNil(forKey: "fish")
                try $0.encode(Null(), forKey: "chips")
            }.getValue() as? NSDictionary,
            [
                "fish": String?.none as Any,
                "chips": String?.none as Any
            ]
        )
        XCTAssertEqual(
            try KeyValueEncoder.encodeKeyedValue(keyedBy: AnyCodingKey.self, nilEncodingStrategy: .stringNull) {
                try $0.encodeNil(forKey: "fish")
                try $0.encode(Null(), forKey: "chips")
            }.getValue() as? NSDictionary,
            [
                "fish": "$null",
                "chips": "$null",
            ]
        )
        XCTAssertEqual(
            try KeyValueEncoder.encodeKeyedValue(keyedBy: AnyCodingKey.self, nilEncodingStrategy: .nsNull) {
                try $0.encodeNil(forKey: "fish")
                try $0.encode(Null(), forKey: "chips")
            }.getValue() as? NSDictionary,
            [
                "fish": NSNull(),
                "chips": NSNull(),
            ]
        )
    }

    #if !os(WASI)
    func testPlistCompatibleEncoder() throws {
        let keyValueAny = try KeyValueEncoder.makePlistCompatible().encode([1, 2, Int?.none, 4])
        XCTAssertEqual(
            try PropertyListDecoder.decodeAny([Int?].self, from: keyValueAny),
            [1, 2, Int?.none, 4]
        )
    }
    #endif

    func testEncoder_Encodes_Dates() {
        let date = Date()
        XCTAssertEqual(
            try KeyValueEncoder().encode(date) as? Date,
            date
        )
    }

    func testJSONCompatibleEncoder() throws {
        let keyValueAny = try KeyValueEncoder.makeJSONCompatible().encode([1, 2, Int?.none, 4])
        XCTAssertEqual(
            try JSONDecoder.decodeAny([Int?].self, from: keyValueAny),
            [1, 2, Int?.none, 4]
        )
    }
}

private extension KeyValueEncoder {

    static func encodeSingleValue(nilEncodingStrategy: NilEncodingStrategy = .default,
                                  with closure: (inout SingleValueEncodingContainer) throws -> Void) throws -> EncodedValue {
        let encoder = KeyValueEncoder()
        encoder.nilEncodingStrategy = nilEncodingStrategy
        return try encoder.encodeValue {
            var container = $0.singleValueContainer()
            try closure(&container)
        }
    }

    static func encodeUnkeyedValue(with closure: (inout UnkeyedEncodingContainer) throws -> Void) throws -> EncodedValue {
        try KeyValueEncoder().encodeValue {
            var container = $0.unkeyedContainer()
            try closure(&container)
        }
    }

    static func encodeKeyedValue<K: CodingKey>(keyedBy: K.Type = K.self,
                                               nilEncodingStrategy: NilEncodingStrategy = .default,
                                               with closure: @escaping (inout KeyedEncodingContainer<K>) throws -> Void) throws -> EncodedValue {
        let encoder = KeyValueEncoder()
        encoder.nilEncodingStrategy = nilEncodingStrategy
        return try encoder.encodeValue {
            var container = $0.container(keyedBy: K.self)
            try closure(&container)
        }
    }

    func encodeValue(with closure: (Encoder) throws -> Void) throws -> EncodedValue {
        try withoutActuallyEscaping(closure) {
            try self.encodeValue(StubEncoder(closure: $0))
        }
    }

    static func makeJSONCompatible() -> KeyValueEncoder {
        let encoder = KeyValueEncoder()
        encoder.nilEncodingStrategy = .nsNull
        return encoder
    }
}

private struct StubEncoder: Encodable {
    var closure: (Encoder) throws -> Void

    func encode(to encoder: Encoder) throws {
        try closure(encoder)
    }
}

extension AnyCodingKey: ExpressibleByStringLiteral {
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

extension KeyValueEncoder.EncodedValue: Equatable {

    public static func ==(lhs: Self, rhs: Self) -> Bool {
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
    func encode(to encoder: Encoder) throws { }
}

private struct Null: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}
