import Foundation

//  fillColorRGB:
//      red: 1e+0
//      green: 9.0283e-1
//      blue: 9.76506e-1

struct RGB: Codable {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat

    init(red: CGFloat, green: CGFloat, blue: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
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
}
