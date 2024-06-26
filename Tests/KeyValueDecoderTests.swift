//
//  KeyValueDecoderTests.swift
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

final class KeyValueDecoderTests: XCTestCase {

    func testDecodes_String() {
        XCTAssertEqual(
            try KeyValueDecoder.decode(String.self, from: "Shrimp"),
            "Shrimp"
        )
        XCTAssertThrowsError(
            try KeyValueDecoder.decode(String.self, from: Int16.max)
        )
    }

    func testDecodes_RawRepresentable() {
        XCTAssertEqual(
            try KeyValueDecoder.decode(Seafood.self, from: "fish"),
            .fish
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Seafood.self, from: "chips"),
            .chips
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode([Seafood].self, from: ["fish", "chips"]),
            [.fish, .chips]
        )
        XCTAssertThrowsError(
            try KeyValueDecoder.decode(Seafood.self, from: "invalid")
        )
        XCTAssertThrowsError(
            try KeyValueDecoder.decode(Seafood.self, from: 10)
        )
    }

    func testDecodes_NestedType() {
        let dictionary: [String: Any] = [
            "id": 1,
            "name": "root",
            "desc": [["id": 2], ["id": 3]],
            "rel": ["left": ["id": 4, "desc": [["id": 5]] as Any],
                    "right": ["id": 6]],
        ]

        XCTAssertEqual(
            try KeyValueDecoder.decode(Node.self, from: dictionary),
            Node(id: 1,
                 name: "root",
                 descendents: [Node(id: 2), Node(id: 3)],
                 related: ["left": Node(id: 4, descendents: [Node(id: 5)]),
                           "right": Node(id: 6)]
            )
        )

        XCTAssertThrowsError(
            try KeyValueDecoder.decode(Node.self, from: [String: Any]())
        )
    }

    func testDecodes_Ints() {
        XCTAssertEqual(
            try KeyValueDecoder.decode(Int16.self, from: Int16.max),
            Int16.max
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Int16.self, from: UInt16(10)),
            10
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Int16.self, from: NSNumber(10)),
            10
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Int16.self, from: 10.0),
            10
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Int16.self, from: NSNumber(10.0)),
            10
        )
        XCTAssertThrowsError(
            try KeyValueDecoder.decode(Int8.self, from: Int16.max)
        )
        XCTAssertThrowsError(
            try KeyValueDecoder.decode(Int8.self, from: NSNumber(value: Int16.max))
        )
        XCTAssertThrowsError(
            try KeyValueDecoder.decode(Int16.self, from: UInt16.max)
        )
        XCTAssertThrowsError(
            try KeyValueDecoder.decode(Int16.self, from: Optional<Int16>.none)
        )
        XCTAssertThrowsError(
            try KeyValueDecoder.decode(Int16.self, from: NSNull())
        )
        XCTAssertThrowsError(
            try KeyValueDecoder.decode(Int8.self, from: 10.1)
        )
        XCTAssertThrowsError(
            try KeyValueDecoder.decode(Int8.self, from: NSNumber(10.1))
        )
    }

    func testDecodes_UInts() {
        XCTAssertEqual(
            try KeyValueDecoder.decode(UInt16.self, from: UInt16.max),
            UInt16.max
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(UInt8.self, from: NSNumber(10)),
            10
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(UInt8.self, from: 10.0),
            10
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(UInt8.self, from: NSNumber(10.0)),
            10
        )
        XCTAssertThrowsError(
            try KeyValueDecoder.decode(UInt8.self, from: UInt16.max)
        )
        XCTAssertThrowsError(
            try KeyValueDecoder.decode(UInt8.self, from: NSNumber(-10))
        )
        XCTAssertThrowsError(
            try KeyValueDecoder.decode(UInt8.self, from: Optional<UInt8>.none)
        )
        XCTAssertThrowsError(
            try KeyValueDecoder.decode(UInt8.self, from: NSNull())
        )
        XCTAssertThrowsError(
            try KeyValueDecoder.decode(UInt8.self, from: 10.1)
        )
        XCTAssertThrowsError(
            try KeyValueDecoder.decode(UInt8.self, from: NSNumber(10.1))
        )
    }

    func testDecodes_Float(){
        XCTAssertEqual(
            try KeyValueDecoder.decode(Float.self, from: 10),
            10
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Float.self, from: -100.5),
            -100.5
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Float.self, from: UInt8.max),
            255
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Float.self, from: UInt64.max),
            Float(UInt64.max)
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Float.self, from: NSNumber(20)),
            20
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Float.self, from: NSNumber(value: 50.5)),
            50.5
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Float.self, from: Decimal.pi),
            Float((Decimal.pi as NSNumber).doubleValue)
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Float.self, from: UInt.max),
            Float(UInt.max)
        )
        XCTAssertThrowsError(
            try KeyValueDecoder.decode(Float.self, from: true)
        )
    }

    func testDecodes_Double(){
        XCTAssertEqual(
            try KeyValueDecoder.decode(Double.self, from: 10),
            10
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Double.self, from: -100.5),
            -100.5
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Double.self, from: UInt8.max),
            255
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Double.self, from: UInt64.max),
            Double(UInt64.max)
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Double.self, from: NSNumber(20)),
            20
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Double.self, from: NSNumber(value: 50.5)),
            50.5
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Double.self, from: Decimal.pi),
            (Decimal.pi as NSNumber).doubleValue
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Double.self, from: UInt.max),
            Double(UInt.max)
        )
        XCTAssertThrowsError(
            try KeyValueDecoder.decode(Double.self, from: true)
        )
    }

    func testDecodes_Decimal() {
        XCTAssertEqual(
            try KeyValueDecoder.decode(Decimal.self, from: 10),
            10
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Decimal.self, from: -100.5),
            -100.5
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Decimal.self, from: UInt8.max),
            255
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Decimal.self, from: NSNumber(20)),
            20
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Decimal.self, from: NSNumber(value: 50.5)),
            50.5
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Decimal.self, from: Decimal.pi),
            .pi
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(Decimal.self, from: UInt.max),
            Decimal(UInt.max)
        )
        XCTAssertThrowsError(
            try KeyValueDecoder.decode(Decimal.self, from: true)
        )
    }

    func testDecodes_URL() {
        XCTAssertEqual(
            try KeyValueDecoder.decode(URL.self, from: "fish.com"),
            URL(string: "fish.com")
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(AllTypes.self, from: ["tURL": "fish.com"]),
            AllTypes(tURL: URL(string: "fish.com")!)
        )

        XCTAssertEqual(
            try KeyValueDecoder.decode(URL.self, from: "fish.com"),
            URL(string: "fish.com")
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(URL.self, from: URL(string: "fish.com")!),
            URL(string: "fish.com")
        )

        XCTAssertThrowsError(
            try KeyValueDecoder.decode(URL.self, from: "")
        )
    }

    func testDecodes_Date() {
        let date = Date(timeIntervalSinceReferenceDate: 0)
        XCTAssertEqual(
            try KeyValueDecoder.decode(Date.self, from: date),
            date
        )
    }

    func testDecodes_Data() {
        XCTAssertEqual(
            try KeyValueDecoder.decode(Data.self, from: Data([0x01])),
            Data([0x01])
        )
    }

    func testDecodes_Null() {
        let decoder = KeyValueDecoder()
        decoder.nilDecodingStrategy = .default

        XCTAssertThrowsError(
            try decoder.decode(String?.self, from: NSNull())
        )

        decoder.nilDecodingStrategy = .nsNull
        XCTAssertEqual(
            try decoder.decode(String?.self, from: NSNull()),
            nil
        )
    }

    func testDecodes_Optionals() {
        XCTAssertEqual(
            try KeyValueDecoder.decode(String?.self, from: String?.some("fish")),
            "fish"
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(String?.self, from: String?.none),
            nil
        )
        XCTAssertThrowsError(
            try KeyValueDecoder.decode(String.self, from: String?.none)
        )
    }

    func testDecodes_NestedUnkeyed() {
        XCTAssertEqual(
            try KeyValueDecoder.decode([[Seafood]].self, from: [["fish", "chips"], ["fish"]]),
            [[.fish, .chips], [.fish]]
        )
    }

    func testDecodes_UnkeyedOptionals() {
        let decoder = KeyValueDecoder()

        decoder.nilDecodingStrategy = .removed
        XCTAssertEqual(
            try decoder.decode([Int?].self, from: [1, 2, 3, 4]),
            [1, 2, 3, 4]
        )

        decoder.nilDecodingStrategy = .default
        XCTAssertEqual(
            try decoder.decode([Int?].self, from: [1, 2, Int?.none, 4]),
            [1, 2, nil, 4]
        )

        decoder.nilDecodingStrategy = .stringNull
        XCTAssertEqual(
            try decoder.decode([Int?].self, from: [1, "$null", 3, 4] as [Any]),
            [1, nil, 3, 4]
        )

        decoder.nilDecodingStrategy = .nsNull
        XCTAssertEqual(
            try decoder.decode([Int?].self, from: [1, 2, 3, NSNull()] as [Any]),
            [1, 2, 3, nil]
        )
    }

    func testDecodes_KeyedBool() {
        XCTAssertEqual(
            try KeyValueDecoder.decode(AllTypes.self, from: ["tBool": true]),
            AllTypes(
                tBool: true
            )
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode(AllTypes.self, from: ["tBool": false]),
            AllTypes(
                tBool: false
            )
        )
    }

    func testKeyedContainer_Decodes_NestedKeyedContainer() {
        XCTAssertEqual(
            try KeyValueDecoder.decodeValue(from: ["id": 1, "rel": ["left": ["id": 2]]], keyedBy: Node.CodingKeys.self) { container in
                let nested = try container.nestedContainer(keyedBy: Node.RelatedKeys.self, forKey: .related)
                return try nested.decode(Node.self, forKey: .left)
            },
            Node(id: 2)
        )
    }

    func testKeyedContainer_Decodes_NestedUnkeyedContainer() {
        XCTAssertEqual(
            try KeyValueDecoder.decodeValue(from: ["id": 1, "desc": [["id": 2]]], keyedBy: Node.CodingKeys.self) { container in
                var nested = try container.nestedUnkeyedContainer(forKey: .descendents)
                return try nested.decode(Node.self)
            },
            Node(id: 2)
        )
    }

    func testKeyedContainer_ThrowsError_WhenKeyIsUknown() {
        XCTAssertThrowsError(
            try KeyValueDecoder.decodeValue(from: [:], keyedBy: Seafood.CodingKeys.self) { container in
                try container.decode(Bool.self, forKey: .chips)
            }
        )
    }

    func testKeyedContainer_Decodes_SuperContainer() {
        XCTAssertEqual(
            try KeyValueDecoder.decodeValue(from: ["id": 1], keyedBy: Node.CodingKeys.self) { container in
                try Node(from: container.superDecoder())
            },
            Node(id: 1)
        )
    }

    func testKeyedContainer_Decodes_NestedSuperContainer() {
        XCTAssertEqual(
            try KeyValueDecoder.decodeValue(from: ["id": 1], keyedBy: Node.CodingKeys.self) { container in
                try Int(from: container.superDecoder(forKey: .id))
            },
            1
        )
    }

    func testDecodes_KeyedRealNumbers() {
        let dict = [
            "tDouble": -10,
            "tFloat": 20.5
        ]

        XCTAssertEqual(
            try KeyValueDecoder.decode(AllTypes.self, from: dict),
            AllTypes(
                tDouble: -10,
                tFloat: 20.5
            )
        )
    }

    func testDecodes_KeyedInts() {
        let dict = [
            "tInt": 10,
            "tInt8": -20,
            "tInt16": 30,
            "tInt32": -40,
            "tInt64": 50
        ]

        XCTAssertEqual(
            try KeyValueDecoder.decode(AllTypes.self, from: dict),
            AllTypes(
                tInt: 10,
                tInt8: -20,
                tInt16: 30,
                tInt32: -40,
                tInt64: 50
            )
        )
    }

    func testDecodes_KeyedUInts() {
        let dict = [
            "tUInt": 10,
            "tUInt8": 20,
            "tUInt16": 30,
            "tUInt32": 40,
            "tUInt64": 50
        ]

        XCTAssertEqual(
            try KeyValueDecoder.decode(AllTypes.self, from: dict),
            AllTypes(
                tUInt: 10,
                tUInt8: 20,
                tUInt16: 30,
                tUInt32: 40,
                tUInt64: 50
            )
        )

        XCTAssertThrowsError(
            try KeyValueDecoder.decode(AllTypes.self, from: ["tUInt": -1])
        )
    }

    func testDecodes_UnkeyedInts() {
        XCTAssertEqual(
            try KeyValueDecoder.decode([Int].self, from: [-10, 20, 30, 40.0, -50.0]),
            [-10, 20, 30, 40, -50]
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode([Int8].self, from: [10, -20, 30]),
            [10, -20, 30]
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode([Int16].self, from: [10, 20, -30]),
            [10, 20, -30]
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode([Int32].self, from: [-10, 20, 30]),
            [-10, 20, 30]
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode([Int64].self, from: [10, -20, 30]),
            [10, -20, 30]
        )

        XCTAssertEqual(
            try KeyValueDecoder.decodeUnkeyedValue(from: [10, -20, 30, -40, 50]) { unkeyed in
                try AllTypes(
                    tInt: unkeyed.decode(Int.self),
                    tInt8: unkeyed.decode(Int8.self),
                    tInt16: unkeyed.decode(Int16.self),
                    tInt32: unkeyed.decode(Int32.self),
                    tInt64: unkeyed.decode(Int64.self)
                )
            },
            AllTypes(
                tInt: 10,
                tInt8: -20,
                tInt16: 30,
                tInt32: -40,
                tInt64: 50
            )
        )
    }

    func testDecodes_UnkeyedDecimals() {
        XCTAssertEqual(
            try KeyValueDecoder.decode([Decimal].self, from: [Decimal(10), Double(20), Float(30), Int(10), UInt.max] as [Any]),
            [10, 20, 30, 10, Decimal(UInt.max)]
        )
    }

    func testDecodes_UnkeyedBool() {
        XCTAssertEqual(
            try KeyValueDecoder.decodeUnkeyedValue(from: [true, false, false, true]) { unkeyed in
                try [
                    unkeyed.decode(Bool.self),
                    unkeyed.decode(Bool.self),
                    unkeyed.decode(Bool.self),
                    unkeyed.decode(Bool.self)
                ]
            },
            [true, false, false, true]
        )
    }

    func testDecodes_UnkeyedString() {
        XCTAssertEqual(
            try KeyValueDecoder.decodeUnkeyedValue(from: ["fish", "chips"]) { unkeyed in
                try [
                    unkeyed.decode(String.self),
                    unkeyed.decode(String.self)
                ]
            },
            ["fish", "chips"]
        )
    }

    func testDecodes_UnkeyedFloat() {
        XCTAssertEqual(
            try KeyValueDecoder.decode([Float].self, from: [Double(5.5), Float(-0.5), Int(-10), UInt64.max] as [Any]),
            [5.5, -0.5, -10.0, Float(UInt64.max)]
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode([Double].self, from: [Double(5.5), Float(-0.5), Int(-10), UInt64.max] as [Any]),
            [5.5, -0.5, -10.0, Double(UInt64.max)]
        )

        XCTAssertEqual(
            try KeyValueDecoder.decodeUnkeyedValue(from: [5.5, -10]) { unkeyed in
                try AllTypes(
                    tDouble: unkeyed.decode(Double.self),
                    tFloat: unkeyed.decode(Float.self)
                )
            },
            AllTypes(
                tDouble: 5.5,
                tFloat: -10.0
            )
        )
    }

    func testDecodes_UnkeyedNil() {
        let decoder = KeyValueDecoder()
        decoder.nilDecodingStrategy = .default

        XCTAssertEqual(
            try KeyValueDecoder.decodeUnkeyedValue(from: [String?.none as Any, NSNull() as Any, -10 as Any]) { unkeyed in
                try [
                    unkeyed.decodeNil(),
                    unkeyed.decodeNil(),
                    unkeyed.decodeNil()
                ]
            },
            [true, false, false]
        )

        XCTAssertThrowsError(
            try KeyValueDecoder.decodeUnkeyedValue(from: []) { unkeyed in
                try unkeyed.decodeNil()
            }
        )
    }

    func testDecodes_UnkeyedCount() {
        XCTAssertEqual(
            try KeyValueDecoder.decodeUnkeyedValue(from: [10, 20, 30, 40, 50]) { unkeyed in
                unkeyed.count
            },
            5
        )
    }

    func testDecodes_UnkeyedUInts() {
        XCTAssertEqual(
            try KeyValueDecoder.decode([UInt].self, from: [10, 20, 30, 40.0]),
            [10, 20, 30, 40]
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode([UInt8].self, from: [10, 20, 30]),
            [10, 20, 30]
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode([UInt16].self, from: [10, 20, 30]),
            [10, 20, 30]
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode([UInt32].self, from: [10, 20, 30]),
            [10, 20, 30]
        )
        XCTAssertEqual(
            try KeyValueDecoder.decode([UInt64].self, from: [10, UInt8(20), UInt64.max] as [Any]),
            [10, 20, .max]
        )

        XCTAssertEqual(
            try KeyValueDecoder.decodeUnkeyedValue(from: [10, 20, 30, 40, 50]) { unkeyed in
                try AllTypes(
                    tUInt: unkeyed.decode(UInt.self),
                    tUInt8: unkeyed.decode(UInt8.self),
                    tUInt16: unkeyed.decode(UInt16.self),
                    tUInt32: unkeyed.decode(UInt32.self),
                    tUInt64: unkeyed.decode(UInt64.self)
                )
            },
            AllTypes(
                tUInt: 10,
                tUInt8: 20,
                tUInt16: 30,
                tUInt32: 40,
                tUInt64: 50
            )
        )
    }

    func testUnKeyedContainer_Decodes_NestedKeyedContainer() {
        XCTAssertEqual(
            try KeyValueDecoder.decodeUnkeyedValue(from: [["id": 1]]) { unkeyed in
                let nested = try unkeyed.nestedContainer(keyedBy: Node.CodingKeys.self)
                return try nested.decode(Int.self, forKey: .id)
            },
            1
        )
    }

    func testUnKeyedContainer_Decodes_NestedUnkeyedContainer() {
        XCTAssertEqual(
            try KeyValueDecoder.decodeUnkeyedValue(from: [[1, 2, 3]]) { unkeyed in
                var nested = try unkeyed.nestedUnkeyedContainer()
                return try [
                    nested.decode(Int.self),
                    nested.decode(Int.self),
                    nested.decode(Int.self)
                ]
            },
            [1, 2, 3]
        )
    }

    func testUnKeyedContainer_Decodes_SuperContainer() {
        XCTAssertEqual(
            try KeyValueDecoder.decodeUnkeyedValue(from: [1, 2, 3]) { unkeyed in
                let decoder = try unkeyed.superDecoder()
                var container = try decoder.unkeyedContainer()
                return try [
                    container.decode(Int.self),
                    container.decode(Int.self),
                    container.decode(Int.self)
                ]
            },
            [1, 2, 3]
        )
    }

    func testNSNumber_Int64Value() {
        XCTAssertEqual(NSNumber(10).getInt64Value(), 10)
        XCTAssertEqual(NSNumber(-10).getInt64Value(), -10)
        XCTAssertEqual(NSNumber(value: UInt8.max).getInt64Value(), Int64(UInt8.max))
        XCTAssertEqual(NSNumber(value: UInt16.max).getInt64Value(), Int64(UInt16.max))
        XCTAssertEqual(NSNumber(value: UInt32.max).getInt64Value(), Int64(UInt32.max))
        XCTAssertEqual(NSNumber(value: UInt64.max).getInt64Value(), -1) // NSNumber stores unsigned values with sign in the next largest size but 64bit is largest size.
        XCTAssertEqual(NSNumber(10.5).getInt64Value(), nil)
        XCTAssertEqual(NSNumber(true).getInt64Value(), nil)
    }

    func testNSNumber_DoubleValue() {
        XCTAssertEqual(NSNumber(10.5).getDoubleValue(), 10.5)
        XCTAssertEqual(NSNumber(value: Float(20)).getDoubleValue(), 20)
        XCTAssertEqual(NSNumber(value: CGFloat(30.5)).getDoubleValue(), 30.5)
        XCTAssertEqual(NSNumber(value: Float(40.5)).getDoubleValue(), 40.5)
        XCTAssertEqual(NSNumber(value: Double.pi).getDoubleValue(), .pi)
        XCTAssertEqual(NSNumber(-10).getDoubleValue(), nil)
        XCTAssertEqual(NSNumber(true).getDoubleValue(), nil)
        XCTAssertEqual((true as NSNumber).getDoubleValue(), nil)
    }

    func testDecodingErrors() {
        AssertThrowsDecodingError(try KeyValueDecoder.decode(Seafood.self, from: 10)) { error in
            XCTAssertEqual(error.debugDescription, "Expected String at SELF, found Int")
        }
        AssertThrowsDecodingError(try KeyValueDecoder.decode(Int.self, from: NSNull())) { error in
            XCTAssertEqual(error.debugDescription, "Expected BinaryInteger at SELF, found NSNull")
        }
        AssertThrowsDecodingError(try KeyValueDecoder.decode(Int.self, from: Optional<Int>.none)) { error in
            XCTAssertEqual(error.debugDescription, "Expected BinaryInteger at SELF, found nil")
        }
        AssertThrowsDecodingError(try KeyValueDecoder.decode([Int].self, from: [0, 1, true] as [Any])) { error in
            XCTAssertEqual(error.debugDescription, "Expected BinaryInteger at SELF[2], found Bool")
        }
        AssertThrowsDecodingError(try KeyValueDecoder.decode(AllTypes.self, from: ["tArray": [["tString": 0]]] as [String: Any])) { error in
            XCTAssertEqual(error.debugDescription, "Expected String at SELF.tArray[0].tString, found Int")
        }
        AssertThrowsDecodingError(try KeyValueDecoder.decode(AllTypes.self, from: ["tArray": [["tString": 0]]] as [String: Any])) { error in
            XCTAssertEqual(error.debugDescription, "Expected String at SELF.tArray[0].tString, found Int")
        }
    }

    #if !os(WASI)
    func testPlistCompatibleDecoder() throws {
        let plistAny = try PropertyListEncoder.encodeAny([1, 2, Int?.none, 4])
        XCTAssertEqual(
            try KeyValueDecoder.makePlistCompatible().decode([Int?].self, from: plistAny),
            [1, 2, Int?.none, 4]
        )

        XCTAssertEqual(
            try KeyValueDecoder.makePlistCompatible().decode(String?.self, from: "$null"),
            nil
        )
    }

    func testJSONCompatibleDecoder() throws {
        let jsonAny = try JSONEncoder.encodeAny([1, 2, Int?.none, 4])
        XCTAssertEqual(
            try KeyValueDecoder.makeJSONCompatible().decode([Int?].self, from: jsonAny),
            [1, 2, Int?.none, 4]
        )
    }
    #endif
}

