import ToolVNTestFixtures
import XCTest

final class TelexEngineTests: XCTestCase {
    func testTelexGoldenFixtures() {
        let failures = IMETestRunner.runTelex(TelexGoldenFixtures.all)
        assertNoFailures(failures, label: "Telex golden")
    }

    func testVNIGoldenFixtures() {
        let failures = IMETestRunner.runVNI(VNIGoldenFixtures.all)
        assertNoFailures(failures, label: "VNI golden")
    }

    func testTelexCorpusValid() {
        let errors = TelexCorpus.validateAgainstEngine()
        XCTAssertTrue(errors.isEmpty, errors.joined(separator: "\n"))
    }

    func testTelexMatrixGolden() {
        let errors = TelexTestMatrix.validateGoldenMatrixAgainstEngine()
        XCTAssertTrue(errors.isEmpty, errors.joined(separator: "\n"))
    }

    func testTelexMatrixEngine() {
        let failures = IMETestRunner.runTelex(TelexTestMatrix.engineCases)
        assertNoFailures(failures, label: "Telex matrix")
    }

    func testTypingSessions() {
        let failures = TypingSessionRunner.run()
        XCTAssertTrue(failures.isEmpty, failures.prefix(5).map { $0.reason }.joined(separator: "\n"))
    }

    func testMarkedTextCommitRegressions() {
        let errors = MarkedTextCommitRegression.run()
        XCTAssertTrue(errors.isEmpty, errors.joined(separator: "\n"))
    }

    private func assertNoFailures(_ failures: [IMETestFailure], label: String) {
        guard !failures.isEmpty else { return }
        let lines = failures.prefix(25).map { failure in
            "[\(failure.testCase.category)] \(failure.testCase.input) → expected \(failure.testCase.expected), got \(failure.actual)"
        }
        XCTFail("\(failures.count) \(label) fixture(s) failed:\n" + lines.joined(separator: "\n"))
    }
}
