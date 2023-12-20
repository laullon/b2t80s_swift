//
//  Machine.swift
//  b2t80s
//
//  Created by German Laullon on 7/12/23.
//

import Foundation

enum Status {
    case paused, error, runing
}


@MainActor
protocol Machine: ObservableObject {
    var status: Status { get }
    var registersData: RegistersData { get }

    func start(fast: Bool) async
    func step() async
    func stop()
    func reset() async
}
