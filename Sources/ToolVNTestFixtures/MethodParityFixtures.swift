import Foundation
import ToolVNCore

/// Cùng kết quả tiếng Việt: Telex vs VNI (engine batch + gõ từng phím).
public enum MethodParityFixtures {
    public struct Pair: Sendable {
        public let telex: String
        public let vni: String
        public let expected: String
        public let note: String

        public init(telex: String, vni: String, expected: String, note: String = "") {
            self.telex = telex
            self.vni = vni
            self.expected = expected
            self.note = note
        }
    }

    public static let pairs: [Pair] = [
        Pair(telex: "vieetj", vni: "vie6t5", expected: "việt"),
        Pair(telex: "Vieetj", vni: "Vie6t5", expected: "Việt"),
        Pair(telex: "hoocj", vni: "ho6c5", expected: "h\u{1ED9}c"),
        Pair(telex: "nguowif", vni: "ngu7o7i2", expected: "người"),
        Pair(telex: "dduwowcj", vni: "ddu7o7c5", expected: "được"),
        Pair(telex: "khoongf", vni: "kho6ng2", expected: "khồng"),
        Pair(telex: "mootj", vni: "mo6t5", expected: "một"),
        Pair(telex: "trowif", vni: "tro72i", expected: "trời"),
        Pair(telex: "Kieemr", vni: "Kie63m", expected: "Kiểm"),
        Pair(telex: "tieens", vni: "tie6n1", expected: "tiến"),
        Pair(telex: "dduwowngf", vni: "ddu7o7ng2", expected: "đường"),
        Pair(telex: "Tooi laf nguowif Vieetj Nam", vni: "To6i la2 ngu7o7i2 Vie6t5 Nam", expected: "Tôi là người Việt Nam"),
        Pair(telex: "as", vni: "a1", expected: "á"),
        Pair(telex: "aas", vni: "a61", expected: "ấ"),
        Pair(telex: "uws", vni: "u71", expected: "ứ"),
        Pair(telex: "dd", vni: "d9", expected: "đ"),
    ]

    public static var engineCases: [IMETestCase] {
        pairs.flatMap { p in
            [
                IMETestCase(category: "method_parity_telex", input: p.telex, expected: p.expected, note: p.note),
                IMETestCase(category: "method_parity_vni", input: p.vni, expected: p.expected, note: p.note),
            ]
        }
    }
}

public enum MethodParityRunner {
    public static func summary() -> String {
        "Parity Telex/VNI: \(MethodParityFixtures.pairs.count) cặp (\(MethodParityFixtures.engineCases.count) engine case)"
    }

    public static func run() -> [String] {
        var errors: [String] = []

        for pair in MethodParityFixtures.pairs {
            let telexBatch = TelexEngine.transform(pair.telex)
            let vniBatch = VNIEngine.transform(pair.vni)
            if telexBatch != pair.expected {
                errors.append("[parity] Telex batch `\(pair.telex)` → `\(telexBatch)` ≠ `\(pair.expected)`")
            }
            if vniBatch != pair.expected {
                errors.append("[parity] VNI batch `\(pair.vni)` → `\(vniBatch)` ≠ `\(pair.expected)`")
            }
            if telexBatch != vniBatch {
                errors.append("[parity] Telex `\(telexBatch)` ≠ VNI `\(vniBatch)` for `\(pair.note)`")
            }
            if let err = PerKeystrokeTypingEngine.engineMismatchErrors(telex: pair.telex, label: "Telex \(pair.telex)", method: .telex) {
                errors.append("[parity] \(err)")
            }
            if let err = PerKeystrokeTypingEngine.engineMismatchErrors(telex: pair.vni, label: "VNI \(pair.vni)", method: .vni) {
                errors.append("[parity] \(err)")
            }
        }

        let typingCases = MethodParityFixtures.pairs.flatMap { p -> [TypingSequenceCase] in
            [
                TypingSequenceCase(
                    category: "method_parity_telex_typing",
                    keystrokes: p.telex,
                    expectedFinal: p.expected,
                    note: p.note,
                    method: .telex
                ),
                TypingSequenceCase(
                    category: "method_parity_vni_typing",
                    keystrokes: p.vni,
                    expectedFinal: p.expected,
                    note: p.note,
                    method: .vni
                ),
            ]
        }
        errors.append(contentsOf: PerKeystrokeTypingRunner.run(typingCases).map {
            "[parity_typing] \($0.reason) `\($0.testCase.keystrokes)`"
        })

        return errors
    }
}

public enum VNIComprehensiveRunner {
    public static func summary() -> String {
        """
        \(VNITestMatrix.summary())
        \(MethodParityRunner.summary())
        """
    }

    public static func run() -> [String] {
        var errors: [String] = []
        errors.append(contentsOf: VNITestMatrix.validateGoldenMatrixAgainstEngine())

        let engineFailures = IMETestRunner.runVNI(VNITestMatrix.engineCases)
        errors.append(contentsOf: engineFailures.map {
            "[vni_engine] \($0.testCase.input) → \($0.testCase.expected) got \($0.actual)"
        })

        errors.append(contentsOf: PerKeystrokeTypingRunner.run(VNITestMatrix.fullTypingCases).map {
            "[vni_typing] \($0.reason) `\($0.testCase.keystrokes)`"
        })

        errors.append(contentsOf: MethodParityRunner.run())
        errors.append(contentsOf: vniGoldenFailures())

        return errors
    }

    private static func vniGoldenFailures() -> [String] {
        IMETestRunner.runVNI(VNIGoldenFixtures.all + VNIExtendedFixtures.all).map {
            "[vni_fixture] \($0.testCase.input) got \($0.actual)"
        }
    }
}
