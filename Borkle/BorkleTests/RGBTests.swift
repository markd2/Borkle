import Testing
import AppKit
@testable import Borkle


struct RGBTests {

    @Test func createWithString() {
        // failure cases

        let nilString = RGB(string: nil)
        #expect(nilString == RGB.obnoxiousGreen)

        let shortString = RGB(string: "1.0 2.3")
        #expect(shortString == RGB.obnoxiousGreen)

        // success cases
        let color = RGB(string: "0.1 0.234 0.5678")
        #expect(color.red.approxEqual(0.1))
        #expect(color.green.approxEqual(0.234))
        #expect(color.blue.approxEqual(0.5678))
    }

    @Test func constants() {
        let white = RGB.white
        #expect(white.red.approxEqual(1.0))
        #expect(white.green.approxEqual(1.0))
        #expect(white.blue.approxEqual(1.0))

        let black = RGB.black
        #expect(black.red.approxEqual(0.0))
        #expect(black.green.approxEqual(0.0))
        #expect(black.blue.approxEqual(0.0))
    }

    @Test func createWithGrayModel() {
        let color = RGB(nscolor: .lightGray)
        #expect(color.red.approxEqual(0.6666))
        #expect(color.green.approxEqual(0.6666))
        #expect(color.blue.approxEqual(0.6666))
    }

    @Test func createWithRGBModel() {
        let color = RGB(nscolor: .purple)
        #expect(color.red.approxEqual(0.5))
        #expect(color.green.approxEqual(0.0))
        #expect(color.blue.approxEqual(0.5))
    }

    @Test func convertNSColorToRGB() {
        let color = NSColor.magenta
        let rgb = color.rgbColor()
        #expect(rgb.red.approxEqual(1.0))
        #expect(rgb.green.approxEqual(0.0))
        #expect(rgb.blue.approxEqual(1.0))
    }
}


extension RGB {
    static func == (thing1: RGB, thing2: RGB) -> Bool {
        thing1.red.approxEqual(thing2.red) && thing1.green.approxEqual(thing2.green) && thing1.blue.approxEqual(thing2.blue)
    }
}
