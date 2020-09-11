import Cocoa

class Document: NSDocument {

    @IBOutlet var label: NSTextField!
    @IBOutlet var imageView: NSImageView!
    
    var text = "greeble bork"
    var image: NSImage?

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

    func dataXYZ(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the
        // specified type, throwing an error in case of failure.
        // Alternatively, you could remove this method and override
        // fileWrapper(ofType:), write(to:ofType:), or
        // write(to:ofType:for:originalContentsURL:) instead.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        // Insert code here to read your document from the given data
        // of the specified type, throwing an error in case of
        // failure.
        // Alternatively, you could remove this method and override
        // read(from:ofType:) instead.  If you do, you should also
        // override isEntireFileLoaded to return false if the contents
        // are lazily loaded.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }

    var documentFileWrapper: FileWrapper?
    enum FileWrapperError: Error {
        case badFileWrapper
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

        let textFilename = "text.txt"
        let imageFilename = "image.png"
        let metadataFilename = "metadata.json"

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
        let metadataDict = ["blah": "greeble", "hoover": "bork"]
        let encoder = JSONEncoder()
        let metadataData = try! encoder.encode(metadataDict)
        metadataFileWrapper = FileWrapper(regularFileWithContents: metadataData)
        metadataFileWrapper!.preferredFilename = metadataFilename
        documentFileWrapper.addFileWrapper(metadataFileWrapper!)

        return documentFileWrapper
    }
}

