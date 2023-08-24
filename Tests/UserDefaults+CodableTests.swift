//
//  KeyValueDecoder.swift
//  DictionaryDecoder
//
//  Created by Simon Whitty on 23/17/2023.
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
import XCTest

#if !os(WASI)
final class UserDefaultsCodableTests: XCTestCase {

    func testEncodes_Single() {
        let defaults = UserDefaults.makeMock()

        XCTAssertNil(
            try defaults.decode(Bool.self, forKey: "flag")
        )

        XCTAssertNoThrow(
            try defaults.encode(true, forKey: "flag")
        )

        XCTAssertEqual(
            try defaults.decode(Bool.self, forKey: "flag"),
            true
        )

        XCTAssertNoThrow(
            try defaults.encode(false, forKey: "flag")
        )

        XCTAssertEqual(
            try defaults.decode(Bool.self, forKey: "flag"),
            false
        )

        defaults.removeObject(forKey: "flag")

        XCTAssertNil(
            try defaults.decode(Bool.self, forKey: "flag")
        )
    }

    func testNil_RemovesObject() {
        let defaults = UserDefaults.makeMock()
        defaults.set("fish", forKey: "food")

        XCTAssertEqual(
            try defaults.decode(Seafood.self, forKey: "food"),
            .fish
        )

        XCTAssertNoThrow(
            try defaults.encode(Seafood?.none, forKey: "food")
        )

        XCTAssertNil(
            defaults.object(forKey: "food")
        )
        XCTAssertNil(
            try defaults.decode(Seafood.self, forKey: "food")
        )
    }

    func testEncodes_RawRepresenable() {
        let defaults = UserDefaults.makeMock()

        XCTAssertNil(
            try defaults.decode(Seafood.self, forKey: "food")
        )

        XCTAssertNoThrow(
            try defaults.encode(Seafood.fish, forKey: "food")
        )

        XCTAssertEqual(
            try defaults.decode(Seafood.self, forKey: "food"),
            .fish
        )
    }

    func testEncodes_Array() {
        let defaults = UserDefaults.makeMock()

        XCTAssertNil(
            try defaults.decode([Int].self, forKey: "count")
        )

        XCTAssertNoThrow(
            try defaults.encode([1, 2, 3], forKey: "count")
        )

        XCTAssertEqual(
            try defaults.decode([Int].self, forKey: "count"),
            [1, 2, 3]
        )
    }

    func testEncodes_Ints() {
        let defaults = UserDefaults.makeMock()

        XCTAssertNil(
            try defaults.decode(AllTypes.self, forKey: "ints")
        )

        XCTAssertNoThrow(
            try defaults.encode(
                AllTypes(tInt: 1,
                         tInt8: -2,
                         tInt16: .max,
                         tInt64: .max),
                forKey: "ints")
        )

        XCTAssertEqual(
            try defaults.decode(AllTypes.self, forKey: "ints"),
            AllTypes(
                tInt: 1,
                tInt8: -2,
                tInt16: .max,
                tInt64: .max
            )
        )
    }

    func testEncodes_UInts() {
        let defaults = UserDefaults.makeMock()

        XCTAssertNil(
            try defaults.decode(AllTypes.self, forKey: "uints")
        )

        XCTAssertNoThrow(
            try defaults.encode(
                AllTypes(tUInt: 1,
                         tUInt8: 2,
                         tUInt16: .max,
                         tUInt64: 5),
                forKey: "uints")
        )

        XCTAssertEqual(
            try defaults.decode(AllTypes.self, forKey: "uints"),
            AllTypes(
                tUInt: 1,
                tUInt8: 2,
                tUInt16: .max,
                tUInt64: 5
            )
        )
    }

