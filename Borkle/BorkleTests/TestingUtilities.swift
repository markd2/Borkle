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
