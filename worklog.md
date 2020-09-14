# Wednesday September 9, 2020

* LnL - I love Scapple, just kind of outgrew it for creating making RPG campaigns
* Transferred software notes from markDnD textfile into Sketchings.scap
* Analyzed Scapple save file.  It's delightfully straightforward
* Started looking see if there's any app kit guidance for document-based apps.
  - abandonware - https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/DocBasedAppProgrammingGuideForOSX/Introduction/Introduction.html
  - https://developer.apple.com/documentation/appkit/documents_data_and_pasteboard/developing_a_document-based_app

- document represented by custom subclass of NSDocument
    - provides most of the behavior for managing your document
    - override or file-tune this behavior by providing custom code for reading and
      writing document data. a.k.a. data model
    - each NSDocument has its own NSWindowController
- NSDocumentController manages multiple documents open
    - Cocoa provides most of hte infrastructure for managing documents
    - with file coordination, version management, and conflict resolution
        - provides the easiest path to using iCloud

NSDocumentController -> NSDocument -> NSWindowController (NSWindow)

- [ ] NSDocument subclass
- [ ] Declare the document type (in xc document types editor) to define the types
      of document type information
      - UTI, identifies a data format
      - Name is human-readable - in Finder
      - Class is NSDocument subclass that handles it
      - Role - editor
      - Bundle turned on. So we can store images, text files, etc.
- [ ] design the document content
      - Document: NSDocument.
      - Has a single Content object
          - "it's easier to add new data elements to the document later"
```
class Content: NSObject {
    @objc dynamic var contentString = ""
    public init(contentString: String) ... etc
}
```
- [ ] uses objc runtime, often use KVC, KVO, bindings, NSCoding
      - therefore model classes should be objc objects and properties @objc
      - properties should be `dynamic` in Swift to use dynamic dispatch for access
- Using a centralized Content object encapsulates the document's data model
  into a single package. If need to add new data elements to your data model
  later, also place them within the content model.
  The model object is therefore responsible for encoding and decoding its content
  for reading and writing to disk

Design the document user interface

MVC.  `Content` is the model.  View is the NSWindow+NSViews,
controller divided amongst various objects including the Document..
The doc's NSWindowController and view hierarchy of NSViewController objects
descend from the window controller's contentViewController

- [ ] `Document` determines which window controllers the document will use
      via `makeWindowController`. It sets a reference to the document object
      as the contentViewController's `representedObject`, allowing the UI
      to bind the document's data model.
      So UI elements get their values through the represented object.

```
override func makeWindowControllers() {
    // Returns the storyboard that contains your document window.
    let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
    if let windowController =
        storyboard.instantiateController(
            withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as? NSWindowController {
        addWindowController(windowController)
        
        // Set the view controller's represented object as your document.
        if let contentVC = windowController.contentViewController as? ViewController {
            contentVC.representedObject = content
            contentViewController = contentVC
        }
    }
}
```

When organize the user interface into groups of view controllers
called _child view controllers_.  NSVC passes down its `representedObject` to
all of its children.

```
override var representedObject: Any? {
    didSet {
        // Pass down the represented object to all of the child view controllers.
        for child in children {
            child.representedObject = representedObject
        }
    }
}
```

Reading/Writing document content

- [X] at runtime the Document call `read(from:ofType:)` to read in the data of
      a specified type from a file.
- [X] calls `data(ofType:)` function to write a plain text file.

==================================================
# Thursday September 10, 2020

* "Scrivner for RPG planning" and/or "Scrivner and Scapple had a child"

* Want to get something up and running. Kind of infrastructure MVP
  - [X] document-based app
  - [X] image and text file in the bundle
  - [X] save to a file bundle

==================================================
# Friday September 11, 20202

  - [X] polish the file bundle experience
     - [X] interior file names and extensions
     - [X] That runtime warning
     - [X] bundle double-clickable
  - [X] display stuff
  - [X] load file
  - [X] hand-edit bundle and open. yay.
  - [X] let the user edit stuff and save it

ok, that runtime waring


2020-09-11 18:43:22.903437-0400 Borkle[55612:3042353] 

-[NSDocumentController fileExtensionsFromType:] is deprecated
  and does not work when passed a uniform type identifier (UTI). 
  If the application didn't invoke it directly _(which is true)_
  then the problem is probably that some other NSDocument or NSDocumentController
  method is getting confused by a UTI that's not actually declared anywhere. 
  Maybe it should be declared in the UTExportedTypeDeclarations section
  of this app's Info.plist but is 
  not. The alleged UTI in question is "com.borkware.borkle.bundle".

ALLEGED UTI

so UTExportedTypeDeclarations.    I have a com.borkware.borkle.bundle there :-(

There's one in LSItemContentTypes and on in UTExpotedTypeDeclrations.

ok, deleted the LSItemContentTypes. That quieted it.

added conforms to com.apple.package. Didn't work
Added-back-in "CFBundleTypeOSTypes"->"????" %-)

----------

loading file - 

```
    override func read(from fileWrapper: FileWrapper, 
                       ofType typeName: String) throws {
```

pattern:

```
        let fileWrappers = fileWrapper.fileWrappers!

        // load text file
        if let imageFileWrapper = fileWrappers[imageFilename] {
            let imageData = imageFileWrapper.regularFileContents!
            let image = NSImage(data: imageData)
            self.image = image
        }
```

----------

Let the user do stuff.

==================================================
# Saturday September 12, 2020

- [>] Some basic tests for the document
- [ ] Sketch in basic data structure, based on Scapple
- [ ] Scapple import?

