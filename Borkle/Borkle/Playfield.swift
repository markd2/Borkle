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

    // make optional to quiet "does not conform to De/Encodable"
    var soup: BubbleSoup? = nil

    private enum CodingKeys: String, CodingKey {
        case title, description, bubbleIdentifiers
        case connections, positions, widths
    }

    init(soup: BubbleSoup) {
        self.soup = soup
    }

    func forEachBubble(_ iterator: (Bubble.Identifier) -> Void) {
        for id in bubbleIdentifiers {
            iterator(id)
        }
    }

    func connectionsForBubble(id: Bubble.Identifier) -> IndexSet {
        return connections[id] ?? IndexSet()
    }

    // Alpha Thought...
    var bubbles: [Bubble] = []

    func migrateFrom(bubbles: [Bubble]) {
        for bubble in bubbles {
            let id = bubble.ID

            bubbleIdentifiers.append(id)
            
            let position = bubble.position
            positions[id] = position
            
            let width = bubble.width
            widths[id] = width
            
            // assume that all the connections are bidi
            bubble.forEachConnection { otherId in
                addConnectionBetween(bubbleID: id, to: otherId)
                addConnectionBetween(bubbleID: otherId, to: id)
            }
        }
        self.bubbles = bubbles
    }

    func addConnectionBetween(bubbleID: Bubble.Identifier,
                              to toBubbleID: Bubble.Identifier) {
        var indexSet = connections[bubbleID, default: IndexSet()]
        indexSet.insert(toBubbleID)
        connections[bubbleID] = indexSet
    }

    func rectFor(bubbleID: Bubble.Identifier) -> CGRect {
        guard let anchor = positions[bubbleID],
              let width = widths[bubbleID] else {
            fatalError("did not find anchor or width for \(bubbleID)")
        }

        guard let bubble = soup?.bubble(byID: bubbleID) else {
            fatalError("unknown bubble ID \(bubbleID)")
        }
        
        let effectiveHeight = bubble.heightForStringDrawing(width: width)

        var rect = CGRect(x: anchor.x, y: anchor.y,
                          width: width, height: effectiveHeight)

        rect.size.height += 2 * Bubble.margin

        return rect
    }

    var enclosingRect: CGRect {
        let union = bubbleIdentifiers.reduce(into: CGRect.zero) { union, id in
            union = union.union(rectFor(bubbleID: id))
        }
        return union
    }

    /// Given a point, find the first bubble that intersects it.
    /// Drawing happens front->back, so hit testing happens back->front
    public func hitTestBubble(at point: CGPoint) -> Bubble.Identifier? {
        let bubble = bubbles.last(where: { $0.rect.contains(point) })
        return bubble?.ID
    }
}
