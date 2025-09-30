#if canImport(Testing)
import Testing
@testable import LiftOS

@Suite("Engine progression decisions")
struct EngineTests {

    @Test("Rounding uses machine fine steps for lb")
    func lbMachineUsesFineSteps() async throws {
        let rounded = MesocycleProgressionEngine.roundedWeight(from: 183, unit: .lb, equip: .machineAssistance)
        // With lb fineStep = 2.5 and machine fine steps, 183 rounds to 182.5
        #expect(rounded == 182.5)
    }

    @Test("Assistance decreases with step")
    func assistanceDecreases() async throws {
        let next = MesocycleProgressionEngine.nextAssistance(current: 12, step: 2, min: 0, unit: .lb)
        #expect(next == 10)
    }

    @Test("Rep carry-over uses heaviest completed set")
    func repCarryOverHeaviest() async throws {
        let sets: [(Double, Int)] = [(100.0, 10), (120.0, 8), (110.0, 9)]
        let carry = MesocycleProgressionEngine.carryOverReps(from: sets.map { (weight: $0.0, reps: $0.1) })
        let reps = try #require(carry)
        #expect(reps == 8)
    }
}

#elseif canImport(XCTest)
import XCTest
@testable import LiftOS

final class EngineTests: XCTestCase {

    func testLbMachineUsesFineSteps() throws {
        let rounded = MesocycleProgressionEngine.roundedWeight(from: 183, unit: .lb, equip: .machineAssistance)
        // With lb fineStep = 2.5 and machine fine steps, 183 rounds to 182.5
        XCTAssertEqual(rounded, 182.5)
    }

    func testAssistanceDecreases() throws {
        let next = MesocycleProgressionEngine.nextAssistance(current: 12, step: 2, min: 0, unit: .lb)
        XCTAssertEqual(next, 10)
    }

    func testRepCarryOverHeaviest() throws {
        let sets: [(Double, Int)] = [(100.0, 10), (120.0, 8), (110.0, 9)]
        let carry = MesocycleProgressionEngine.carryOverReps(from: sets.map { (weight: $0.0, reps: $0.1) })
        let reps = try XCTUnwrap(carry)
        XCTAssertEqual(reps, 8)
    }
}
#endif
