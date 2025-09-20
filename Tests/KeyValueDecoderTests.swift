//
//  KeyValueDecoderTests.swift
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

@testable import KeyValueCoder

import Foundation
import Testing

struct KeyValueDecoderTests {

    @Test
    func decodes_String() throws {
        let decoder = KeyValueDecoder()

        #expect(
            try decoder.decode(String.self, from: "Shrimp") == "Shrimp"
        )
        #expect(throws: (any Error).self) {
            try decoder.decode(String.self, from: Int16.max)
        }
    }

    @Test
    func decodes_RawRepresentable() throws {
        let decoder = KeyValueDecoder()

        #expect(
            try decoder.decode(Seafood.self, from: "fish") == .fish
        )
        #expect(
            try decoder.decode(Seafood.self, from: "chips") == .chips
        )
        #expect(
            try decoder.decode([Seafood].self, from: ["fish", "chips"]) == [.fish, .chips]
        )
        #expect(throws: (any Error).self) {
            try decoder.decode(Seafood.self, from: "invalid")
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(Seafood.self, from: 10)
        }
    }

    @Test
    func decodes_NestedType() throws {
        let decoder = KeyValueDecoder()
        let dictionary: [String: Any] = [
            "id": 1,
            "name": "root",
            "desc": [["id": 2], ["id": 3]],
            "rel": ["left": ["id": 4, "desc": [["id": 5]] as Any],
                    "right": ["id": 6]]
        ]

        #expect(
            try decoder.decode(Node.self, from: dictionary) == Node(
                id: 1,
                name: "root",
                descendents: [Node(id: 2), Node(id: 3)],
                related: ["left": Node(id: 4, descendents: [Node(id: 5)]),
                          "right": Node(id: 6)]
            )
        )

        #expect(throws: (any Error).self) {
            try decoder.decode(Node.self, from: [String: Any]())
        }
    }

    @Test
    func decodes_Ints() throws {
        let decoder = KeyValueDecoder()

        #expect(
            try decoder.decode(Int16.self, from: Int16.max) == Int16.max
        )
        #expect(
            try decoder.decode(Int16.self, from: UInt16(10)) == 10
        )
        #expect(
            try decoder.decode(Int16.self, from: NSNumber(10)) == 10
        )
        #expect(
            try decoder.decode(Int16.self, from: 10.0) == 10
        )
        #expect(
            try decoder.decode(Int16.self, from: NSNumber(10.0)) == 10
        )
        #expect(throws: (any Error).self) {
            try decoder.decode(Int8.self, from: Int16.max)
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(Int8.self, from: NSNumber(value: Int16.max))
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(Int16.self, from: UInt16.max)
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(Int16.self, from: Optional<Int16>.none as Any)
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(Int16.self, from: NSNull())
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(Int8.self, from: 10.1)
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(Int8.self, from: NSNumber(10.1))
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(Int8.self, from: Double.nan)
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(Int8.self, from: Double.infinity)
        }
    }

    @Test
    func decodesRounded_Ints() throws {
        var decoder = KeyValueDecoder()
        decoder.intDecodingStrategy = .rounding(rule: .toNearestOrAwayFromZero)

        #expect(
            try decoder.decode(Int16.self, from: 10.0) == 10
        )
        #expect(
            try decoder.decode(Int16.self, from: 10.00001) == 10
        )
        #expect(
            try decoder.decode(Int16.self, from: 10.1) == 10
        )
        #expect(
            try decoder.decode(Int16.self, from: 10.5) == 11
        )
        #expect(
            try decoder.decode(Int16.self, from: -10.5) == -11
        )
        #expect(
            try decoder.decode(Int16.self, from: NSNumber(10.5)) == 11
        )
        #expect(
            try decoder.decode([Int].self, from: [10.1, -20.9, 50.00001]) == [10, -21, 50]
        )

        #expect(throws: (any Error).self) {
            try decoder.decode(Int8.self, from: Double(Int16.max))
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(Int8.self, from: NSNumber(value: Double(Int16.max)))
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(Int16.self, from: Optional<Double>.none as Any)
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(Int16.self, from: NSNull())
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(Int16.self, from: Double.nan)
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(Int16.self, from: Double.infinity)
        }
    }

    @Test
    func decodes_UInts() throws {
        let decoder = KeyValueDecoder()

        #expect(
            try decoder.decode(UInt16.self, from: UInt16.max) == UInt16.max
        )
        #expect(
            try decoder.decode(UInt8.self, from: NSNumber(10)) == 10
        )
        #expect(
            try decoder.decode(UInt8.self, from: 10.0) == 10
        )
        #expect(
            try decoder.decode(UInt8.self, from: NSNumber(10.0)) == 10
        )
        #expect(throws: (any Error).self) {
            try decoder.decode(UInt8.self, from: UInt16.max)
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(UInt8.self, from: NSNumber(-10))
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(UInt8.self, from: Optional<UInt8>.none as Any)
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(UInt8.self, from: NSNull())
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(UInt8.self, from: 10.1)
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(UInt8.self, from: NSNumber(10.1))
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(UInt16.self, from: Double.nan)
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(UInt16.self, from: Double.infinity)
        }
    }

    @Test
    func decodesRounded_UInts() throws {
        var decoder = KeyValueDecoder()
        decoder.intDecodingStrategy = .rounding(rule: .toNearestOrAwayFromZero)

        #expect(
            try decoder.decode(UInt16.self, from: 10.0) == 10
        )
        #expect(
            try decoder.decode(UInt16.self, from: 10.00001) == 10
        )
        #expect(
            try decoder.decode(UInt16.self, from: 10.1) == 10
        )
        #expect(
            try decoder.decode(UInt16.self, from: 10.5) == 11
        )
        #expect(
            try decoder.decode(UInt16.self, from: NSNumber(10.5)) == 11
        )
        #expect(
            try decoder.decode([UInt].self, from: [10.1, 20.9, 50.00001]) == [10, 21, 50]
        )

        #expect(throws: (any Error).self) {
            try decoder.decode(UInt8.self, from: Double(Int16.max))
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(UInt8.self, from: NSNumber(value: Double(Int16.max)))
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(UInt16.self, from: Double(-1))
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(UInt16.self, from: Optional<Double>.none as Any)
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(UInt16.self, from: NSNull())
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(UInt16.self, from: Double.nan)
        }
        #expect(throws: (any Error).self) {
            try decoder.decode(UInt16.self, from: Double.infinity)
        }
    }

    @Test
    func decodes_Float() throws {
        let decoder = KeyValueDecoder()

        #expect(
            try decoder.decode(Float.self, from: 10) == 10
        )
        #expect(
            try decoder.decode(Float.self, from: -100.5) == -100.5
        )
        #expect(
            try decoder.decode(Float.self, from: UInt8.max) == 255
        )
        #expect(
            try decoder.decode(Float.self, from: UInt64.max) == Float(UInt64.max)
        )
        #expect(
            try decoder.decode(Float.self, from: NSNumber(20)) == 20
        )
        #expect(
            try decoder.decode(Float.self, from: NSNumber(value: 50.5)) == 50.5
        )
        #expect(
            try decoder.decode(Float.self, from: Decimal.pi) == Float((Decimal.pi as NSNumber).doubleValue)
        )
        #expect(
            try decoder.decode(Float.self, from: UInt.max) == Float(UInt.max)
        )
        #expect(throws: (any Error).self) {
            try decoder.decode(Float.self, from: true)
        }
    }

    @Test
    func decodes_Double() throws {
        let decoder = KeyValueDecoder()

        #expect(
            try decoder.decode(Double.self, from: 10) == 10
        )
        #expect(
            try decoder.decode(Double.self, from: -100.5) == -100.5
        )
        #expect(
            try decoder.decode(Double.self, from: UInt8.max) == 255
        )
        #expect(
            try decoder.decode(Double.self, from: UInt64.max) == Double(UInt64.max)
        )
        #expect(
            try decoder.decode(Double.self, from: NSNumber(20)) == 20
        )
        #expect(
            try decoder.decode(Double.self, from: NSNumber(value: 50.5)) == 50.5
        )
        #expect(
            try decoder.decode(Double.self, from: Decimal.pi) == (Decimal.pi as NSNumber).doubleValue
        )
        #expect(
            try decoder.decode(Double.self, from: UInt.max) == Double(UInt.max)
        )
        #expect(throws: (any Error).self) {
            try decoder.decode(Double.self, from: true)
        }
    }

    @Test
    func decodes_Decimal() throws {
        let decoder = KeyValueDecoder()

        #expect(
            try decoder.decode(Decimal.self, from: 10) == 10
        )
        #expect(
            try decoder.decode(Decimal.self, from: -100.5) == -100.5
        )
        #expect(
            try decoder.decode(Decimal.self, from: UInt8.max) == 255
        )
        #expect(
            try decoder.decode(Decimal.self, from: NSNumber(20)) == 20
        )
        #expect(
            try decoder.decode(Decimal.self, from: NSNumber(value: 50.5)) == 50.5
        )
        #expect(
            try decoder.decode(Decimal.self, from: Decimal.pi) == .pi
        )
        #expect(
            try decoder.decode(Decimal.self, from: UInt.max) == Decimal(UInt.max)
        )
        #expect(throws: (any Error).self) {
            try decoder.decode(Decimal.self, from: true)
        }
    }

    @Test
    func decodes_URL() throws {
        let decoder = KeyValueDecoder()

        #expect(
            try decoder.decode(URL.self, from: "fish.com") == URL(string: "fish.com")
        )
        #expect(
            try decoder.decode(AllTypes.self, from: ["tURL": "fish.com"]) == AllTypes(
                tURL: URL(string: "fish.com")!
            )
        )

        #expect(
            try decoder.decode(URL.self, from: "fish.com") == URL(string: "fish.com")
        )
        #expect(
            try decoder.decode(URL.self, from: URL(string: "fish.com")!) == URL(string: "fish.com")
        )

        #expect(throws: (any Error).self) {
            try decoder.decode(URL.self, from: "")
        }
    }

    @Test
    func decodes_Date() throws {
        var decoder = KeyValueDecoder()
        let referenceDate = Date(timeIntervalSinceReferenceDate: 0)

        decoder.dateDecodingStrategy = .date
        #expect(
            try decoder.decode(Date.self, from: referenceDate) == referenceDate
        )

        decoder.dateDecodingStrategy = .iso8601()
        #expect(
            try decoder.decode(Date.self, from: "2001-01-01T00:00:00Z") == referenceDate
        )
        #expect(throws: DecodingError.self) {
            try decoder.decode(Date.self, from: "2001-01-01")
        }

        decoder.dateDecodingStrategy = .iso8601(options: [.withInternetDateTime, .withFractionalSeconds])
        #expect(
            try decoder.decode(Date.self, from: "2001-01-01T00:00:00.000Z") == referenceDate
        )

        decoder.dateDecodingStrategy = .millisecondsSince1970
        #expect(
            try decoder.decode(Date.self, from: 978307200000) == referenceDate
        )

        decoder.dateDecodingStrategy = .secondsSince1970
        #expect(
            try decoder.decode(Date.self, from: 978307200) == referenceDate
        )
    }

    @Test
    func decodes_Data() throws {
        let decoder = KeyValueDecoder()

        #expect(
            try decoder.decode(Data.self, from: Data([0x01])) == Data([0x01])
        )
    }

    @Test
    func decodes_Null() throws {
        var decoder = KeyValueDecoder()
        decoder.nilDecodingStrategy = .default

        #expect(throws: (any Error).self) {
            try decoder.decode(String?.self, from: NSNull())
        }

        decoder.nilDecodingStrategy = .nsNull
        #expect(
            try decoder.decode(String?.self, from: NSNull()) == nil
        )
    }

    @Test
    func decodes_Optionals() throws {
        #expect(
            try KeyValueDecoder.decode(String?.self, from: String?.some("fish")) == "fish"
        )
        #expect(
            try KeyValueDecoder.decode(String?.self, from: String?.none) == nil
        )
        #expect(throws: (any Error).self) {
            try KeyValueDecoder.decode(String.self, from: String?.none)
        }
    }

    @Test
    func decodes_SnakeCase() throws {
        let dict: [String: Any] = [
            "first_name": "fish",
            "surname": "chips",
            "profile_url": "drop",
            "rel_nodes_link": ["ocean": ["first_name": "shrimp", "surname": "anemone"]]
        ]

        var decoder = KeyValueDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        #expect(
            try decoder.decode(SnakeNode.self, from: dict) == SnakeNode(
                firstName: "fish",
                lastName: "chips",
                profileURL: "drop",
                relNODESLink: ["ocean": SnakeNode(firstName: "shrimp", lastName: "anemone")]
            )
        )
    }

    @Test
    func decodes_NestedUnkeyed() throws {
        let decoder = KeyValueDecoder()

        #expect(
            try decoder.decode([[Seafood]].self, from: [["fish", "chips"], ["fish"]]) == [
                [.fish, .chips], [.fish]
            ]
        )
    }

    @Test
    func decodes_UnkeyedOptionals() throws {
        var decoder = KeyValueDecoder()

        decoder.nilDecodingStrategy = .removed
        #expect(
            try decoder.decode([Int?].self, from: [1, 2, 3, 4]) == [1, 2, 3, 4]
        )

        decoder.nilDecodingStrategy = .default
        #expect(
            try decoder.decode([Int?].self, from: [1, 2, Int?.none, 4]) == [1, 2, nil, 4]
        )

        decoder.nilDecodingStrategy = .stringNull
        #expect(
            try decoder.decode([Int?].self, from: [1, "$null", 3, 4] as [Any]) == [1, nil, 3, 4]
        )

        decoder.nilDecodingStrategy = .nsNull
        #expect(
            try decoder.decode([Int?].self, from: [1, 2, 3, NSNull()] as [Any]) == [1, 2, 3, nil]
        )
    }

    @Test
    func decodes_KeyedBool() throws {
        let decoder = KeyValueDecoder()

        #expect(
            try decoder.decode(AllTypes.self, from: ["tBool": true]) == AllTypes(tBool: true)
        )
        #expect(
            try decoder.decode(AllTypes.self, from: ["tBool": false]) == AllTypes(tBool: false)
        )
    }

    @Test
    func keyedContainer_Decodes_NestedKeyedContainer() throws {
        #expect(
            try KeyValueDecoder.decodeValue(from: ["id": 1, "rel": ["left": ["id": 2]]], keyedBy: Node.CodingKeys.self) { container in
                let nested = try container.nestedContainer(keyedBy: Node.RelatedKeys.self, forKey: .related)
                return try nested.decode(Node.self, forKey: .left)
            } == Node(id: 2)
        )
    }

    @Test
    func keyedContainer_Decodes_NestedUnkeyedContainer() throws {
        #expect(
            try KeyValueDecoder.decodeValue(from: ["id": 1, "desc": [["id": 2]]], keyedBy: Node.CodingKeys.self) { container in
                var nested = try container.nestedUnkeyedContainer(forKey: .descendents)
                return try nested.decode(Node.self)
            } == Node(id: 2)
        )
    }

    @Test
    func keyedContainer_ThrowsError_WhenKeyIsUknown() {
        #expect(throws: (any Error).self) {
            try KeyValueDecoder.decodeValue(from: [:], keyedBy: Seafood.CodingKeys.self) { container in
                try container.decode(Bool.self, forKey: .chips)
            }
        }
    }

    @Test
    func keyedContainer_Decodes_SuperContainer() throws {
        #expect(
            try KeyValueDecoder.decodeValue(from: ["id": 1], keyedBy: Node.CodingKeys.self) { container in
                try Node(from: container.superDecoder())
            } == Node(id: 1)
        )
    }

    @Test
    func keyedContainer_Decodes_NestedSuperContainer() throws {
        #expect(
            try KeyValueDecoder.decodeValue(from: ["id": 1], keyedBy: Node.CodingKeys.self) { container in
                try Int(from: container.superDecoder(forKey: .id))
            } == 1
        )
    }

    @Test
    func decodes_KeyedRealNumbers() throws {
        let dict = [
            "tDouble": -10,
            "tFloat": 20.5
        ]

        #expect(
            try KeyValueDecoder.decode(AllTypes.self, from: dict) == AllTypes(
                tDouble: -10,
                tFloat: 20.5
            )
        )
    }

    @Test
    func decodes_KeyedInts() throws {
        let dict = [
            "tInt": 10,
            "tInt8": -20,
            "tInt16": 30,
            "tInt32": -40,
            "tInt64": 50
        ]

        #expect(
            try KeyValueDecoder.decode(AllTypes.self, from: dict) == AllTypes(
                tInt: 10,
                tInt8: -20,
                tInt16: 30,
                tInt32: -40,
                tInt64: 50
            )
        )
    }

    @Test
    func decodes_KeyedUInts() throws {
        let dict = [
            "tUInt": 10,
            "tUInt8": 20,
            "tUInt16": 30,
            "tUInt32": 40,
            "tUInt64": 50
        ]

        #expect(
            try KeyValueDecoder.decode(AllTypes.self, from: dict) == AllTypes(
                tUInt: 10,
                tUInt8: 20,
                tUInt16: 30,
                tUInt32: 40,
                tUInt64: 50
            )
        )

        #expect(throws: (any Error).self) {
            try KeyValueDecoder.decode(AllTypes.self, from: ["tUInt": -1])
        }
    }

    @Test
    func decodes_UnkeyedInts() throws {
        #expect(
            try KeyValueDecoder.decode([Int].self, from: [-10, 20, 30, 40.0, -50.0]) == [-10, 20, 30, 40, -50]
        )
        #expect(
            try KeyValueDecoder.decode([Int8].self, from: [10, -20, 30]) == [10, -20, 30]
        )
        #expect(
            try KeyValueDecoder.decode([Int16].self, from: [10, 20, -30]) == [10, 20, -30]
        )
        #expect(
            try KeyValueDecoder.decode([Int32].self, from: [-10, 20, 30]) == [-10, 20, 30]
        )
        #expect(
            try KeyValueDecoder.decode([Int64].self, from: [10, -20, 30]) == [10, -20, 30]
        )

        #expect(
            try KeyValueDecoder.decodeUnkeyedValue(from: [10, -20, 30, -40, 50]) { unkeyed in
                try AllTypes(
                    tInt: unkeyed.decode(Int.self),
                    tInt8: unkeyed.decode(Int8.self),
                    tInt16: unkeyed.decode(Int16.self),
                    tInt32: unkeyed.decode(Int32.self),
                    tInt64: unkeyed.decode(Int64.self)
                )
            } == AllTypes(
                tInt: 10,
                tInt8: -20,
                tInt16: 30,
                tInt32: -40,
                tInt64: 50
            )
        )
    }

    @Test
    func decodes_UnkeyedDecimals() throws {
        #expect(
            try KeyValueDecoder.decode([Decimal].self, from: [Decimal(10), Double(20), Float(30), Int(10), UInt.max] as [Any]) == [
                10, 20, 30, 10, Decimal(UInt.max)
            ]
        )
    }

    @Test
    func decodes_UnkeyedBool() throws {
        #expect(
            try KeyValueDecoder.decodeUnkeyedValue(from: [true, false, false, true]) { unkeyed in
                try [
                    unkeyed.decode(Bool.self),
                    unkeyed.decode(Bool.self),
                    unkeyed.decode(Bool.self),
                    unkeyed.decode(Bool.self)
                ]
            } == [true, false, false, true]
        )
    }

    @Test
    func decodes_UnkeyedString() throws {
        #expect(
            try KeyValueDecoder.decodeUnkeyedValue(from: ["fish", "chips"]) { unkeyed in
                try [
                    unkeyed.decode(String.self),
                    unkeyed.decode(String.self)
                ]
            } == ["fish", "chips"]
        )
    }

    @Test
    func decodes_UnkeyedFloat() throws {
        #expect(
            try KeyValueDecoder.decode([Float].self, from: [Double(5.5), Float(-0.5), Int(-10), UInt64.max] as [Any]) == [
                5.5, -0.5, -10.0, Float(UInt64.max)
            ]
        )
        #expect(
            try KeyValueDecoder.decode([Double].self, from: [Double(5.5), Float(-0.5), Int(-10), UInt64.max] as [Any]) == [
                5.5, -0.5, -10.0, Double(UInt64.max)
            ]
        )

        #expect(
            try KeyValueDecoder.decodeUnkeyedValue(from: [5.5, -10]) { unkeyed in
                try AllTypes(
                    tDouble: unkeyed.decode(Double.self),
                    tFloat: unkeyed.decode(Float.self)
                )
            } == AllTypes(
                tDouble: 5.5,
                tFloat: -10.0
            )
        )
    }

    @Test
    func decodes_UnkeyedNil() throws {
        var decoder = KeyValueDecoder()
        decoder.nilDecodingStrategy = .default

        #expect(
            try KeyValueDecoder.decodeUnkeyedValue(from: [String?.none as Any, NSNull() as Any, -10 as Any]) { unkeyed in
                try [
                    unkeyed.decodeNil(),
                    unkeyed.decodeNil(),
                    unkeyed.decodeNil()
                ]
            } == [
                true, false, false
            ]
        )

        #expect(throws: (any Error).self) {
            try KeyValueDecoder.decodeUnkeyedValue(from: []) { unkeyed in
                try unkeyed.decodeNil()
            }
        }
    }

    @Test
    func decodes_UnkeyedCount() throws {
        #expect(
            try KeyValueDecoder.decodeUnkeyedValue(from: [10, 20, 30, 40, 50]) { unkeyed in
                unkeyed.count
            } == 5
        )
    }

    @Test
    func decodes_UnkeyedUInts() throws {
        #expect(
            try KeyValueDecoder.decode([UInt].self, from: [10, 20, 30, 40.0]) == [
                10, 20, 30, 40
            ]
        )
        #expect(
            try KeyValueDecoder.decode([UInt8].self, from: [10, 20, 30]) == [
                10, 20, 30
            ]
        )
        #expect(
            try KeyValueDecoder.decode([UInt16].self, from: [10, 20, 30]) == [
                10, 20, 30
            ]
        )
        #expect(
            try KeyValueDecoder.decode([UInt32].self, from: [10, 20, 30]) == [
                10, 20, 30
            ]
        )
        #expect(
            try KeyValueDecoder.decode([UInt64].self, from: [10, UInt8(20), UInt64.max] as [Any]) == [
                10, 20, .max
            ]
        )

        #expect(
            try KeyValueDecoder.decodeUnkeyedValue(from: [10, 20, 30, 40, 50]) { unkeyed in
                try AllTypes(
                    tUInt: unkeyed.decode(UInt.self),
                    tUInt8: unkeyed.decode(UInt8.self),
                    tUInt16: unkeyed.decode(UInt16.self),
                    tUInt32: unkeyed.decode(UInt32.self),
                    tUInt64: unkeyed.decode(UInt64.self)
                )
            } == AllTypes(
                tUInt: 10,
                tUInt8: 20,
                tUInt16: 30,
                tUInt32: 40,
                tUInt64: 50
            )
        )
    }

    @Test
    func unKeyedContainer_Decodes_NestedKeyedContainer() throws {
        #expect(
            try KeyValueDecoder.decodeUnkeyedValue(from: [["id": 1]]) { unkeyed in
                let nested = try unkeyed.nestedContainer(keyedBy: Node.CodingKeys.self)
                return try nested.decode(Int.self, forKey: .id)
            } == 1
        )
    }

    @Test
    func unKeyedContainer_Decodes_NestedUnkeyedContainer() throws {
        #expect(
            try KeyValueDecoder.decodeUnkeyedValue(from: [[1, 2, 3]]) { unkeyed in
                var nested = try unkeyed.nestedUnkeyedContainer()
                return try [
                    nested.decode(Int.self),
                    nested.decode(Int.self),
                    nested.decode(Int.self)
                ]
            } as [Int] == [1, 2, 3]
        )
    }

    @Test
    func unKeyedContainer_Decodes_SuperContainer() throws {
        #expect(
            try KeyValueDecoder.decodeUnkeyedValue(from: [1, 2, 3]) { unkeyed in
                let decoder = try unkeyed.superDecoder()
                var container = try decoder.unkeyedContainer()
                return try [
                    container.decode(Int.self),
                    container.decode(Int.self),
                    container.decode(Int.self)
                ]
            } as [Int] == [1, 2, 3]
        )
    }

    @Test
    func nsNumber_Int64Value() throws {
        #expect(NSNumber(10).getInt64Value() == 10)
        #expect(NSNumber(-10).getInt64Value() == -10)
        #expect(NSNumber(value: UInt8.max).getInt64Value() == Int64(UInt8.max))
        #expect(NSNumber(value: UInt16.max).getInt64Value() == Int64(UInt16.max))
        #expect(NSNumber(value: UInt32.max).getInt64Value() == Int64(UInt32.max))
        // NSNumber stores unsigned values with sign in the next largest size but 64bit is largest size.
        #expect(NSNumber(value: UInt64.max).getInt64Value() == -1)
        #expect(NSNumber(10.5).getInt64Value() == nil)
        #expect(NSNumber(true).getInt64Value() == nil)
    }

    @Test
    func nsNumber_DoubleValue() throws {
        #expect(NSNumber(10.5).getDoubleValue() == 10.5)
        #expect(NSNumber(value: Float(20)).getDoubleValue() == 20)
        #expect(NSNumber(value: CGFloat(30.5)).getDoubleValue() == 30.5)
        #expect(NSNumber(value: Float(40.5)).getDoubleValue() == 40.5)
        #expect(NSNumber(value: Double.pi).getDoubleValue() == .pi)
        #expect(NSNumber(-10).getDoubleValue() == nil)
        #expect(NSNumber(true).getDoubleValue() == nil)
        #expect((true as NSNumber).getDoubleValue() == nil)
    }

