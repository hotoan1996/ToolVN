import Foundation
import ToolVNCore

public struct IMETestCase: Sendable {
    public let category: String
    public let input: String
    public let expected: String
    public let note: String

    public init(category: String, input: String, expected: String, note: String = "") {
        self.category = category
        self.input = input
        self.expected = expected
        self.note = note
    }
}

public struct IMETestFailure: Sendable {
    public let testCase: IMETestCase
    public let actual: String
    public let method: VietnameseInputMethod
}

public enum IMETestSuite: Sendable {
    case golden
    case full

    public var telexCases: [IMETestCase] {
        switch self {
        case .golden: TelexGoldenFixtures.all
        case .full: TelexFixtures.all
        }
    }

    public var vniCases: [IMETestCase] {
        switch self {
        case .golden: VNIGoldenFixtures.all
        case .full: VNIFixtures.all
        }
    }
}

public enum IMETestRunner {
    public static func runTelex(_ cases: [IMETestCase]) -> [IMETestFailure] {
        run(cases, method: .telex)
    }

    public static func runVNI(_ cases: [IMETestCase]) -> [IMETestFailure] {
        run(cases, method: .vni)
    }

    public static func run(_ cases: [IMETestCase], method: VietnameseInputMethod) -> [IMETestFailure] {
        cases.compactMap { test in
            let actual = VietnameseConverter.convert(test.input, method: method)
            if actual == test.expected { return nil }
            return IMETestFailure(testCase: test, actual: actual, method: method)
        }
    }

    public static func run(suite: IMETestSuite) -> (telex: [IMETestFailure], vni: [IMETestFailure]) {
        (runTelex(suite.telexCases), runVNI(suite.vniCases))
    }
}
