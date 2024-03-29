import XCTest
@testable import Borkle

class ScappleImporterTests: XCTestCase {
    var importer: ScappleImporter!
    var bundle: Bundle!
    
    override func setUp() {
        super.setUp()
        importer = ScappleImporter()
        bundle = Bundle(for: type(of: self))
    }

    override func tearDown() {
        importer = nil
        bundle = nil
        super.tearDown()
    }

    func test_import_empty_document() throws {
        let url = try urlFor(filename: "empty")

        do {
            let bubbles = try importer.importScapple(url: url)
            XCTAssertEqual(bubbles.count, 0)
        } catch {
            XCTFail("\(error)")
        }
    }

    func test_import_single_bubble() throws {
        let url = try urlFor(filename: "bubble-with-text")

        do {
            let bubbles = try importer.importScapple(url: url)
            XCTAssertEqual(bubbles.count, 1)
            let bubble = bubbles[0]
            XCTAssertEqual(bubble.text, "Snorgle")
            XCTAssertEqual(bubble.width, 50.0)
            XCTAssertEqual(bubble.position, CGPoint(x: 296.0, y: 221.0))
        } catch {
            XCTFail("\(error)")
        }
    }

    func test_import_two_bubbles_with_connections() throws {
        let url = try urlFor(filename: "two-connected")

        do {
            let bubbles = try importer.importScapple(url: url)
            XCTAssertEqual(bubbles.count, 2)
            let b1 = bubbles[0]
            let b2 = bubbles[1]

            XCTAssertEqual(b1.text, "oop")
            XCTAssertEqual(b2.text, "ack")
            XCTAssertEqual(b1.width, 29.0)
            XCTAssertEqual(b2.width, 27.0)
            XCTAssertEqual(b1.position, CGPoint(x: 179.0, y: 197.0))
            XCTAssertEqual(b2.position, CGPoint(x: 304.0, y: 280.0))

            XCTAssertTrue(b1.isConnectedTo(b2))
            XCTAssertTrue(b2.isConnectedTo(b1))
        } catch {
            XCTFail("\(error)")
        }
    }


    // What the corresponding XML looks like
    //   <String>I seem to be a verb</String>
    //   <Formatting>
    //       <FormatRange Italic="Yes">2,4</FormatRange>
    //       <FormatRange Bold="Yes">7,2</FormatRange>
    //       <FormatRange Underline="Yes">10,2</FormatRange>
    //       <FormatRange Struckthrough="Yes">13,1</FormatRange>
    //       <FormatRange Bold="Yes" Italic="Yes">15,4</FormatRange>
    //   </Formatting>
    func test_import_single_styled_bubble() throws {
        let url = try urlFor(filename: "single-formatted")

        do {
            let bubbles = try importer.importScapple(url: url)
            XCTAssertEqual(bubbles.count, 1)
            let bubble = bubbles[0]
            XCTAssertEqual(bubble.text, "I seem to be a verb")

            XCTAssertEqual(bubble.formattingOptions.count, 5)
            
            let expectedOptions: [Bubble.FormattingOption] = [
              Bubble.FormattingOption([.italic], 2, 4),
              Bubble.FormattingOption([.bold], 7, 2),
              Bubble.FormattingOption([.underline], 10, 2),
              Bubble.FormattingOption([.strikethrough], 13, 1),
              Bubble.FormattingOption([.bold, .italic], 15, 4)
            ]
            XCTAssertEqual(bubble.formattingOptions, expectedOptions)
                               
        } catch {
            XCTFail("\(error)")
        }
    }

    // All the ranges have :alot: of overlap
    //       <Formatting>
    //           <FormatRange Italic="Yes">5,5</FormatRange>
    //           <FormatRange Italic="Yes" Struckthrough="Yes">10,5</FormatRange>
    //           <FormatRange Bold="Yes" Italic="Yes" Struckthrough="Yes">15,5</FormatRange>
    //           <FormatRange Bold="Yes" Italic="Yes" Underline="Yes" Struckthrough="Yes">20,8</FormatRange>
    //           <FormatRange Bold="Yes" Italic="Yes" Underline="Yes">28,6</FormatRange>
    //           <FormatRange Italic="Yes" Underline="Yes">34,11</FormatRange>
    //           <FormatRange Bold="Yes" Italic="Yes">45,8</FormatRange>
    //       </Formatting>
    func test_import_single_styled_bubble_with_overlapping_ranges() throws {
        let url = try urlFor(filename: "overlapping-styles")

        do {
            let bubbles = try importer.importScapple(url: url)
            XCTAssertEqual(bubbles.count, 1)
            let bubble = bubbles[0]
            XCTAssertEqual(bubble.text, "This is a very long sentence with overlapping styling")

            XCTAssertEqual(bubble.formattingOptions.count, 7)
            
            let expectedOptions: [Bubble.FormattingOption] = [
              Bubble.FormattingOption([.italic], 5, 5),
              Bubble.FormattingOption([.italic, .strikethrough], 10, 5),
              Bubble.FormattingOption([.bold, .italic, .strikethrough], 15, 5),
              Bubble.FormattingOption([.bold, .italic, .strikethrough, .underline], 20, 8),
              Bubble.FormattingOption([.bold, .italic, .underline], 28, 6),
              Bubble.FormattingOption([.italic, .underline], 34, 11),
              Bubble.FormattingOption([.bold, .italic], 45, 8)
            ]
            XCTAssertEqual(bubble.formattingOptions, expectedOptions)
                               
        } catch {
            XCTFail("\(error)")
        }
    }

    func test_import_single_with_appearance() throws {
        let url = try urlFor(filename: "single-appearance")

        do {
            let bubbles = try importer.importScapple(url: url)
            XCTAssertEqual(bubbles.count, 1)
            let bubble = bubbles[0]

            XCTAssertEqual(bubble.borderThickness, 3)
            XCTAssertTrue(try! XCTUnwrap(bubble.borderColor).sortOfEqualTo(red: 0.819, green: 0.034, blue: 0.054))
            XCTAssertTrue(try! XCTUnwrap(bubble.fillColor).sortOfEqualTo(red: 1.0, green: 0.977, blue: 0.261))

        } catch {
            XCTFail("\(error)")
        }
    }

    func test_malformed_file_throws() throws {
        let url = try urlFor(filename: "malformed")

        do {
            _ = try importer.importScapple(url: url)
            XCTFail("Expected complaint")
        } catch {
            // yay!  Right now don't really care what it is
        }
    }
}

extension ScappleImporterTests {
    func urlFor(filename: String) throws -> URL {
        let url = try XCTUnwrap(bundle.url(forResource: filename, withExtension: "scap"))
        return url
    }
}

extension NSColor {
    func sortOfEqualTo(red: CGFloat, green: CGFloat, blue: CGFloat) -> Bool {
        var minered: CGFloat = 0
        var minegreen: CGFloat = 0
        var mineblue: CGFloat = 0

        getRed(&minered, green: &minegreen, blue: &mineblue, alpha: nil)

        return abs(minered - red) < 0.001 && abs(minegreen - green) < 0.001 && abs(mineblue - blue) < 0.001
    }
}
