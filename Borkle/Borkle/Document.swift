import Cocoa
import Yams

class Document: NSDocument {
    @IBOutlet var imageView: NSImageView!
    @IBOutlet var bubbleCanvas: BubbleCanvas!
    @IBOutlet var bubbleScroller: NSScrollView!

    var documentFileWrapper: FileWrapper?

    let imageFilename = "image.png"
    let metadataFilename = "metadata.json"
    let bubbleFilename = "bubbles.yaml"
    let barrierFilename = "barriers.yaml"

    /// On the way out
    var bubbles: [Bubble] = [] {
        didSet {
            documentFileWrapper?.remove(filename: bubbleFilename)

            bubbleSoup.removeEverything()
            bubbleSoup.add(bubbles: bubbles)
        }
    }
    var bubbleSoup: BubbleSoup

    var barriers: [Barrier] = [] {
        didSet {
            documentFileWrapper?.remove(filename: bubbleFilename)

            barrierSoup.removeEverything()
            barrierSoup.add(barriers: barriers)
        }
    }
    var barrierSoup: BarrierSoup

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
        barrierSoup = BarrierSoup()
        super.init()
        image = NSImage(named: "flumph")!
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.image = image

        if let undoManager = undoManager {
            bubbleSoup.undoManager = undoManager
            barrierSoup.undoManager = undoManager
        }
        bubbleSoup.bubblesChangedHook = {
            self.documentFileWrapper?.remove(filename: self.bubbleFilename)
        }
        barrierSoup.barriersChangedHook = {
            self.documentFileWrapper?.remove(filename: self.barrierFilename)
        }

        bubbleCanvas.bubbleSoup = bubbleSoup
        bubbleCanvas.barrierSoup = barrierSoup
        bubbleCanvas.barriers = barriers
        bubbleCanvas.barriersChangedHook = {
            self.documentFileWrapper?.remove(filename: self.barrierFilename)
        }

        // need to actually drive the frame from the bubbles
        bubbleScroller.contentView.backgroundColor = BubbleCanvas.background
        bubbleScroller.hasHorizontalScroller = true
        bubbleScroller.hasVerticalScroller = true

        bubbleCanvas.keypressHandler = { event in
            self.handleKeypress(event)
        }

#if false
        let barrier1 = Barrier(ID: 1, label: "Snorgle", horizontalPosition: 100.0, width: 6.0)
        let barrier2 = Barrier(ID: 2, label: "Characters", horizontalPosition: 300.0, width: 4.0)
        let barrier3 = Barrier(ID: 3, label: "Flongwaffle", horizontalPosition: 600.0, width: 8.0)
        barriers = [barrier1, barrier2, barrier3]
#endif
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
            let decoder = YAMLDecoder()
            let bubbles = try! decoder.decode([Bubble].self, from: bubbleData)
            self.bubbles = bubbles
        }

        if let barrierFileWrapper = fileWrappers[barrierFilename] {
            let barrierData = barrierFileWrapper.regularFileContents!
            let decoder = YAMLDecoder()
            let barriers = try! decoder.decode([Barrier].self, from: barrierData)
            self.barriers = barriers
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
            let encoder = YAMLEncoder()

            if let bubbleString = try? encoder.encode(bubbles) {
                let bubbleFileWrapper = FileWrapper(regularFileWithString: bubbleString)
                bubbleFileWrapper.preferredFilename = bubbleFilename
                documentFileWrapper.addFileWrapper(bubbleFileWrapper)
            }
        }
        
        if fileWrappers[barrierFilename] == nil {
            let encoder = YAMLEncoder()

            if let barrierString = try? encoder.encode(barriers) {
                let barrierFileWrapper = FileWrapper(regularFileWithString: barrierString)
                barrierFileWrapper.preferredFilename = barrierFilename
                documentFileWrapper.addFileWrapper(barrierFileWrapper)
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

    // !!! there should be some kind of utility when given a soup and a selection to push it out.
    // !!! maybe a command patterny thing.
    func expand(selection: Selection) {
        // !!! this is O(N^2).  May need to have a lookup by ID?
        // !!! of course, wait until we see it appear in instruments
        selection.forEachBubble { bubble in
            for connection in bubble.connections {
                let connectedBubble = bubbles.first { $0.ID == connection }
                if let connectedBubble = connectedBubble {
                    selection.select(bubble: connectedBubble)
                }
            }
        }
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
        bubbleCanvas.selectedBubbles.select(bubbles: bubbles)
    }
    
    @IBAction func expandSelection(_ sender: Any) {
        expand(selection: bubbleCanvas.selectedBubbles)
    }
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(expandSelection(_:)):
            return bubbleCanvas.selectedBubbles.bubbleCount > 0
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
            bubbles = try ScappleImporter().importScapple(url: url)
            bubbleSoup.add(bubbles: bubbles)
        } catch {
            Swift.print("import error \(error)")
        }
    }
}
