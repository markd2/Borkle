import XCTest
@testable import Borkle

class BarrierSoupTests: XCTestCase {
    
    var soup: BarrierSoup!

    override func setUp() {
        super.setUp()
        soup = BarrierSoup()
    }

    override func tearDown() {
        soup = nil
        super.tearDown()
    }

    func test_complete_coverage() {
        _ = BarrierSoup(undoManager: UndoManager())
    }
    
}

/// These exercise adding and removing
extension BarrierSoupTests {
    func test_add_barrier() {
        let barrier = Barrier(ID: 23)
        soup.add(barrier: barrier)
        XCTAssertEqual(soup.barrierCount, 1)
    }

    func test_add_barrier_undo() {
        let barrier = Barrier(ID: 23)
        soup.add(barrier: barrier)
        soup.undo()
        XCTAssertEqual(soup.barrierCount, 0)
    }

    func test_add_bulk_barriers_to_empty_soup() {
        let barriers = [Barrier(ID: 1)]

        soup.add(barriers: barriers)
        XCTAssertEqual(soup.barrierCount, 1)
    }

    func test_add_bulk_barriers_to_soup() {
        let barriers = [Barrier(ID: 1)]
        soup.add(barriers: barriers)

        let moreBarriers = [Barrier(ID: 2), Barrier(ID: 3)]
        soup.add(barriers: moreBarriers)

        XCTAssertEqual(soup.barrierCount, 3)
    }

    func test_lookup_by_ID() {
        let barriers = [Barrier(ID: 1), Barrier(ID: 5), Barrier(ID: 3)]
        soup.add(barriers: barriers)

        XCTAssertEqual(soup.barrier(byID: 1)!.ID, 1)
        XCTAssertEqual(soup.barrier(byID: 3)!.ID, 3)
        XCTAssertNil(soup.barrier(byID: 666))
    }

    func test_adding_bulk_barriers_undo() {
        let barriers = [Barrier(ID: 1)]
        soup.add(barriers: barriers)

        let moreBarriers = [Barrier(ID: 2), Barrier(ID: 3)]
        soup.add(barriers: moreBarriers)

        XCTAssertEqual(soup.barrierCount, 3)
        soup.undo()
        XCTAssertEqual(soup.barrierCount, 1)
        soup.undo()
        XCTAssertEqual(soup.barrierCount, 0)
    }

    func test_remove_everything() {
        let barriers = [Barrier(ID: 1), Barrier(ID: 2), Barrier(ID: 3)]
        soup.add(barriers: barriers)

        XCTAssertEqual(soup.barrierCount, 3)
        soup.removeEverything()

        XCTAssertEqual(soup.barrierCount, 0)
    }

    func test_remove_everything_undo() {
        let barriers = [Barrier(ID: 1), Barrier(ID: 2), Barrier(ID: 3)]
        soup.add(barriers: barriers)

        soup.removeEverything()
        XCTAssertEqual(soup.barrierCount, 0)
        soup.undo()
        XCTAssertEqual(soup.barrierCount, 3)
    }

    func test_undo_grouping() {
        soup.beginGrouping()
        soup.add(barrier: Barrier(ID: 1))
        soup.add(barrier: Barrier(ID: 2))
        soup.add(barrier: Barrier(ID: 3))
        soup.endGrouping()
        
        XCTAssertEqual(soup.barrierCount, 3)
        soup.undo()
        XCTAssertEqual(soup.barrierCount, 0)
    }
    
    func test_undo_latch() {
        soup.add(barrier: Barrier(ID: 1))
        soup.add(barrier: Barrier(ID: 2))
        soup.add(barrier: Barrier(ID: 3))
        soup.endGrouping()
        
        XCTAssertEqual(soup.barrierCount, 3)
        soup.undo()
        XCTAssertEqual(soup.barrierCount, 2)
    }

    func test_barrier_iteration() {
        soup.add(barrier: Barrier(ID: 1))
        soup.add(barrier: Barrier(ID: 2))
        soup.add(barrier: Barrier(ID: 3))

        var count = 0
        var seenIDs = IndexSet()
        soup.forEachBarrier {
            seenIDs.insert($0.ID)
            count += 1
        }
        
        XCTAssertEqual(count, 3)
        XCTAssertEqual(seenIDs, IndexSet(1...3))
    }
}
