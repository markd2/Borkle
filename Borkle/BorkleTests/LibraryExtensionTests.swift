import Testing

struct LibraryExtensionTests {

    @Test func stringExtensions() {
        let string = "    Stuff in the Middle      "
        #expect(string.trimmed == "Stuff in the Middle")
    }

}
