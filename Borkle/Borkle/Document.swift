import Cocoa

class Document: NSDocument {
    @IBOutlet var label: NSTextField!
    @IBOutlet var imageView: NSImageView!
    @IBOutlet var bubbleCanvas: BubbleCanvas!

    var documentFileWrapper: FileWrapper?

    let textFilename = "text.txt"
    let imageFilename = "image.png"
    let metadataFilename = "metadata.json"
    let bubbleFilename = "bubbles.json"

    var bubbles: [Bubble] = [] {
        didSet {
            bubbleCanvas?.bubbles = bubbles
            removeFileWrapper(filename: bubbleFilename)
        }
    }

    var text = "greeble bork" {
        didSet {
            removeFileWrapper(filename: textFilename)
        }
    }
    var image: NSImage? {
        didSet {
            removeFileWrapper(filename: imageFilename)
        }
    }
    var metadataDict = ["blah": "greeble", "hoover": "bork"] {
        didSet {
            removeFileWrapper(filename: metadataFilename)
        }
    }

    func removeFileWrapper(filename: String) {
        // remove the text file wrapper if it exists
        if let fileWrapper = documentFileWrapper?.fileWrappers?[filename] {
            documentFileWrapper?.removeFileWrapper(fileWrapper)
        }
    }

    override init() {
        super.init()
        image = NSImage(named: "flumph")!
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        label.stringValue = text
        imageView.image = image
        bubbleCanvas.bubbles = bubbles
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
        // look for the image and text file wrappers.
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
        
        // load text file
        if let imageFileWrapper = fileWrappers[imageFilename] {
            let imageData = imageFileWrapper.regularFileContents!
            let image = NSImage(data: imageData)
            self.image = image
        }

        if let textFileWrapper = fileWrappers[textFilename] {
            let textData = textFileWrapper.regularFileContents!
            let text = String(data: textData, encoding: .utf8)!
            self.text = text
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
        

        if fileWrappers[textFilename] == nil, let textData = text.data(using: .utf8) {
            let textFileWrapper = FileWrapper(regularFileWithContents: textData)
            textFileWrapper.preferredFilename = textFilename
            
            documentFileWrapper.addFileWrapper(textFileWrapper)
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
}

extension Document: NSTextFieldDelegate {
    func controlTextDidChange(_ notification: Notification) {
        if let textField = notification.object as? NSTextField {
            text = textField.stringValue
            updateChangeCount(.changeDone)
        }
    }
}


extension Document {
    @IBAction func imageDrop(_ sender: NSImageView) {
        image = sender.image
        updateChangeCount(.changeDone)
    }
}


extension Document {
    // Comes in via responder chain.
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