func AssertThrowsDecodingError<T>(_ expression: @autoclosure () throws -> T,
                                  file: StaticString = #filePath,
                                  line: UInt = #line,
                                  _ errorHandler: (DecodingError) -> Void = { _ in }) {
    do {
        _ = try expression()
        XCTFail("Expected error", file: file, line: line)
    } catch let error as DecodingError {
        errorHandler(error)
    } catch {
        XCTFail("Expected DecodingError \(type(of: error))", file: file, line: line)
    }
}

extension DecodingError {

    var context: Context? {
        switch self {
        case .valueNotFound(_, let context),
              .dataCorrupted(let context),
              .typeMismatch(_, let context),
              .keyNotFound(_, let context):
            return context
        @unknown default:
            return nil
        }
    }

    var debugDescription: String? {
        context?.debugDescription
    }
}

private extension KeyValueDecoder {

    static func decode<T: Decodable, V>(_ type: T.Type, from value: V) throws -> T {
        let decoder = KeyValueDecoder()
        return try decoder.decode(type, from: value)

    }

    static func decodeValue<K: CodingKey, T>(from value: [String: Any], keyedBy: K.Type = K.self, with closure: @escaping (inout KeyedDecodingContainer<K>) throws -> T) throws -> T {
        let proxy = StubDecoder.Proxy { decoder in
            var container = try decoder.container(keyedBy: K.self)
            return try closure(&container)
        }

        let decoder = KeyValueDecoder()
        decoder.userInfo[.decoder] = proxy.decode(from:)
        _ = try decoder.decode(StubDecoder.self, from: value)
        return proxy.result!
    }