    func testDecodes_String() {
        let defaults = UserDefaults.makeMock()

        defaults.set("YES", forKey: "flag")
        XCTAssertEqual(
            defaults.string(forKey: "flag"),
            "YES"
        )
        XCTAssertEqual(
            try defaults.decode(String.self, forKey: "flag"),
            "YES"
        )

        #if canImport(Darwin)
        defaults.set(1, forKey: "flag")
        XCTAssertEqual(
            defaults.string(forKey: "flag"),
            "1"
        )
        XCTAssertEqual(
            try defaults.decode(String.self, forKey: "flag"),
            "1"
        )
        #endif
    }

    func testDecodes_Bool() {
        let defaults = UserDefaults.makeMock()

        defaults.set("YES", forKey: "flag")
        XCTAssertTrue(defaults.bool(forKey: "flag"))
        XCTAssertEqual(
            try defaults.decode(Bool.self, forKey: "flag"),
            true
        )

        defaults.set("NO", forKey: "flag")
        XCTAssertFalse(defaults.bool(forKey: "flag"))
        XCTAssertEqual(
            try defaults.decode(Bool.self, forKey: "flag"),
            false
        )

        defaults.set("other", forKey: "flag")
        XCTAssertFalse(defaults.bool(forKey: "flag"))
        XCTAssertEqual(
            try defaults.decode(Bool.self, forKey: "flag"),
            false
        )
    }

    func testDecodes_Integer() {
        let defaults = UserDefaults.makeMock()

        defaults.set(1, forKey: "flag")
        XCTAssertEqual(
            defaults.integer(forKey: "flag"),
            1
        )
        XCTAssertEqual(
            try defaults.decode(Int.self, forKey: "flag"),
            1
        )

        defaults.set("2", forKey: "flag")
        XCTAssertEqual(
            defaults.integer(forKey: "flag"),
            2
        )
        XCTAssertEqual(
            try defaults.decode(Int.self, forKey: "flag"),
            2
        )
    }

    func testDecodes_Double() {
        let defaults = UserDefaults.makeMock()

        defaults.set(Double(1.5), forKey: "flag")
        XCTAssertEqual(
            defaults.double(forKey: "flag"),
            1.5
        )
        XCTAssertEqual(
            try defaults.decode(Double.self, forKey: "flag"),
            1.5
        )

        defaults.set("2.5", forKey: "flag")
        XCTAssertEqual(
            defaults.double(forKey: "flag"),
            2.5
        )
        XCTAssertEqual(
            try defaults.decode(Double.self, forKey: "flag"),
            2.5
        )
    }

    func testDecodes_Float() {
        let defaults = UserDefaults.makeMock()

        defaults.set(Float(1.5), forKey: "flag")
        XCTAssertEqual(
            defaults.float(forKey: "flag"),
            1.5
        )
        XCTAssertEqual(
            try defaults.decode(Float.self, forKey: "flag"),
            1.5
        )

        defaults.set("2.5", forKey: "flag")
        XCTAssertEqual(
            defaults.float(forKey: "flag"),
            2.5
        )
        XCTAssertEqual(
            try defaults.decode(Float.self, forKey: "flag"),
            2.5
        )
    }

    func testDecodes_URL() {
        let defaults = UserDefaults.makeMock()

        defaults.set(URL(fileURLWithPath: "/fish"), forKey: "flag")
        XCTAssertEqual(
            defaults.url(forKey: "flag"),
            URL(fileURLWithPath: "/fish")
        )
        XCTAssertEqual(
            try defaults.decode(URL.self, forKey: "flag"),
            URL(fileURLWithPath: "/fish")
        )

        defaults.set("/chips", forKey: "flag")
        XCTAssertEqual(
            defaults.url(forKey: "flag"),
            URL(fileURLWithPath: "/chips")
        )
        XCTAssertEqual(
            try defaults.decode(URL.self, forKey: "flag"),
            URL(fileURLWithPath: "/chips")
        )
    }
}

private extension UserDefaults {
    static func makeMock() -> UserDefaults {
        UserDefaults().removePersistentDomain(forName: "mock")
        return UserDefaults(suiteName: "mock")!
    }
}
#endif
