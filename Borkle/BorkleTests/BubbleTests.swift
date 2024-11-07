import Testing
@testable import Borkle

struct BubbleTests {
    var bubble: Bubble
    let defaultID = 123

    init() {
        bubble = Bubble(ID: defaultID)
    }

    @Test func emptyTextOutOfTheBox() {
        #expect(bubble.text.isEmpty)
    }

    @Test func noColorOutOfTheBox() {
        #expect(bubble.borderColor == nil)
        #expect(bubble.borderColorRGB == nil)
    }

    @Test func textChangesStick() {
        let expected = "hello"
        bubble.text = expected
        #expect(bubble.text == expected)
    }

    @Test func colorChangesStick() {
        let redRGB = RGB(red: 1.0, green: 0.0, blue: 0.0)
        bubble.borderColorRGB = redRGB
        #expect(bubble.borderColor != nil)
    }

    @Test func checkEquatable() {
        let thing1 = Bubble(ID: 123)
        let thing2 = Bubble(ID: 123)
        let differentThing = Bubble(ID: 666)

        #expect(thing1 == thing1)
        #expect(thing1 === thing1)
        #expect(thing1 == thing2)
        #expect(thing1 !== thing2)
        #expect(thing2 != differentThing)

        var hasher1 = Hasher()
        thing1.hash(into: &hasher1)
        var hasher2 = Hasher()
        thing2.hash(into: &hasher2)
        var hasher3 = Hasher()
        differentThing.hash(into: &hasher3)

        #expect(hasher1.finalize() == hasher2.finalize())
        #expect(hasher1.finalize() != hasher3.finalize())
    }

    @Test func haveDebugString() {
        bubble.text = "oopack"
        let description = bubble.debugDescription
        #expect(description.contains("\(defaultID)"))
        #expect(description.contains("oopack"))
    }

    @Test func nonEmptyStringHasNonZeroHeight() {
        bubble.text = "hello"
        
        #expect(bubble.heightForStringDrawing(width: 100) > 0)
    }

}
