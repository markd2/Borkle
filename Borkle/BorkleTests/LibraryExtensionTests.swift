import Testing
import AppKit

struct LibraryExtensionTests {

    @Test func stringTrimming() {
        let string = "    Stuff in the Middle      "
        #expect(string.trimmed == "Stuff in the Middle")
    }
    
    @Test(arguments: [
            ("1.0", 1.0),
            ("0.0", 0.0),
            ("-0.0", -0.0),
            ("-0.0", 0.0),
            ("0.00000", 0.0),
            ("3.02", 3.02),
            ("-.23", -0.23),
            ("2837.5e-2", 28.375),
            ("0x1c.6", 28.375),
            ("3.7796484325e+2", 377.96484325) // from an actual document
          ])
    func cgfloatFromString(_ string: String, expected: CGFloat) throws {
        let value = try #require(CGFloat(string))
        #expect(value.approxEqual(expected))
    }

    @Test(arguments: [
            "hello",
            "",
            " ",
            "pi",
            "π",
            "true",
            "false",
          ])
    func cgfloatFromStringFailure(string: String) {
        #expect(CGFloat(string) == nil)
    }

    @Test(arguments: [
            0.0,
            1.5,
            377.96484325,
            -50.0,
            1234567.7654321,
            -1234567.7654321,
          ])
    func rectToRight(leftEdge: CGFloat) {
        let rect = leftEdge.rectToRight
        #expect(rect.minX.approxEqual(leftEdge))
        let bigly = CGFloat(10_000_000_000)
        #expect(rect.width > bigly)
        #expect(rect.height > bigly)
        #expect(rect.minY < -bigly)
    }

    @Test(arguments: [
            ("1.2,3.4", (1.2,  3.4)),
            ("0.0,0.0", (0.0,  0.0)),
            ("-1.2,3.4", (-1.2,  3.4)),
            ("1.2,-3.4", (1.2, -3.4)),
            ("123.45678,-3210.1321", (123.45678, -3210.1321)),
            ("1.39541796825e+3,-6.6178515625e+2", (1.39541796825e+3, -6.6178515625e+2)),
    ])
    func cgpointFromString(string: String, rawPoint: (Double, Double)) throws {
        let expected = CGPoint(x: rawPoint.0, y: rawPoint.1)
        let point = try #require(CGPoint(string))
        #expect(point.x.approxEqual(expected.x))
        #expect(point.y.approxEqual(expected.y))
    }

    @Test(arguments: [
            "splunge",
            "1.2",
            "1.2,",
            ",1.2",
            "1,2,3",
            "three",
            "three,four",
            "1.2345, 5.6789",
          ])
    func cgpointFromStringFailure(string: String) {
        #expect(CGPoint(string) == nil)
    }
}
