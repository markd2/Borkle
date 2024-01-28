import Foundation
import AppKit


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

    // make optional to quiet "does not conform to De/Encodable"
    var undoManager: UndoManager!

    var title: String = "Untitled"
    var description: String = ""

    var bubbleIdentifiers: [Bubble.Identifier] = []

    var connections: [Bubble.Identifier: IndexSet] = [:]
    private var positions: [Bubble.Identifier: CGPoint] = [:]
    let defaultWidth: CGFloat = 150
    var widths: [Bubble.Identifier: CGFloat] = [:]
    var colors: [Bubble.Identifier: RGB?] = [:]

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

    init(soup: BubbleSoup, undoManager: UndoManager) {
        self.soup = soup
        self.undoManager = undoManager

        soup.addChangeHook { [weak self] in
            self?.canvas?.invalidate()
        }
    }

    func bubble(byID id: Bubble.Identifier) -> Bubble? {
        guard bubbleIdentifiers.contains(id) else {
            fatalError("asking playfield for a bubble it doesn't have")
        }
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

    func addBubble(_ bubble: Bubble) {
        bubbleIdentifiers.append(bubble.ID)
        positions[bubble.ID] = CGPointZero
        widths[bubble.ID] = defaultWidth
        colors[bubble.ID] = RGB.white
    }

    func createNewBubble(at point: CGPoint) -> Bubble.Identifier {
        guard let bubble = soup?.createNewBubble() else {
            fatalError("no soup for us")
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
            
            colors[id] = RGB(nscolor: .white)
            
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

    private func addConnectionBetween(bubbleID: Bubble.Identifier,
                                      to toBubbleID: Bubble.Identifier) {
        var indexSet = connections[bubbleID, default: IndexSet()]
        indexSet.insert(toBubbleID)
        connections[bubbleID] = indexSet
    }

    func addConnectionsBetween(bubbleIDs: [Bubble.Identifier], to bubbleID: Bubble.Identifier) {
        undoManager.registerUndo(withTarget: self) { selfTarget in
            selfTarget.disconnect(bubbleIDs: bubbleIDs, from: bubbleID)
        }
        for id in bubbleIDs {
            addConnectionBetween(bubbleID: id, to: bubbleID)
            addConnectionBetween(bubbleID: bubbleID, to: id)
        }
        self.canvas?.invalidate()
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

    func setColor(rgb: RGB?, for bubbleID: Bubble.Identifier) {
        colors[bubbleID] = rgb
    }

    func colorFor(bubbleID: Bubble.Identifier) -> RGB? {
        guard let color = colors[bubbleID] else { return nil }
        return color
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

    var originalPositions: [Bubble.Identifier: CGPoint]?

    func beginMove() {
        guard originalPositions == nil else {
            fatalError("we have a move in-flight, and beginning another")
        }
        originalPositions = [:]
    }

    func endMove() {
        guard let originalPositions else {
            return
        }

        let newPositions: [Bubble.Identifier: CGPoint] = originalPositions.reduce(into: [:]) { newpos, keyvalue in
            let bubbleID = keyvalue.key
            newpos[bubbleID] = positions[bubbleID]
        }

        undoManager.registerUndo(withTarget: self) { selfTarget in
            selfTarget.moveBubbles(from: newPositions, to: originalPositions)
        }

        self.originalPositions = nil
    }

    private func moveBubbles(from: [Bubble.Identifier: CGPoint], to: [Bubble.Identifier: CGPoint]) {
        undoManager.registerUndo(withTarget: self) { selfTarget in
            selfTarget.moveBubbles(from: to, to: from)
        }

        to.forEach { bubbleID, point in
            positions[bubbleID] = point
        }
        self.canvas?.invalidate()
    }

    func move(_ bubbleID: Bubble.Identifier, to point: CGPoint) {
        if originalPositions != nil, originalPositions?[bubbleID] == nil {
            originalPositions?[bubbleID] = positions[bubbleID]
        }

        positions[bubbleID] = point
    }

    func disconnect(bubbleIDs: [Bubble.Identifier], from: Bubble.Identifier) {
        undoManager.registerUndo(withTarget: self) { selfTarget in
            selfTarget.addConnectionsBetween(bubbleIDs: bubbleIDs, to: from)
        }
        for bubble in bubbleIDs {
            connections[bubble]?.remove(from)
            connections[from]?.remove(bubble)
        }
        self.canvas?.invalidate()
    }

    func setBubbleText(bubbleID: Bubble.Identifier, text: String) {
        guard let bubble = soup?.bubble(byID: bubbleID) else {
            fatalError("was expecting a bubble to back ID \(bubbleID)")
        }

        let oldText = bubble.text
        undoManager.registerUndo(withTarget: self) { selfTarget in
            selfTarget.setBubbleText(bubbleID: bubbleID, text: oldText)
        }
        bubble.text = text
        
        soup?.bubbleChanged(bubbleID)
    }
}

extension Playfield {
    func selectAll() {
        selectedBubbles.select(bubbles: bubbleIdentifiers)
    }

    func expandSelection() {
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
        var old: [Bubble.Identifier: CGFloat] = [:]
        var new: [Bubble.Identifier: CGFloat] = [:]

        selectedBubbles.forEachBubble { id in
            guard let width = widths[id] else {
                fatalError("unexpectedly missing width for id \(id)")
            }
            let newWidth = width - 10

            if newWidth > 10 {
                old[id] = width
                new[id] = newWidth
            }
        }

        changeBubbleSizes(old: old, new: new)
    }

    func embiggenBubbles() {
        var old: [Bubble.Identifier: CGFloat] = [:]
        var new: [Bubble.Identifier: CGFloat] = [:]

        selectedBubbles.forEachBubble { id in
            guard let width = widths[id] else {
                fatalError("unexpectedly missing width for id \(id)")
            }
            old[id] = width
            new[id] = width + 10
            changeBubbleSizes(old: old, new: new)
        } 
    }

    private func changeBubbleSizes(old: [Bubble.Identifier: CGFloat],
                                   new: [Bubble.Identifier: CGFloat]) {
        undoManager.registerUndo(withTarget: self) { selfTarget in
            selfTarget.changeBubbleSizes(old: new, new: old)
        }

        for (bubbleID, width) in new {
            widths[bubbleID] = width
        }
        self.canvas?.invalidate()
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

    func colorBubbles(_ color: RGB) {
        var colorChange: [Bubble.Identifier: RGB?] = [:]
        var originals: [Bubble.Identifier: RGB?] = [:]

        selectedBubbles.forEachBubble { bubbleID in
            originals[bubbleID] = colors[bubbleID]
            colorChange[bubbleID] = color
        }        
        changeBubbleColors(old: originals, new: colorChange)
    }

    private func changeBubbleColors(old: [Bubble.Identifier: RGB?],
                                    new: [Bubble.Identifier: RGB?]) {
        undoManager.registerUndo(withTarget: self) { selfTarget in
            selfTarget.changeBubbleColors(old: new, new: old)
        }
        for (bubbleID, color) in new {
            colors[bubbleID] = color
        }
        self.canvas?.invalidate()
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
        playfield?.colorBubbles(RGB(nscolor: db.color))
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
