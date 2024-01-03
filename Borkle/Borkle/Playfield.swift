import Foundation
import AppKit

class PlayfieldResponder: NSResponder, NSMenuItemValidation {
    weak var playfield: Playfield?

    init(playfield: Playfield) {
        self.playfield = playfield
        super.init()
        playfield.responder = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var acceptsFirstResponder: Bool { true }
    override func becomeFirstResponder() -> Bool {
        return true
    }

    override func selectAll(_ sender: Any?) {
        playfield?.selectAll()
    }
    @IBAction func expandSelection(_ sender: Any) {
        playfield?.expandSelection()
    }
    @IBAction func expandComponent(_ sender: Any) {
        playfield?.expandComponent()
    }
    @IBAction func shrinkBubble(_ sender: Any) {
        playfield?.shrinkBubbles()
    }
    @IBAction func embiggenBubble(_ sender: Any) {
        playfield?.embiggenBubbles()
    }
    @IBAction func exportPDF(_ sender: Any) {
        playfield?.exportPDF()
    }
    @IBAction func importScapple(_ sender: Any) {
    }
    @IBAction func paste(_ sender: Any) {
        playfield?.paste()
    }
    @IBAction func colorBubbles(_ sender: Any) {
        guard let db = (sender as? DumbButton) else { return }
        playfield?.colorBubbles(db.color)
    }
    @IBAction func resetZoom(_ sender: Any) {
        playfield?.resetZoom()
    }
    @IBAction func incZoom(_ sender: Any) {
        playfield?.incZoom()
    }
    @IBAction func decZoom(_ sender: Any) {
        playfield?.decZoom()
    }

    @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let playfield else { return false }
        
        switch menuItem.action {
        case #selector(selectAll(_:)):
            return playfield.bubbleIdentifiers.count > 0
        case #selector(expandSelection(_:)):
            return playfield.selectedBubbles.bubbleCount > 0
        case #selector(expandComponent(_:)):
            return playfield.selectedBubbles.bubbleCount > 0
        case #selector(shrinkBubble(_:)):
            return playfield.selectedBubbles.bubbleCount > 0
        case #selector(embiggenBubble(_:)):
            return playfield.selectedBubbles.bubbleCount > 0
        case #selector(exportPDF(_:)):
            return true
        case #selector(importScapple(_:)):
            return true
        case #selector(paste(_:)):
            return playfield.canPaste()
        default:
            break
        }
        return menuItem.isEnabled
    }

}

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
    // to keep it alive
    var responder: PlayfieldResponder?
    weak var canvas: BubbleCanvas? // for PDF export

    var title: String = "Untitled"
    var description: String = ""

    var bubbleIdentifiers: [Bubble.Identifier] = []

    var connections: [Bubble.Identifier: IndexSet] = [:]
    private var positions: [Bubble.Identifier: CGPoint] = [:]
    var widths: [Bubble.Identifier: CGFloat] = [:]

    // make optional to quiet "does not conform to De/Encodable"
    private var soup: BubbleSoup? = nil {
        didSet {
        }
    }
    
    /// Hook that's called when a bubble position changes, so it can be invalidated
    var invalHook: ((Bubble.Identifier) -> Void)?

    var selectedBubbles = Selection()

    private enum CodingKeys: String, CodingKey {
        case title, description, bubbleIdentifiers
        case connections, positions, widths
    }

    init(soup: BubbleSoup) {
        self.soup = soup

        soup.addChangeHook { [weak self] in
            self?.canvas?.invalidate()
        }
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

    func migrateSomeFrom(bubbles: [Bubble]) {
        let halfBubbles = bubbles.filter { _ in Bool.random() }
        

        let width: CGFloat = 90
        let height: CGFloat = 80
        let maxWidth: CGFloat = 250
        var x: CGFloat = 19
        var y: CGFloat = 10

        var ids = Set<Bubble.Identifier>() 

        for bubble in halfBubbles {
            let id = bubble.ID
            bubbleIdentifiers.append(id)

            x += width + 10
            if x > maxWidth { x = 10; y += height }

            let position = CGPoint(x: x, y: y)
            positions[id] = position
            widths[id] = width

            ids.insert(id)
        }

        for _ in 0 ..< (halfBubbles.count / 2) {
            let a = ids.randomElement()!
            let b = ids.randomElement()!

            addConnectionBetween(bubbleID: a, to: b)
            addConnectionBetween(bubbleID: b, to: a)
        }

    }

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
            addConnectionBetween(bubbleID: bubbleID, to: id)
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
        let rect = CGRect(x: point.x, y: point.y, width: 1.0, height: 1.0)
        let bubbles = areaTestBubbles(intersecting: rect)
        return bubbles?.last
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

    func setBubbleText(bubbleID: Bubble.Identifier, text: String) {
        soup?.bubble(byID: bubbleID)?.text = text
        soup?.bubbleChanged(bubbleID)
    }
}

