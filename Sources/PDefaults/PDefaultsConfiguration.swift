//
//  PDefaultsConfiguration.swift
//  
//
//  Created by Pierre Mardon on 28/06/2023.
//

import Foundation

/// Global configuration of PDefaults instances
public struct PDefaultsConfiguration {

    /// Whether all instances should be mocked or not.
    ///
    /// This flag should be set before any wrapped value or projected value access
    public static var mock = false
}
