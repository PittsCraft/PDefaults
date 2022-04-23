//
//  Decodable+PDefaults.swift
//  PDefaults
//
//  Created by Pierre Mardon on 17/04/2022.
//

import Foundation

extension Decodable {
    /// `Decodable` mapping for reading from storage
    static func decodableReadMapper(_ object: Any?) -> Self? {
        guard let data = object as? Data else { return nil }
        do {
            return try JSONDecoder().decode(self, from: data)
        } catch {
            print("Couldn't decode \(String(describing: object))", error)
            // Opinionated choice to almost ignore thrown errors
            return nil
        }
    }
}
