import Cocoa

class Document: NSDocument {

    @IBOutlet var label: NSTextField!
    @IBOutlet var imageView: NSImageView!
    
    var text = "greeble bork"
    var image: NSImage?
    var metadataDict = ["blah": "greeble", "hoover": "bork"]

    let textFilename = "text.txt"
    let imageFilename = "image.png"
    let metadataFilename = "metadata.json"

    override init() {
        super.init()
        image = NSImage(named: "flumph")!
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        label.stringValue = text
        imageView.image = image
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

    var documentFileWrapper: FileWrapper?
    enum FileWrapperError: Error {
        case badFileWrapper
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
    }
    
    override func fileWrapper(ofType typeName: String) throws -> FileWrapper {
        if documentFileWrapper == nil {
            let childrenByPreferredName = [String: FileWrapper]()
            documentFileWrapper = FileWrapper(directoryWithFileWrappers: childrenByPreferredName)
        }

        guard let documentFileWrapper = documentFileWrapper else {
            throw(FileWrapperError.badFileWrapper)
        }

        let fileWrappers = documentFileWrapper.fileWrappers!

        // "if there isn't a wrapper for the text file, create one too"
        if fileWrappers[textFilename] != nil {
            let textWrapper = fileWrappers[textFilename]!
            documentFileWrapper.removeFileWrapper(textWrapper)
        }

        let textdata = text.data(using: .utf8)!
        let textFileWrapper = FileWrapper(regularFileWithContents: textdata)
        textFileWrapper.preferredFilename = textFilename

        documentFileWrapper.addFileWrapper(textFileWrapper)

        // "if the document file wrapper doesn't contain a file wrapper for an
        // image and the image is not nil,
        // then create a file wrapper for the image and add it to the document
        // file wrapper

        if fileWrappers[imageFilename] == nil, let image = image {
            let imageReps = image.representations
            var data = NSBitmapImageRep.representationOfImageReps(in: imageReps,
                                                                  using: .png,
                                                                  properties: [:])
            if data == nil {
                let tiffData = image.tiffRepresentation!
                let imageRep = NSBitmapImageRep(data: tiffData)!
                data = imageRep.representation(using: .png, properties: [:])
            }

            let imageFileWrapper = FileWrapper(regularFileWithContents: data!)
            imageFileWrapper.preferredFilename = imageFilename
            documentFileWrapper.addFileWrapper(imageFileWrapper)
        }

        // "check if we already have a metadata file wrapper, first remove
        // the old one if it exists.
        var metadataFileWrapper = fileWrappers[metadataFilename]
        if metadataFileWrapper != nil {
            documentFileWrapper.removeFileWrapper(metadataFileWrapper!)
        }

        // write the new file wrapper for our metadata
        let encoder = JSONEncoder()
        let metadataData = try! encoder.encode(metadataDict)
        metadataFileWrapper = FileWrapper(regularFileWithContents: metadataData)
        metadataFileWrapper!.preferredFilename = metadataFilename
        documentFileWrapper.addFileWrapper(metadataFileWrapper!)

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
