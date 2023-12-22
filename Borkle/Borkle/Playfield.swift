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
    private var positions: [Bubble.Identifier: CGPoint] = [:]
    var widths: [Bubble.Identifier: CGFloat] = [:]

    // make optional to quiet "does not conform to De/Encodable"
    var soup: BubbleSoup? = nil
    
    /// Hook that's called when a bubble position changes, so it can be invalidated
    var invalHook: ((Bubble.Identifier) -> Void)?


    private enum CodingKeys: String, CodingKey {
        case title, description, bubbleIdentifiers
        case connections, positions, widths
    }

    init(soup: BubbleSoup) {
        self.soup = soup
    }

    func bubble(byID id: Bubble.Identifier) -> Bubble? {
        return soup?.bubble(byID: id)
    }

    func forEachBubble(_ iterator: (Bubble.Identifier) -> Void) {
        for id in bubbleIdentifiers {
            iterator(id)
        }
    }

    func connectionsForBubble(id: Bubble.Identifier) -> IndexSet {
        return connections[id] ?? IndexSet()
    }

    func isBubble(_ id: Bubble.Identifier, connectedTo otherId: Bubble.Identifier) -> Bool {
        let connected = connections[id]?.contains(otherId) ?? false
        return connected
    }

    func createNewBubble(at point: CGPoint) -> Bubble.Identifier {
        guard let bubble = soup?.create(newBubbleAt: point) else {
            fatalError("could not make a booblay")
        }
        bubbleIdentifiers += [bubble.ID]

        // TODO: pull out these defaults to somewhere else
        let actualPoint = CGPoint(x: point.x - soup!.defaultWidth / 2.0, 
                                  y: point.y - soup!.defaultHeight / 2.0)
        positions[bubble.ID] = actualPoint
        widths[bubble.ID] = soup!.defaultWidth

        return bubble.ID
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

    func addConnectionsBetween(bubbleIDs: [Bubble.Identifier], to bubbleID: Bubble.Identifier) {
        for id in bubbleIDs {
            addConnectionBetween(bubbleID: id, to: bubbleID)
        }
    }

    func rectFor(bubbleID: Bubble.Identifier) -> CGRect {
        guard let anchor = positions[bubbleID],
              let width = widths[bubbleID] else {
            print("OOPS - no bubble for \(bubbleID)")
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

    public func remove(bubbleID id: Bubble.Identifier) {
        bubbleIdentifiers.removeAll { $0 == id }
        connections.removeValue(forKey: id)
        positions.removeValue(forKey: id)
        widths.removeValue(forKey: id)
        print("REMOVING \(id)")
    }

    public func remove(bubbles: [Bubble.Identifier]) {
        // TODO: inform the soup we've removed these bubbles. 12/15/2023
        for bubbleID in bubbles {
            remove(bubbleID: bubbleID)
        }
    }

    /// Given a rectangle, return all bubbles that intersect the rect.
    public func areaTestBubbles(intersecting: CGRect) -> [Bubble.Identifier]? {

        let bubbleIDs = bubbleIdentifiers.reduce(into: []) { bubbleIDs, id in
            let rect = rectFor(bubbleID: id)
            if rect.intersects(intersecting) {
                bubbleIDs.append(id)
            }
        }

        return bubbleIDs.count == 0 ? nil : bubbleIDs as? [Bubble.Identifier]
/*
        let intersectingBubbles = bubbles.filter { $0.rect.intersects(rect) }
        let result = intersectingBubbles.count > 0 ? intersectingBubbles : nil
        return result
*/
    }

    func position(for id: Bubble.Identifier) -> CGPoint {
        guard let pos = positions[id] else {
            fatalError("unexpected missing position ID \(id)")
        }
        return pos
    }

    func move(_ bubbleID: Bubble.Identifier, to point: CGPoint) {
        // TODO: error-check getting an identifier we haven't seen yet? 12/16/23
        positions[bubbleID] = point
    }

    func disconnect(bubbles: [Bubble.Identifier], from: Bubble.Identifier) {
        for bubble in bubbles {
            connections[bubble]?.remove(from)
            connections[from]?.remove(bubble)
        }
    }
}