extension Playfield {
    func selectAll() {
        selectedBubbles.select(bubbles: bubbleIdentifiers)
    }

    func expandSelection() {
        // !!! this is O(N^2).  May need to have a lookup by ID?
        // !!! of course, wait until we see it appear in instruments
        selectedBubbles.forEachBubble { id in
            connections[id]?.forEach { connection in
                selectedBubbles.select(bubble: connection)
            }
        }
    }

    func expandComponent() {
        var lastSelectionCount = selectedBubbles.bubbleCount
        
        while true {
            expandSelection()
            if lastSelectionCount == selectedBubbles.bubbleCount {
                break
            }
            lastSelectionCount = selectedBubbles.bubbleCount
        }
    }

    func shrinkBubbles() {
        selectedBubbles.forEachBubble { id in
            guard let width = widths[id] else {
                fatalError("unexpectedly missing width for id \(id)")
            }
            let newWidth = width - 10
            if newWidth > 10 {
                // TODO make this undoable
                widths[id] = newWidth
                invalHook?(id)
            }
        } 
    }

    func embiggenBubbles() {
        selectedBubbles.forEachBubble { id in
            guard let width = widths[id] else {
                fatalError("unexpectedly missing width for id \(id)")
            }
            let newWidth = width + 10
            if newWidth > 10 {
                // TODO make this undoable
                widths[id] = newWidth
                invalHook?(id)
            }
        } 
    }

    func exportPDF() {
        guard let canvas else {
            fatalError("no canvas during pdf export")
        }
        
        Swift.print("saved to Desktop directory as _borkle.pdf_")
        let data = canvas.dataWithPDF(inside: canvas.bounds)
        let url = Document.userDesktopURL().appendingPathComponent("borkle.pdf")
        try! data.write(to: url)
    }


    func canPaste() -> Bool {
        // need a point to paste at
        guard let _ = canvas?.lastPoint else {
            return false
        }

        // and need something on the pasteboard to paste
        let pasteboard = NSPasteboard.general
        let types = pasteboard.availableType(from: [.string])
        return types != nil
    }

    func paste() {
        let pasteboard = NSPasteboard.general
        guard let string = pasteboard.string(forType: .string),
              let canvas, let soup,
              var point = canvas.lastPoint else {
            return
        }
        var startPoint = point

        point.x += soup.defaultWidth / 2.0

        let bubbleID = createNewBubble(at: point)
        guard let bubble = soup.bubble(byID: bubbleID) else {
            fatalError("soup can't find a bubble it just created - ID \(bubbleID)")
        }
        bubble.text = string
        invalHook?(bubbleID)

        // Change the start point so that multiple pastes get
        // offset.
        startPoint.x += 30
        startPoint.y += 30
        canvas.lastPoint = startPoint
        
        Swift.print(bubble.text)
    }

    func colorBubbles(_ color: NSColor) {
        Swift.print("need to make color changing undoable")
        selectedBubbles.forEachBubble { bubbleID in
            guard let bubble = soup!.bubble(byID: bubbleID) else {
                fatalError("soup can't find a bubble for colirizing \(bubbleID)")
            }     
            bubble.fillColor = color
            invalHook?(bubbleID)
        }        
    }

    func resetZoom() {
        canvas?.scroller?.magnification = 1.0
    }

    func incZoom() {
        canvas?.scroller?.magnification += 0.1
    }

    func decZoom() {
        canvas?.scroller?.magnification -= 0.1
    }

}
