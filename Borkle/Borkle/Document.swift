import Cocoa

class Document: NSDocument {
    @IBOutlet var imageView: NSImageView!
    @IBOutlet var bubbleCanvas: BubbleCanvas!
    @IBOutlet var bubbleScroller: NSScrollView!

    var documentFileWrapper: FileWrapper?

    let imageFilename = "image.png"
    let metadataFilename = "metadata.json"
    let bubbleFilename = "bubbles.json"

    /// On the way out
    var bubbles: [Bubble] = [] {
        didSet {
            bubbleCanvas?.bubbles = bubbles
            documentFileWrapper?.remove(filename: bubbleFilename)

            bubbleSoup.removeEverything()
            bubbleSoup.add(bubbles: bubbles)
        }
    }
    var bubbleSoup: BubbleSoup

    var image: NSImage? {
        didSet {
            documentFileWrapper?.remove(filename: imageFilename)
        }
    }
    var metadataDict = ["blah": "greeble", "hoover": "bork"] {
        didSet {
            documentFileWrapper?.remove(filename: metadataFilename)
        }
    }

    override init() {
        bubbleSoup = BubbleSoup()
        super.init()
        image = NSImage(named: "flumph")!
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.image = image

        if let undoManager = undoManager {
            bubbleSoup.undoManager = undoManager
        }

        bubbleCanvas.bubbles = bubbles
        // need to actually drive the frame from the bubbles
        bubbleScroller.contentView.backgroundColor = BubbleCanvas.background
        bubbleScroller.hasHorizontalScroller = true
        bubbleScroller.hasVerticalScroller = true

        bubbleCanvas.bubbleSoup = bubbleSoup

        bubbleCanvas.bubbleMoveUndoCompletion = { bubble, start, end in
            self.setBubblePosition(bubble: bubble, start: end, end: start)
        }
        bubbleCanvas.keypressHandler = { event in
            self.handleKeypress(event)
        }
    }

    func setBubblePosition(bubble: Bubble, start: CGPoint, end: CGPoint) {
        documentFileWrapper?.remove(filename: bubbleFilename)

        bubble.position = end
        bubbleCanvas.needsDisplay = true

        undoManager?.registerUndo(withTarget: self, handler: { (selfTarget) in
                self.setBubblePosition(bubble: bubble, start: end, end: start)

                // !!! Need to do this at the end of a bunch of undos rather than every time
                self.bubbleCanvas.resizeCanvas()
            })
    }

    override class var autosavesInPlace: Bool {
        return true
    }

    override var windowNibName: NSNib.Name? {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if
        // your document supports multiple NSWindowControllers, you
        // should remove this property and override
        // -makeWindowControllers instead.

        return NSNib.Name("Document")
    }

    enum FileWrapperError: Error {
        case badFileWrapper
        case unexpectedlyNilFileWrappers
    }

    override func read(from fileWrapper: FileWrapper, 
                       ofType typeName: String) throws {

        // (comment from apple sample code)
        // look for the file wrappers.
        // for each wrapper, extract the data and keep the file wrapper itself.
        // The file wrappers are kept so that, if the corresponding data hasn't
        // been changed, they can be reused during a save, and so the source
        // file can be reused rather than rewritten.
        // This avoids the overhead of syncing data unnecessarily. If the data
        // related to a file wrapper changes (like a new image is added or text
        // is edited), the corresponding file wrapper object is disposed of
        // and a new file wrapper created on save.

        let fileWrappers = fileWrapper.fileWrappers!

        if let bubbleFileWrapper = fileWrappers[bubbleFilename] {
            let bubbleData = bubbleFileWrapper.regularFileContents!
            let decoder = JSONDecoder()
            let bubbles = try! decoder.decode([Bubble].self, from: bubbleData)
            self.bubbles = bubbles
        }
        
        if let imageFileWrapper = fileWrappers[imageFilename] {
            let imageData = imageFileWrapper.regularFileContents!
            let image = NSImage(data: imageData)
            self.image = image
        }

        if let metadataFileWrapper = fileWrappers[metadataFilename] {
            let metadataData = metadataFileWrapper.regularFileContents!
            let decoder = JSONDecoder()
            let metadata = try! decoder.decode([String:String].self, from: metadataData)
            self.metadataDict = metadata
        }
        
        documentFileWrapper = fileWrapper
    }
    