#if compiler(>=6.1)
    @Test()
    func decodingErrors() throws {

        var error = #expect(throws: DecodingError.self) {
            try KeyValueDecoder.decode(Seafood.self, from: 10)
        }
        #expect(error?.debugDescription == "Expected String at SELF, found Int")

        error = #expect(throws: DecodingError.self) {
            try KeyValueDecoder.decode(Seafood.self, from: 10)
        }
        #expect(error?.debugDescription == "Expected String at SELF, found Int")

        error = #expect(throws: DecodingError.self) {
            try KeyValueDecoder.decode(Int.self, from: NSNull())
        }
        #expect(error?.debugDescription == "Expected BinaryInteger at SELF, found NSNull")

        error = #expect(throws: DecodingError.self) {
            try KeyValueDecoder.decode(Int.self, from: Optional<Int>.none)
        }
        #expect(error?.debugDescription == "Expected BinaryInteger at SELF, found nil")

        error = #expect(throws: DecodingError.self) {
            try KeyValueDecoder.decode([Int].self, from: [0, 1, true] as [Any])
        }
        #expect(error?.debugDescription == "Expected BinaryInteger at SELF[2], found Bool")

        error = #expect(throws: DecodingError.self) {
            try KeyValueDecoder.decode(AllTypes.self, from: ["tArray": [["tString": 0]]] as [String: Any])
        }
        #expect(error?.debugDescription == "Expected String at SELF.tArray[0].tString, found Int")

        error = #expect(throws: DecodingError.self) {
            try KeyValueDecoder.decode(AllTypes.self, from: ["tArray": [["tString": 0]]] as [String: Any])
        }
        #expect(error?.debugDescription == "Expected String at SELF.tArray[0].tString, found Int")
    }
