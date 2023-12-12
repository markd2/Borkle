import Foundation

/// Playfields are the worksheets for Borkle.  A canvas (will eventually)
/// be driven by a single playfield. The user can have as many playfields
/// as they want.
///
/// Bubble contents are global (change in one, it's reflected elsewhere),
/// but things like location, size, and connections, are part of the
/// playfield.
///
/// Right now formatting (text formatting, bubble color) are still bubble attributes.
///
class Playfield: Codable {
    var title: String = "Untitled"
    var description: String = ""

    var bubbleIdentifiers: [Bubble.Identifier] = []

    var connections: [Bubble.Identifier: IndexSet] = [:]
    var positions: [Bubble.Identifier: CGPoint] = [:]
    var widths: [Bubble.Identifier: CGFloat] = [:]
}