    static func decodeUnkeyedValue<T>(from value: [Any], with closure: @escaping (inout any UnkeyedDecodingContainer) throws -> T) throws -> T {
        let proxy = StubDecoder.Proxy { decoder in
            var container = try decoder.unkeyedContainer()
            return try closure(&container)
        }

        let decoder = KeyValueDecoder()
        decoder.userInfo[.decoder] = proxy.decode(from:)
        _ = try decoder.decode(StubDecoder.self, from: value)
        return proxy.result!
    }

    static func makeJSONCompatible() -> KeyValueDecoder {
        let decoder = KeyValueDecoder()
        decoder.nilDecodingStrategy = .nsNull
        return decoder
    }
}

private extension CodingUserInfoKey {
    static let decoder = CodingUserInfoKey(rawValue: "decoder")!
}

private struct StubDecoder: Decodable {

    final class Proxy<T> {
        private let closure: (any Decoder) throws -> T
        private(set) var result: T?

        init(_ closure: @escaping (any Decoder) throws -> T) {
            self.closure = closure
        }

        func decode(from decoder: any Decoder) throws {
            self.result = try closure(decoder)
        }
    }

    init(from decoder: any Decoder) throws {
        let closure = decoder.userInfo[.decoder] as! (any Decoder) throws -> Void
        try closure(decoder)
    }
}