#else
    @Test()
    func decodingErrors() throws {
        expectDecodingError(try KeyValueDecoder.decode(Seafood.self, from: 10)) { error in
            #expect(error.debugDescription == "Expected String at SELF, found Int")
        }
        expectDecodingError(try KeyValueDecoder.decode(Int.self, from: NSNull())) { error in
            #expect(error.debugDescription == "Expected BinaryInteger at SELF, found NSNull")
        }
        expectDecodingError(try KeyValueDecoder.decode(Int.self, from: Optional<Int>.none)) { error in
            #expect(error.debugDescription == "Expected BinaryInteger at SELF, found nil")
        }
        expectDecodingError(try KeyValueDecoder.decode([Int].self, from: [0, 1, true] as [Any])) { error in
            #expect(error.debugDescription == "Expected BinaryInteger at SELF[2], found Bool")
        }
        expectDecodingError(try KeyValueDecoder.decode(AllTypes.self, from: ["tArray": [["tString": 0]]] as [String: Any])) { error in
            #expect(error.debugDescription == "Expected String at SELF.tArray[0].tString, found Int")
        }
        expectDecodingError(try KeyValueDecoder.decode(AllTypes.self, from: ["tArray": [["tString": 0]]] as [String: Any])) { error in
            #expect(error.debugDescription == "Expected String at SELF.tArray[0].tString, found Int")
        }
    }
