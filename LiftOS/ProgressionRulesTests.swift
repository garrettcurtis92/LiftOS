#if canImport(XCTest)
import XCTest
@testable import app

final class ProgressionTests: XCTestCase {

    func testProgressionInitialState() async throws {
        let progression = Progression()
        XCTAssertEqual(progression.currentStep, 0)
        XCTAssertFalse(progression.isCompleted)
    }

    func testProgressionAdvanceStep() async throws {
        var progression = Progression()
        progression.advance()
        XCTAssertEqual(progression.currentStep, 1)
        XCTAssertFalse(progression.isCompleted)
    }

    func testProgressionComplete() async throws {
        var progression = Progression()
        while !progression.isCompleted {
            progression.advance()
        }
        XCTAssertTrue(progression.isCompleted)
    }
}

#endif