I'm not a huge fan of `Document` owning all the data.  It's more controller-y,
dealing with loading and saving.  Plus it'd probably be easier to test stuff
pulling the data storage out of Document.

ALTHOUGH, it'll actually be owning stuff more sophisicated than a text field
and an image.  So maybe that's ok.  Document is responsible for holding on
to the data strucures involved, providing an undo manager, and other
document jazz.

oh no!  my keyboard is failing :-( control key and caps lock :-(

Cleaning up logic for file wrapper - the sample code doesn't make a lot
of sense / is in contradiction to the docs' suggestions for efficiency.
Also taking out the force-unwraps added for expediency

----------

Next, basic data structure - definitely a subset of Scapple's data for now.

What do I want to start out with?
  - Bubble
  - ID
  - Position
  - Width
  - Plain Text
  - connections (IndexSet)

- Bubble (Note)

That'll give a good start to displaying the stuff later.

----------

ok, stuffed some tape under the control key to make the throw shorter, seems
to have worked so far...  but not long enough :-(


----------
for the future

```
protocol Taggable {
    var tags: [String] {get set}
}
```

----------

* XML import works (not pretty, but very quick to hack something together).
* Have a canvas that draws ugly rectangles

* Import the segments
* draw the things

----------

next:

- save bubbles

- scrolling



==================================================
# Sunday September 13, 2020

- [X] save bubbles
   - [X] open last opened document and window position
- [X] scrolling

- [X] mouse motion
- [X] hit testing
- [X] equatable for bubbles
- [X] dragging
- [X] undo
- [X] multiple selection + drag
- [X] select cluster
- [X] watch keystrokes - ^X^S
- [X] properly set bounds

----------

Get some work in before _two_ games today.

----------

added saving (with bundles is really easy.  Shouldn't have been scared of them
over the years), also open lat document and window position. Makes getting
into a runnable state much faster.

----------

Now for scrolling

embed in a scroll view.  Now to remember how NSScrollView works...

NSScrollView hsa three parts:
- NSScrollView
- NSClipView
- Document View

scrollView documentView
scrollView.contentView.scroll(to: CGPoint)

bet it's driven by the frame. Yep.

Getting scroller behavior needed to turn on the scrollers

```
        bubbleScroller.hasHorizontalScroller = true
        bubbleScroller.hasVerticalScroller = true
```

----------

Also consolidaetd some of the useful utilities into one place

----------

ok, mouse motion. It's been a while...

https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/TrackingAreaObjects/TrackingAreaObjects.html#//apple_ref/doc/uid/10000060i-CH8-SW1

docs

NSTrackingArea seems to be the new hotness
request NSMouseMoved events
can request cursorUpdate (not sure what those are yet)
not sure if NSTrackingActiveInActiveApp or NSTrackingActiveInKeyWindow.
  might need to constraint to front-most window
  there's more, like refinemens of behavr

region is rect in local coordinate.  message recipient is specified when the tracking area is created
to keep up to date
  - appkit will do most of it, but will send updateTrackingAreas to recompute and reset areas

reminder for converting points

```
    override func mouseMoved(with event: NSEvent) {
        let locationInWindow = event.locationInWindow
        let viewLocation = convert(locationInWindow, from: nil)
        selectBubble(at: viewLocation)
    }
```

----------

Added mouse-down handling.  Mouse-over will highlight subtly the bubble. Click selects.

----------

OK! a bit of undo!  Let the canvas tell someone about the update.  Right now transmit out the two
points.  But as we get into this, will probably need to tweedle how we do undo.

This pattern
```

        bubbleCanvas.bubbleMoveUndoCompletion = { bubble, start, end in
            self.setBubblePosition(bubble: bubble, start: end, end: start)
        }

    func setBubblePosition(bubble: Bubble, start: CGPoint, end: CGPoint) {
        bubble.position = end
        bubbleCanvas.needsDisplay = true

        undoManager?.registerUndo(withTarget: self, handler: { (selfTarget) in
                self.setBubblePosition(bubble: bubble, start: end, end: start)
            })
    }
```

----------

10.14.4 adds command-shift-A system wide shortcut for open Apropos in Terminal.
W.T.F?  I love the terminal, but that's a bizarre one to inflict on the system.

https://intellij-support.jetbrains.com/hc/en-us/articles/360005137400-Cmd-Shift-A-hotkey-opens-Terminal-with-apropos-search-instead-of-the-Find-Action-dialog

----------

Got select-all working (got rid of the text fields because responder chain was eating Command.
Now for expand-selection (command-shift-A).  It's showing the menu item disabled.

```
    @IBAction func expandSelection(_ sender: Any) {
        Swift.print("expand selection all")
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
```

now to actually do that.  Pretty easy - walk through each bubble and add its companions.

----------

similarly for resizing the canvas when appropriate.
There's a performance issue - when doing the 'hey highlight this cell", it
redraws the WHOLE CANVAS, burning a lot of time doing all the drawing, so
there's hiccups.

==================================================
# Monday September 14, 2020

Rolled forward the ever-growing TODO. Might need to move this into somewhere else.

for next time

- [ ] play with reduce()
- [ ] fix drawing performance - the bubble highlighting is causing scrolling hiccups.

Different kinds of dragging architecture
- [ ] rubberband
- [ ] making connections
- [ ] grab-hand scroll

Need text editing
- [ ] double-click to make

Need text highlighting
- [ ] ^S search

Next text logic for measuring text, calculating heights
- [ ] centering text in bubble
- [ ] resizing bubble height to match text

Invalidate
- [ ] efficiency - spiking CPU on redraws


----------

Consolidated some of the utilites that have accumulated.

