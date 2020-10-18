import XCTest
@testable import Borkle

class TestSupport: MouseSupport {
    var hitTestBubbleArgument: CGPoint? = nil
    var hitTestBubbleReturn: Bubble? = nil
    func hitTestBubble(at: CGPoint) -> Bubble? {
        hitTestBubbleArgument = at
        return hitTestBubbleReturn
    }

    var areaTestBubblesReturn: [Bubble]? = nil
    var areaTestBubblesArgument: CGRect? = nil
    func areaTestBubbles(intersecting: CGRect) -> [Bubble]? {
        areaTestBubblesArgument = intersecting
        return areaTestBubblesReturn
    }

    var drawMarqueeArgument: CGRect? = nil
    func drawMarquee(around: CGRect) {
        drawMarqueeArgument = around
    }

    var unselectAllCalled = false
    func unselectAll() {
        unselectAllCalled = true
    }

    var selectArgument: [Bubble]? = nil
    func select(bubbles: [Bubble]) {
        selectArgument = bubbles
    }

    var currentScrollOffsetReturn = CGPoint.zero
    var currentScrollOffsetCalled = false
    var currentScrollOffset: CGPoint {
        currentScrollOffsetCalled = true
        return currentScrollOffsetReturn
    }

    var scrollArgument: CGPoint?
    func scroll(to point: CGPoint) {
        scrollArgument = point
    }

    var createNewBubbleArgument: CGPoint?
    func createNewBubble(at point: CGPoint) {
        createNewBubbleArgument = point
    }
    
    var connectBubblesArgument: [Bubble]?
    var connectBubblesToArgument: Bubble?
    func connect(bubbles: [Bubble], to: Bubble) {
        connectBubblesArgument = bubbles
        connectBubblesToArgument = to
    }
    
    var disconnectBubblesArgument: [Bubble]?
    var disconnectBubblesFromArgument: Bubble?
    func disconnect(bubbles: [Bubble], from: Bubble) {
        disconnectBubblesArgument = bubbles
        disconnectBubblesFromArgument = from
    }

    var highlightAsDropTargetArgument: Bubble?
    var highlightAsDropTargetCalled = false
    func highlightAsDropTarget(bubble: Bubble?) {
        highlightAsDropTargetCalled = true
        highlightAsDropTargetArgument = bubble
    }
    
    var bubblesAffectedByReturn: [Bubble]?
    var bubblesAffectedByArgument: Barrier?
    func bubblesAffectedBy(barrier: Barrier) -> [Bubble]? {
        bubblesAffectedByArgument = barrier
        return bubblesAffectedByReturn
    }

    var barriersAffectedByReturn: [Barrier]?
    var barriersAffectedByArgument: Barrier?
    func barriersAffectedBy(barrier: Barrier) -> [Barrier]? {
        barriersAffectedByArgument = barrier
        return barriersAffectedByReturn
    }

    var moveBarrierArguments: (barrier: Barrier, bubbles: [Bubble]?, barriers: [Barrier]?, offset: CGFloat)?
    var moveBarrierCalled = false
    func move(barrier: Barrier, affectedBubbles: [Bubble]?, affectedBarriers: [Barrier]?, to horizontalPosition: CGFloat) {
        moveBarrierArguments = (barrier, affectedBubbles, affectedBarriers, horizontalPosition)
        moveBarrierCalled = true
    }

    var moveBubbleArguments: [(bubble: Bubble, to: CGPoint)]?
    var moveBubbleCalled = true
    func move(bubble: Bubble, to point: CGPoint) {
        var args = moveBubbleArguments ?? []
        args += [(bubble, point)]
        moveBubbleCalled = true
        moveBubbleArguments = args
    }

    func reset() {
        hitTestBubbleArgument = nil
        hitTestBubbleReturn = nil
        areaTestBubblesArgument = nil
        areaTestBubblesReturn = nil
        areaTestBubblesArgument = nil
        areaTestBubblesReturn = nil
        drawMarqueeArgument = nil
        unselectAllCalled = false
        selectArgument = nil
        currentScrollOffsetCalled = false
        currentScrollOffsetReturn = CGPoint.zero
        scrollArgument = nil
        createNewBubbleArgument = nil
        connectBubblesArgument = nil
        connectBubblesToArgument = nil
        disconnectBubblesArgument = nil
        disconnectBubblesFromArgument = nil
        highlightAsDropTargetArgument = nil
        highlightAsDropTargetCalled = false
        bubblesAffectedByArgument = nil
        bubblesAffectedByReturn = nil
        barriersAffectedByArgument = nil
        barriersAffectedByReturn = nil
        moveBarrierArguments = nil
        moveBarrierCalled = false
        moveBubbleArguments = nil
        moveBubbleCalled = false
    }
}
