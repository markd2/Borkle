# Borkle

Mind-Mapping for RPG Campaign design and running.

I love love love [Scapple](https://www.literatureandlatte.com/scapple/overview), mind-mapping
software from [Literate and Latte](https://www.literatureandlatte.com), the makers of 
[Scrivener](https://www.literatureandlatte.com/scrivener/overview) (which is also awesome).
I've been using it to design the latest adventure with my DnD group at work.  There's
a [repo](https://github.com/markd2/MarkDnD) with notes and whatnot.

I've been outgrowing it though - I really want Scapple's amazingly simple UI along with
an outline processor, along with some templates for things like NPCs or monster statblocks.

Kinda want Scapple cross-bred with Scrivener.

So, this is my (probably incomplete) attempt of making such a tool before I 
~get distracted~ get a more pressing assignment.

### Future features

Pain points during work:

* Easily add barriers to the right of everything
* Resize bubble while typing
* Find ("wait, what were the kind of mushrooms we found?")
* copy/paste/duplicate bubbles

* modifer-drag on barrier to not move anything
* search
  - text field at top with search criteria
  - maybe grow a sidebar with results
  - key combo to move between them
  - scroll to bubble when focused
  - maybe return to original position when leaving search mode (for in-game 
    note finding)
* Fix the scroll area bounds
* Maybe a bit of overscroll at the edges
* resize bubble when entering text
* resize off the left side with a keypress
* More colors
* color assignable by keystroke

# Screenshot Gallery

Might be fun to see the [elvisloution](https://www.youtube.com/watch?v=knc9LKjukSQ) over the ~years~ ~months~ weeks.


### "It Works"

Imports Scapple documents and draws (crudely) the mindmap.  The text field and flumph are
opened and saved to figure out bundle documents.

![](assets/screenshot-1.png)


### Adds some UI

Adds basic interaction - selecting bubbles (click / shift-click / command-click), dragging them
around, mouse-motion highlight, scrolling, undo

![](assets/borkle2.gif)

### Text Measurement

Figured out how to measure text and get the bubble to resize itself vertically.

![](assets/borkle3.png)

### Grabbing Hand Grabs All It Can

Hold down _space_ to engage the grabbing hand for scrolling.

![](assets/grab-hand.gif)

### Rubber-Band Man

Click and drag in "space" to do a basic rubber band selection

![](assets/rubber-band.gif)

### Double-click to create

Double-click in space to create a new bubble

![](assets/creation.gif)

### Remove on delete

Press Delete to remove bubles

![](assets/remove.gif)

### Barriers

Moving a barrier moves everything to the right, letting you make sections you can
easily move stuff in bulk.

![](assets/barriers.gif)

### Shift-click in space

Shift-click-dragging in space adds to the current selection.

![](assets/shift-space.gif)


### Bubble Editing

Double-click a bubble to edit its text.

![](assets/text-editing.gif)


### Make connections

Drag bubbles on top of another bubble to make (dis) connections

![](assets/connection.gif)
