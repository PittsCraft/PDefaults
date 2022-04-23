//
//  Example.swift
//  PDefaults_Tests
//
//  Created by Pierre Mardon on 08/06/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import PDefaults
import Combine

struct SomeData: Codable {
    var count: Int
    var label: String
}

protocol ServiceProtocol {
    var name: String { get }
    var namePublisher: AnyPublisher<String, Never> { get }

    var array: [String] { get }
    var arrayPublisher: AnyPublisher<[String], Never> { get }

    var data: SomeData { get }
    var dataPublisher: AnyPublisher<SomeData, Never> { get }

    var optionalData: SomeData? { get }
    var optionalDataPublisher: AnyPublisher<SomeData?, Never> { get }
}

class SomeService {

    @PDefaults("user.name")
    var name = "Pitt"

    @PDefaults("user.array")
    var array: [String] = []

    @PDefaults("user.data")
    var data = SomeData(count: 0, label: "Nothing here")

    @PDefaults("user.optionaldata")
    var optionalData: SomeData? = nil
}

extension SomeService: ServiceProtocol {
    var namePublisher: AnyPublisher<String, Never> { $name }
    var arrayPublisher: AnyPublisher<[String], Never> { $array }
    var dataPublisher: AnyPublisher<SomeData, Never> { $data }
    var optionalDataPublisher: AnyPublisher<SomeData?, Never> { $optionalData }
}