enum Seafood: String, Codable {
    case fish
    case chips

    enum CodingKeys: CodingKey {
        case fish
        case chips
    }
}

struct AllTypes: Codable, Equatable {
    var tBool: Bool?
    var tString: String?
    var tDouble: Double?
    var tFloat: Float?
    var tInt: Int?
    var tInt8: Int8?
    var tInt16: Int16?
    var tInt32: Int32?
    var tInt64: Int64?
    var tUInt: UInt?
    var tUInt8: UInt8?
    var tUInt16: UInt16?
    var tUInt32: UInt32?
    var tUInt64: UInt64?

    var tData: Data?
    var tDate: Date?
    var tDecimal: Decimal?
    var tURL: URL?
    var tArray: [AllTypes]?
    var tDictionary: [String: AllTypes]?
}

struct SomeTypes: Codable, Equatable {
    var tBool: Bool?
    var tString: String?
}

#if !os(WASI)
private extension PropertyListEncoder {
    static func encodeAny<T: Encodable>(_ value: T) throws -> Any {
        let data = try PropertyListEncoder().encode(value)
        return try PropertyListSerialization.propertyList(from: data, format: nil)
    }
}

private extension JSONEncoder {
    static func encodeAny<T: Encodable>(_ value: T) throws -> Any {
        let data = try JSONEncoder().encode(value)
        return try JSONSerialization.jsonObject(with: data, options: [])
    }
}
#endif