#endif

    @Test
    func int_ClampsDoubles() {
        #expect(
            Int8(from: 1000.0, using: .clamping(roundingRule: nil)) == Int8.max
        )
        #expect(
            Int8(from: -1000.0, using: .clamping(roundingRule: nil)) == Int8.min
        )
        #expect(
            Int8(from: 100.0, using: .clamping(roundingRule: nil)) == 100
        )
        #expect(
            Int8(from: 100.5, using: .clamping(roundingRule: .toNearestOrAwayFromZero)) == 101
        )
        #expect(
            Int8(from: Double.infinity, using: .clamping(roundingRule: .toNearestOrAwayFromZero)) == Int8.max
        )
        #expect(
            Int8(from: -Double.infinity, using: .clamping(roundingRule: .toNearestOrAwayFromZero)) == Int8.min
        )
        #expect(
            Int8(from: Double.nan, using: .clamping(roundingRule: nil)) == nil
        )
    }

    @Test
    func uInt_ClampsDoubles() throws {
        #expect(
            UInt8(from: 1000.0, using: .clamping(roundingRule: nil)) == UInt8.max
        )
        #expect(
            UInt8(from: -1000.0, using: .clamping(roundingRule: nil)) == UInt8.min
        )
        #expect(
            UInt8(from: 100.0, using: .clamping(roundingRule: nil)) == 100
        )
        #expect(
            UInt8(from: 100.5, using: .clamping(roundingRule: .toNearestOrAwayFromZero)) == 101
        )
        #expect(
            UInt8(from: Double.infinity, using: .clamping(roundingRule: .toNearestOrAwayFromZero)) == UInt8.max
        )
        #expect(
            UInt8(from: -Double.infinity, using: .clamping(roundingRule: .toNearestOrAwayFromZero)) == UInt8.min
        )
        #expect(
            UInt8(from: Double.nan, using: .clamping(roundingRule: nil)) == nil
        )

        var decoder = KeyValueDecoder()
        decoder.intDecodingStrategy = .clamping(roundingRule: .toNearestOrAwayFromZero)
        #expect(
            try decoder.decode([Int8].self, from: [10, 20.5, 1000, -Double.infinity]) == [
                10, 21, 127, -128
            ]
        )
    }

    #if !os(WASI)
    @Test
    func plistCompatibleDecoder() throws {
        let plistAny = try PropertyListEncoder.encodeAny([1, 2, Int?.none, 4])
        #expect(
            try KeyValueDecoder.makePlistCompatible().decode([Int?].self, from: plistAny) == [1, 2, Int?.none, 4]
        )

        #expect(
            try KeyValueDecoder.makePlistCompatible().decode(String?.self, from: "$null") == nil
        )
    }

    @Test
    func jsonCompatibleDecoder() throws {
        let jsonAny = try JSONEncoder.encodeAny([1, 2, Int?.none, 4])
        #expect(
            try KeyValueDecoder.makeJSONCompatible().decode([Int?].self, from: jsonAny) == [
                1, 2, Int?.none, 4
            ]
        )
    }
    #endif
}

