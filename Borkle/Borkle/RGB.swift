import Foundation
import AppKit

//  fillColorRGB:
//      red: 1e+0
//      green: 9.0283e-1
//      blue: 9.76506e-1

struct RGB: Codable {
    static var white: RGB {
        return RGB(nscolor: NSColor.white)
    }

    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat

    init(red: CGFloat, green: CGFloat, blue: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init(nscolor: NSColor) {
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        
        if nscolor.colorSpace.colorSpaceModel == .rgb {
            nscolor.getRed(&red, green: &green, blue: &blue, alpha: nil)
            self.red = nscolor.redComponent
            self.green = nscolor.greenComponent
            self.blue = nscolor.blueComponent
        } else if nscolor.colorSpace.colorSpaceModel == .gray {
            self.red = nscolor.whiteComponent
            self.green = nscolor.whiteComponent
            self.blue = nscolor.whiteComponent
        } else {
            fatalError("unexpected color space model: \(nscolor.colorSpace.colorSpaceModel)")
        }
    }

    init(string: String?) {
        guard let string = string else {
            // no string, be obnoxious green
            red = 0.0; green = 1.0; blue = 0.0
            return
        }

        let chunks = string
          .split(separator: " ")
          .compactMap { String($0) }
          .compactMap { CGFloat($0) }

        guard chunks.count >= 3 else {
            // not enough chunkage, be obnoxious green
            red = 0.0; green = 1.0; blue = 0.0
            return
        }
        red = chunks[0]
        green = chunks[1]
        blue = chunks[2]
    }

    var nscolor: NSColor {
        return NSColor.colorFromRGB(self)
    }
}

extension NSColor {
    static func colorFromRGB(_ rgb: RGB) -> NSColor {
        NSColor.init(deviceRed: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1.0)
    }

    func rgbColor() -> RGB {
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0

        getRed(&red, green: &green, blue: &blue, alpha: nil)
        return RGB(red: red, green: green, blue: blue)
    }
}
