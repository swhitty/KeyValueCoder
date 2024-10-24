//
//  UserDefaults+CodableTests.swift
//  KeyValueCoder
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

#if canImport(Testing)
@testable import KeyValueCoder

import Foundation
import Testing

#if !os(WASI)
struct UserDefaultsCodableTests {

    @Test
    func encodes_Single() throws {
        let defaults = UserDefaults.makeMock()

        #expect(
            try defaults.decode(Bool.self, forKey: "flag") == nil
        )

        #expect(throws: Never.self) {
            try defaults.encode(true, forKey: "flag")
        }

        #expect(
            try defaults.decode(Bool.self, forKey: "flag") == true
        )

        #expect(throws: Never.self) {
            try defaults.encode(false, forKey: "flag")
        }

        #expect(
            try defaults.decode(Bool.self, forKey: "flag") == false
        )

        defaults.removeObject(forKey: "flag")

        #expect(
            try defaults.decode(Bool.self, forKey: "flag") == nil
        )
    }

    @Test
    func nil_RemovesObject() throws {
        let defaults = UserDefaults.makeMock()
        defaults.set("fish", forKey: "food")

        #expect(
            try defaults.decode(Seafood.self, forKey: "food") == .fish
        )

        #expect(throws: Never.self) {
            try defaults.encode(Seafood?.none, forKey: "food")
        }

        #expect(
            defaults.object(forKey: "food") == nil
        )
        #expect(
            try defaults.decode(Seafood.self, forKey: "food") == nil
        )
    }

    @Test
    func encodes_RawRepresenable() throws {
        let defaults = UserDefaults.makeMock()

        #expect(
            try defaults.decode(Seafood.self, forKey: "food") == nil
        )

        #expect(throws: Never.self) {
            try defaults.encode(Seafood.fish, forKey: "food")
        }

        #expect(
            try defaults.decode(Seafood.self, forKey: "food") == .fish
        )
    }

    @Test
    func encodes_Array() throws {
        let defaults = UserDefaults.makeMock()

        #expect(
            try defaults.decode([Int].self, forKey: "count") == nil
        )

        #expect(throws: Never.self) {
            try defaults.encode([1, 2, 3], forKey: "count")
        }

        #expect(
            try defaults.decode([Int].self, forKey: "count") ==  [1, 2, 3]
        )
    }

    @Test
    func encodes_Ints() throws {
        let defaults = UserDefaults.makeMock()

        #expect(
            try defaults.decode(AllTypes.self, forKey: "ints") == nil
        )

        #expect(throws: Never.self) {
            try defaults.encode(
                AllTypes(tInt: 1,
                         tInt8: -2,
                         tInt16: .max,
                         tInt64: .max),
                forKey: "ints")
        }

        #expect(
            try defaults.decode(AllTypes.self, forKey: "ints") == AllTypes(
                tInt: 1,
                tInt8: -2,
                tInt16: .max,
                tInt64: .max
            )
        )
    }

    @Test
    func encodes_UInts() throws {
        let defaults = UserDefaults.makeMock()

        #expect(
            try defaults.decode(AllTypes.self, forKey: "uints") == nil
        )

        #expect(throws: Never.self) {
            try defaults.encode(
                AllTypes(tUInt: 1,
                         tUInt8: 2,
                         tUInt16: .max,
                         tUInt64: 5),
                forKey: "uints")
        }

        #expect(
            try defaults.decode(AllTypes.self, forKey: "uints") == AllTypes(
                tUInt: 1,
                tUInt8: 2,
                tUInt16: .max,
                tUInt64: 5
            )
        )
    }

    @Test
    func decodes_String() throws {
        let defaults = UserDefaults.makeMock()

        defaults.set("YES", forKey: "flag")
        #expect(
            defaults.string(forKey: "flag") == "YES"
        )
        #expect(
            try defaults.decode(String.self, forKey: "flag") == "YES"
        )

        #if canImport(Darwin)
        defaults.set(1, forKey: "flag")
        #expect(
            defaults.string(forKey: "flag") == "1"
        )
        #expect(
            try defaults.decode(String.self, forKey: "flag") == "1"
        )
        #endif
    }

    @Test
    func decodes_Bool() throws {
        let defaults = UserDefaults.makeMock()

        defaults.set("YES", forKey: "flag")
        #expect(defaults.bool(forKey: "flag"))
        #expect(
            try defaults.decode(Bool.self, forKey: "flag") == true
        )

        defaults.set("NO", forKey: "flag")
        #expect(!defaults.bool(forKey: "flag"))
        #expect(
            try defaults.decode(Bool.self, forKey: "flag") == false
        )

        defaults.set("other", forKey: "flag")
        #expect(!defaults.bool(forKey: "flag"))
        #expect(
            try defaults.decode(Bool.self, forKey: "flag") == false
        )
    }

    @Test
    func decodes_Integer() throws {
        let defaults = UserDefaults.makeMock()

        defaults.set(1, forKey: "flag")
        #expect(
            defaults.integer(forKey: "flag") == 1
        )
        #expect(
            try defaults.decode(Int.self, forKey: "flag") == 1
        )

        defaults.set("2", forKey: "flag")
        #expect(
            defaults.integer(forKey: "flag") == 2
        )
        #expect(
            try defaults.decode(Int.self, forKey: "flag") == 2
        )
    }

    @Test
    func decodes_Double() throws {
        let defaults = UserDefaults.makeMock()

        defaults.set(Double(1.5), forKey: "flag")
        #expect(
            defaults.double(forKey: "flag") == 1.5
        )
        #expect(
            try defaults.decode(Double.self, forKey: "flag") == 1.5
        )

        defaults.set("2.5", forKey: "flag")
        #expect(
            defaults.double(forKey: "flag") == 2.5
        )
        #expect(
            try defaults.decode(Double.self, forKey: "flag") == 2.5
        )
    }

    @Test
    func decodes_Float() throws {
        let defaults = UserDefaults.makeMock()

        defaults.set(Float(1.5), forKey: "flag")
        #expect(
            defaults.float(forKey: "flag") == 1.5
        )
        #expect(
            try defaults.decode(Float.self, forKey: "flag") == 1.5
        )

        defaults.set("2.5", forKey: "flag")
        #expect(
            defaults.float(forKey: "flag") == 2.5
        )
        #expect(
            try defaults.decode(Float.self, forKey: "flag") == 2.5
        )
    }

    @Test
    func decodes_URL() throws {
        let defaults = UserDefaults.makeMock()

        defaults.set(URL(fileURLWithPath: "/fish"), forKey: "flag")
        #expect(
            defaults.url(forKey: "flag") == URL(fileURLWithPath: "/fish")
        )
        #expect(
            try defaults.decode(URL.self, forKey: "flag") == URL(fileURLWithPath: "/fish")
        )

        defaults.set("/chips", forKey: "flag")
        #expect(
            defaults.url(forKey: "flag") == URL(fileURLWithPath: "/chips")
        )
        #expect(
            try defaults.decode(URL.self, forKey: "flag") == URL(fileURLWithPath: "/chips")
        )
    }
}

private extension UserDefaults {
    static func makeMock(function: String = #function) -> UserDefaults {
        UserDefaults().removePersistentDomain(forName: function)
        return UserDefaults(suiteName: function)!
    }
}
#endif
#endif
