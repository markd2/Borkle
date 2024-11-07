//
//  TestingUtilities.swift
//  BorkleTests
//
//  Created by markd on 11/6/24.
//  Copyright © 2024 Borkware. All rights reserved.
//

import Foundation
import Numerics

extension Double {
    /// Floating point equality to some decimal places.
    func approxEqual(_ thing2: Double) -> Bool {
        isApproximatelyEqual(to: thing2,
                             relativeTolerance: 0.0001)
    }
}

extension CGFloat {
    /// Floating point equality to some decimal places.
    func approxEqual(_ thing2: CGFloat) -> Bool {
        isApproximatelyEqual(to: thing2,
                             relativeTolerance: 0.0001)
    }
}
