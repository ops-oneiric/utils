//
//  Utils.swift
//
//

import Foundation

typealias DataType = Codable & Hashable

/* data */

typealias IOEnum = DataType & CaseIterable

/* property wrappers */

@propertyWrapper
struct JSONData<Model> where Model: Decodable {
    let wrappedValue: Model
    init(_ bundleResource: String) {
        let decoder = JSONDecoder()
        let data = try! Data(
            contentsOf: Bundle.main.url(forResource: bundleResource, withExtension: nil)!
        )
        wrappedValue = try! decoder.decode(Model.self, from: data)
    }
}

@propertyWrapper
struct Preference<Value> where Value: Codable {
    var wrappedValue: Codable {
        didSet {
            UserDefaults.standard.setValue(wrappedValue, forKey: key)
        }
    }
    let key: String
    init(_ key: String, default: Value) {
        self.key = key
        if let storedValue = UserDefaults.standard.value(forKey: key) as? Value {
            self.wrappedValue = storedValue
        } else {
            self.wrappedValue = `default`
        }
    }
}

/* extensions */

extension Array {
    var indexRange: Range<Self.Index> {
        return startIndex..<endIndex
    }
}

extension Array where Self.Element: Hashable {
    func excludingDuplicates() -> Self {
        return Self(Set(self))
    }
}

extension String {
    func with(letterSpacing: Int) -> Self {
        guard !self.isEmpty else { return self }
        var copy = ""
        for character in self {
            copy.append(character)
            guard character != " " else { continue }
            guard character != "\n" else { continue }
            for _ in 0..<(letterSpacing+1) {
                copy.append(" ")
            }
        }
        copy.removeLast()
        return copy
    }
}