    override func fileWrapper(ofType typeName: String) throws -> FileWrapper {
        if documentFileWrapper == nil {
            let childrenByPreferredName = [String: FileWrapper]()
            documentFileWrapper = FileWrapper(directoryWithFileWrappers: childrenByPreferredName)
        }

        guard let documentFileWrapper = documentFileWrapper else {
            throw(FileWrapperError.badFileWrapper)
        }

        guard let fileWrappers = documentFileWrapper.fileWrappers else {
            throw(FileWrapperError.unexpectedlyNilFileWrappers)
        }

        if fileWrappers[bubbleFilename] == nil {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted

            if let bubbleData = try? encoder.encode(bubbles) {
                let bubbleFileWrapper = FileWrapper(regularFileWithContents: bubbleData)
                bubbleFileWrapper.preferredFilename = bubbleFilename
                documentFileWrapper.addFileWrapper(bubbleFileWrapper)
            }
        }
        
        if fileWrappers[imageFilename] == nil, let image = image {
            let imageReps = image.representations
            var data = NSBitmapImageRep.representationOfImageReps(in: imageReps,
                                                                  using: .png,
                                                                  properties: [:])
            if data == nil, let tiffData = image.tiffRepresentation,
                let imageRep = NSBitmapImageRep(data: tiffData) {
                data = imageRep.representation(using: .png, properties: [:])
            }

            if data != nil {
                let imageFileWrapper = FileWrapper(regularFileWithContents: data!)
                imageFileWrapper.preferredFilename = imageFilename
                documentFileWrapper.addFileWrapper(imageFileWrapper)
            }
        }

        if fileWrappers[metadataFilename] == nil {
            // write the new file wrapper for our metadata
            let encoder = JSONEncoder()
            if let metadataData = try? encoder.encode(metadataDict) {
                let metadataFileWrapper = FileWrapper(regularFileWithContents: metadataData)
                metadataFileWrapper.preferredFilename = metadataFilename
                documentFileWrapper.addFileWrapper(metadataFileWrapper)
            }
        }

        return documentFileWrapper
    }

    // !!! There should be a selection class that can handle this push-out of selections
    func expand(selection: Set<Bubble>) -> Set<Bubble> {
        var destinationSet = selection

        // !!! this is O(N^2).  May need to have a lookup by ID?
        // !!! of course, wait until we see it appear in instruments
        for bubble in selection {
            for connection in bubble.connections {
                let connectedBubble = bubbles.first { $0.ID == connection }
                if let connectedBubble = connectedBubble {
                    destinationSet.insert(connectedBubble)
                }
            }
        }

        return destinationSet
    }

    // Did we see a control-X float by? If so, if we see the next keystroke as a control-S,
    // the save. (emacs save-document combo)
    var controlXLatch = false

    func forceSave() {
        NSApp.sendAction(#selector(NSDocument.save(_:)), to: nil, from: self)
    }
    func handleKeypress(_ event: NSEvent) {
        switch event.characters {

        case "\u{18}":  // control-X
            controlXLatch = true

        case "\u{13}":  // control-S
            if controlXLatch {
                Swift.print("SAVE")
                forceSave()
            } else {
                Swift.print("SEARCH-placeholder")
            }
            controlXLatch = false

        default:
            controlXLatch = false
        }
    }
}


extension Document {
    @IBAction func imageDrop(_ sender: NSImageView) {
        image = sender.image
        updateChangeCount(.changeDone)
    }

    @IBAction func selectAll(_ sender: Any) {
        bubbleCanvas.selectBubbles(Set(bubbles))
    }
    
    @IBAction func expandSelection(_ sender: Any) {
        bubbleCanvas.selectedBubbles = expand(selection: bubbleCanvas.selectedBubbles)
    }
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(expandSelection(_:)):
            return bubbleCanvas.selectedBubbles.count > 0
        default:
            break
        }
        return menuItem.isEnabled
    }

    @IBAction func importScapple(_ sender: AnyObject) {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["scap"]
        panel.allowsMultipleSelection = false
        if let window = windowControllers.first?.window {
            panel.beginSheetModal(for: window) { response in
                if response == .OK, let url = panel.urls.first {
                    self.importScapple(url: url)
                }
            }
        }
    }

    func importScapple(url: URL) {
        do {
            Swift.print("SNORGLE LOAD \(url)")
            bubbles = try ScappleImporter().importScapple(url: url)
        } catch {
            Swift.print("import error \(error)")
        }
    }
}