#if compiler(<6.1)
func expectDecodingError<T>(_ expression: @autoclosure () throws -> T,
                            file: String = #filePath,
                            line: Int = #line,
                            column: Int = #column,
                            _ errorHandler: (DecodingError) -> Void = { _ in }) {
    let location = SourceLocation(fileID: file, filePath: file, line: line, column: column)
    do {
        _ = try expression()
        Issue.record("Expected DecodingError", sourceLocation: location)
    } catch let error as DecodingError {
        errorHandler(error)
    } catch {
        Issue.record(error, "Expected DecodingError", sourceLocation: location)
    }
}
#endif

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

    static func decodeValue<K: CodingKey, T>(
        from value: [String: Any],
        keyedBy: K.Type = K.self,
        with closure: @escaping (inout KeyedDecodingContainer<K>
        ) throws -> T) throws -> T {
        let proxy = StubDecoder.Proxy { decoder in
            var container = try decoder.container(keyedBy: K.self)
            return try closure(&container)
        }

        var decoder = KeyValueDecoder()
        decoder.userInfo[.decoder] = proxy as any DecodingProxy
        _ = try decoder.decode(StubDecoder.self, from: value)
        return proxy.result!
    }

    static func decodeUnkeyedValue<T>(
        from value: [Any],
        with closure: @escaping (inout any UnkeyedDecodingContainer) throws -> T
    ) throws -> T {
        let proxy = StubDecoder.Proxy { decoder in
            var container = try decoder.unkeyedContainer()
            return try closure(&container)
        }

        var decoder = KeyValueDecoder()
        decoder.userInfo[.decoder] = proxy as any DecodingProxy
        _ = try decoder.decode(StubDecoder.self, from: value)
        return proxy.result!
    }

    static func makeJSONCompatible() -> KeyValueDecoder {
        var decoder = KeyValueDecoder()
        decoder.nilDecodingStrategy = .nsNull
        return decoder
    }
}

private extension CodingUserInfoKey {
    static let decoder = CodingUserInfoKey(rawValue: "decoder")!
}

private protocol DecodingProxy: Sendable {
    func decode(from decoder: any Decoder) throws
}

private struct StubDecoder: Decodable {

    final class Proxy<T>: @unchecked Sendable, DecodingProxy {
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
        let proxy = decoder.userInfo[.decoder] as! any DecodingProxy
        try proxy.decode(from: decoder)
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
