//
//  StopWatch.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2026-01-18.
//

import Foundation

struct StopWatch {
    static func measure(_ label: String, codeBlock: () -> Void) {
        let startTime = CFAbsoluteTimeGetCurrent()
        codeBlock()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("--- [\(label)] : \(timeElapsed.formatted(.number.precision(.fractionLength(6)))) sec")
    }
}
