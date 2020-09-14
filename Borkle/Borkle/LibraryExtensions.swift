import Foundation

extension String {
    /// Returns a version of the string trimmed (off the ends) of whitespace
    var trimmed: String {
        let trimmedString = self.trimmingCharacters(in: .whitespaces)
        return trimmedString
    }
}


extension CGFloat {
    /// Make a new CGFloat with the given string, in the same manner as `Double(string)`
    init?(_ string: String) {
        if let double = Double(string) {
            self.init(double)
        } else {
            return nil
        }
    }
}

extension CGPoint {
    /// Make a new CGFloat with the given string, in the same manner as `Double(string)`
    /// Takes a string of the format "3.1415,2.718"
    init?(_ string: String) {
        let components = string.split(separator: ",").map { String($0) }
        if components.count != 2 { return nil }
        
        if let x = CGFloat(components[0]), let y = CGFloat(components[1]) {
            self.init(x: x, y: y)
        } else {
            return nil
        }
    }

    static public func - (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: right.x - left.x, y: right.y - left.y)
    }

    static public func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
}


extension CGRect {
    /// Returns the center point of the rectangle
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }

    static public func + (left: CGRect, right: CGSize) -> CGRect {
        let rect = CGRect(x: left.minX, y: left.minY,
            width: left.width + right.width,
            height: left.height + right.height)
        return rect
    }
}


extension IndexSet {
    /// Given a string of the form  "76, 78-81, 83, 91, 142-143, 162, 171", turn that into
    /// an index set.  Hypenated ranges are inclusive.
    static func setFromString(_ string: String) -> IndexSet {
        var indexSet = Self()

        let components = string.split(separator: ",").map { String($0).trimmed }

        for component in components {
            let innerComponents = component.split(separator: "-").map { String($0).trimmed }
            if innerComponents.count == 1 {
                if let value = Int(component) {
                    indexSet.update(with: value)
                }
            } else if innerComponents.count == 2 {
                if let firstValue = Int(innerComponents[0]),
                   let secondValue = Int(innerComponents[1]) {
                    indexSet.insert(integersIn: firstValue ... secondValue)
                }
            } else {
                Swift.print("Unexpected multiple (or zero) components from \(component)")
            }
        }
        return indexSet
    }

    /// Given a string of the form  "76, 78-81, 83, 91, 142-143, 162, 171", turn that into
    /// an index set.  Hypenated ranges are inclusive.
    init?(_ string: String) {
        self = Self.setFromString(string)
    }
}


extension FileWrapper {
    func remove(filename: String) {
        if let fileWrapper = fileWrappers?[filename] {
            removeFileWrapper(fileWrapper)
        }
    }
}
