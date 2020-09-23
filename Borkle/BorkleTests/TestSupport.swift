import XCTest
@testable import Borkle

class TestSupport: MouseSupport {

    var hitTestBubbleArgument: CGPoint? = nil
    var hitTestBubbleReturn: Bubble? = nil
    func hitTestBubble(at: CGPoint) -> Bubble? {
        hitTestBubbleArgument = at
        return hitTestBubbleReturn
    }

    var areaTestBubblesArgument: CGRect? = nil
    var areaTestBubblesReturn: [Bubble]? = nil
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

    var currentScrollOffsetCalled = false
    var currentScrollOffsetReturn = CGPoint.zero
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

    var bubblesAffectedByArgument: Barrier?
    var bubblesAffectedByReturn: [Bubble]?
    func bubblesAffectedBy(barrier: Barrier) -> [Bubble]? {
        bubblesAffectedByArgument = barrier
        return bubblesAffectedByReturn
    }

    var barriersAffectedByArgument: Barrier?
    var barriersAffectedByReturn: [Barrier]?
    func barriersAffectedBy(barrier: Barrier) -> [Barrier]? {
        barriersAffectedByArgument = barrier
        return barriersAffectedByReturn
    }

    var moveBarrierArgments: (Barrier, [Bubble]?, [Barrier]?, CGFloat)?
    var moveBarrierCalled = false
    func move(barrier: Barrier, affectedBubbles: [Bubble]?, affectedBarriers: [Barrier]?, to horizontalPosition: CGFloat) {
        moveBarrierCalled = true
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
        bubblesAffectedByArgument = nil
        bubblesAffectedByReturn = nil
        barriersAffectedByArgument = nil
        barriersAffectedByReturn = nil
        moveBarrierArgments = nil
        moveBarrierCalled = false
    }
}
