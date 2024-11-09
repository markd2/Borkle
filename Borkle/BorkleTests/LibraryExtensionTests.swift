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
        print(string, expected)
        let value = try #require(CGFloat(string))
        #expect(value.approxEqual(expected))
    }
}
