import Cocoa
import AppKit
import Yams

class Document: NSDocument {
    @IBOutlet var imageView: NSImageView!

    var defaultPlayfield: Playfield!
    @IBOutlet var bubbleCanvas: BubbleCanvas!

    var secondPlayfield: Playfield!
    @IBOutlet var secondBubbleCanvas: BubbleCanvas!

    // I am so lazy...
    @IBOutlet var colorButton1: DumbButton!
    @IBOutlet var colorButton2: DumbButton!
    @IBOutlet var colorButton3: DumbButton!
    @IBOutlet var colorButton4: DumbButton!

    var documentFileWrapper: FileWrapper?

    let imageFilename = "image.png"
    let metadataFilename = "metadata.json"
    let legacyBubbleFilename = "bubbles.yaml"
    let bubbleFilename = "bubbles2.yaml"
    let barrierFilename = "barriers.yaml"
    let playfieldDirectory = "playfields.yaml"
    let defaultPlayfieldFilename = "default-playfield.yaml"

    var bubbleSoup: BubbleSoup

    // for walking selections
    var seenIDs = Set<Int>()

    var barriers: [Barrier] = [] {
        didSet {
            documentFileWrapper?.remove(filename: legacyBubbleFilename)

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
        
        // set up some defaults
        image = NSImage(named: "flumph")!
        
        let barrier1 = Barrier(ID: 1, label: "Snorgle", horizontalPosition: 100.0, width: 6.0)
        let barrier2 = Barrier(ID: 2, label: "Characters", horizontalPosition: 300.0, width: 4.0)
        let barrier3 = Barrier(ID: 3, label: "Flongwaffle", horizontalPosition: 600.0, width: 8.0)
        barriers = [barrier1, barrier2, barrier3]
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.image = image

        if let undoManager = undoManager {
            bubbleSoup.undoManager = undoManager
            barrierSoup.undoManager = undoManager
        }
        bubbleSoup.bubblesChangedHook = {
            self.documentFileWrapper?.remove(filename: self.legacyBubbleFilename)
        }
        barrierSoup.barriersChangedHook = {
            self.documentFileWrapper?.remove(filename: self.barrierFilename)
        }

        bubbleCanvas.playfield = defaultPlayfield ?? Playfield(soup: bubbleSoup)
        bubbleCanvas.playfield.canvas = bubbleCanvas
        bubbleCanvas.barrierSoup = barrierSoup
        bubbleCanvas.barriers = barriers
        bubbleCanvas.backgroundColor = BubbleCanvas.background
        bubbleCanvas.barriersChangedHook = {
            self.documentFileWrapper?.remove(filename: self.barrierFilename)
        }

        let responder = PlayfieldResponder(playfield: bubbleCanvas.playfield)
        responder.nextResponder = bubbleCanvas.nextResponder
        bubbleCanvas.nextResponder = responder

        // need to actually drive the frame from the bubbles
        let bubbleScroller = bubbleCanvas.scroller
        bubbleScroller?.contentView.backgroundColor = bubbleCanvas.backgroundColor
        bubbleScroller?.hasHorizontalScroller = true
        bubbleScroller?.hasVerticalScroller = true

        // zoom
        bubbleScroller?.magnification = 1.0

        bubbleCanvas.keypressHandler = { event in
            self.handleKeypress(event)
        }

        secondBubbleCanvas.playfield = secondPlayfield ?? Playfield(soup: bubbleSoup)
        secondBubbleCanvas.playfield.canvas = secondBubbleCanvas
        secondBubbleCanvas.barrierSoup = barrierSoup
        secondBubbleCanvas.barriers = barriers
        secondBubbleCanvas.backgroundColor = BubbleCanvas.background2
        secondBubbleCanvas.barriersChangedHook = {
            self.documentFileWrapper?.remove(filename: self.barrierFilename)
        }

        let responder2 = PlayfieldResponder(playfield: secondBubbleCanvas.playfield)
        responder2.nextResponder = secondBubbleCanvas.nextResponder
        secondBubbleCanvas.nextResponder = responder2

        // need to actually drive the frame from the bubbles
        let bubbleScroller2 = secondBubbleCanvas.scroller
        bubbleScroller2?.contentView.backgroundColor = secondBubbleCanvas.backgroundColor
        bubbleScroller2?.hasHorizontalScroller = true
        bubbleScroller2?.hasVerticalScroller = true

        // zoom
        bubbleScroller2?.magnification = 1.0

        secondBubbleCanvas.keypressHandler = { event in
            self.handleKeypress(event)
        }




        colorButton1.color = .white
        colorButton2.color = NSColor(red: 0.896043, green: 0.997437, blue: 0.942763, alpha: 1.0) // greenish
        colorButton3.color = NSColor(red: 1.0, green: 0.90283, blue: 0.976506, alpha: 1.0) // pinkish
        colorButton4.color = NSColor(red: 0.893993, green: 0.992872, blue: 1.0, alpha: 1.0) // blueish

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

        if let bubbleFileWrapper = fileWrappers[legacyBubbleFilename] {
            let bubbleData = bubbleFileWrapper.regularFileContents!
            let decoder = YAMLDecoder()
            do {
                let bubbles = try decoder.decode([Bubble].self, from: bubbleData)
                bubbleSoup.bubbles = bubbles
                defaultPlayfield = Playfield(soup: bubbleSoup)
                defaultPlayfield.migrateFrom(bubbles: bubbles)

                secondPlayfield = Playfield(soup: bubbleSoup)
                secondPlayfield.migrateSomeFrom(bubbles: bubbles)
            } catch {
                Swift.print("SNORGLE loading got \(error)")
            }
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

        if fileWrappers[legacyBubbleFilename] == nil {
            let encoder = YAMLEncoder()

            if let bubbleString = try? encoder.encode(bubbleSoup.bubbles) {
                let bubbleFileWrapper = FileWrapper(regularFileWithString: bubbleString)
                bubbleFileWrapper.preferredFilename = legacyBubbleFilename
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

//asdf    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(importScapple(_:)):
            return true
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

    /// This is probalby better moved into the playfield
    func importScapple(url: URL) {
//        let ceiling = bubbleSoup.maxBubbleID() + 1

        do {
            let incomingBubbles = try ScappleImporter().importScapple(url: url)
//            incomingBubbles.forEach { bubble in
//                bubble.offset(by: ceiling)
//            }

            bubbleSoup.add(bubbles: incomingBubbles)

            bubbleCanvas.selectedBubbles.unselectAll()
            bubbleCanvas.select(bubbles: incomingBubbles.map { $0.ID })
        } catch {
            Swift.print("import error \(error)")
        }
    }

    static func userDesktopURL() -> URL {
        let urls = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)
        let userDesktopDirectoryURL = urls[0]
        return userDesktopDirectoryURL
    }
}
