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
}

private extension UserDefaults {
    static func makeMock() -> UserDefaults {
        UserDefaults().removePersistentDomain(forName: "mock")
        return UserDefaults(suiteName: "mock")!
    }
}
