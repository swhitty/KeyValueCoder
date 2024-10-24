//
//  UserDefaults+Codable.swift
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

import Foundation

#if !os(WASI)
public extension UserDefaults {

    func encode<T: Encodable>(_ value: T, forKey key: String) throws {
        let encoder = KeyValueEncoder.makePlistCompatible()
        let encoded = try encoder.encode(value)
        if encoder.nilEncodingStrategy.isNull(encoded) {
            removeObject(forKey: key)
        } else {
            set(encoded, forKey: key)
        }
    }

    func decode<T: Decodable>(_ type: T.Type = T.self, forKey key: String) throws -> T? {
        guard let storage = object(forKey: key) else { return nil }
        switch type {
        case is String.Type: return string(forKey: key) as? T
        case is Bool.Type: return bool(forKey: key) as? T
        case is Int.Type: return integer(forKey: key) as? T
        case is Double.Type: return double(forKey: key) as? T
        case is Float.Type: return float(forKey: key) as? T
        case is URL.Type: return url(forKey: key) as? T
        default: return try KeyValueDecoder.makePlistCompatible().decode(type, from: storage)
        }
    }
}
#endif
