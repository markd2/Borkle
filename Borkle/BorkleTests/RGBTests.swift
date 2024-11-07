import Testing
@testable import Borkle


struct RGBTests {

    @Test func createWithGrayModel() {
        let color = RGB(nscolor: .lightGray)
        #expect(color.red.approxEqual(0.6666))
        #expect(color.green.approxEqual(0.6666))
        #expect(color.blue.approxEqual(0.6666))
    }

}
