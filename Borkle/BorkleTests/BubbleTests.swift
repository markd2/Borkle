import Testing
@testable import Borkle

struct BubbleTests {

    @Test func xcodeSucks() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func nonEmptyStringHasNonZeroHeight() {
        let bubble = Bubble(ID: 123)
        bubble.text = "hello"
        
        #expect(bubble.heightForStringDrawing(width: 100) < 0)
        
    }

}
