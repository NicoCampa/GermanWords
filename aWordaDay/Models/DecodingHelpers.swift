//
//  DecodingHelpers.swift
//  aWordaDay
//
//  Extracted from Item.swift
//

import Foundation

extension String {
    var trimmedIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

extension KeyedDecodingContainer {
    func decodeFlexibleString(forKey key: Key) throws -> String {
        if let value = try? decode(String.self, forKey: key) {
            return value
        }
        if let array = try? decode([String].self, forKey: key), let first = array.first {
            return first
        }
        if let boolValue = try? decode(Bool.self, forKey: key) {
            return boolValue ? "true" : "false"
        }
        throw DecodingError.typeMismatch(
            String.self,
            DecodingError.Context(
                codingPath: codingPath + [key],
                debugDescription: "Expected String, Bool, or single-value String array."
            )
        )
    }

    func decodeFlexibleStringIfPresent(forKey key: Key) -> String? {
        guard contains(key) else { return nil }
        return try? decodeFlexibleString(forKey: key)
    }

    func decodeFlexibleBoolIfPresent(forKey key: Key) -> Bool? {
        if let value = try? decode(Bool.self, forKey: key) {
            return value
        }
        if let array = try? decode([Bool].self, forKey: key) {
            return array.first
        }
        return nil
    }
}
