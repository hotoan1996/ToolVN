import Foundation
import ToolVNCore

/// Chuẩn test gõ IME: **một lần nhấn phím** → một lần `IMEComposeSession.typeCharacter` (không “cả đoạn rồi replace”).
public enum PerKeystrokeTypingEngine {
    public struct Step: Sendable {
        public let index: Int
        public let key: Character
        public let prefix: String
        public let visible: String
    }

    /// Mô phỏng người gõ: trả về visible sau **từng** phím.
    public static func replay(
        keystrokes: String,
        method: VietnameseInputMethod = .telex
    ) -> [Step] {
        var session = IMEComposeSession(method: method)
        var steps: [Step] = []
        let chars = Array(keystrokes)
        for (offset, key) in chars.enumerated() {
            session.typeCharacter(key)
            let prefix = String(chars.prefix(offset + 1))
            steps.append(
                Step(
                    index: offset + 1,
                    key: key,
                    prefix: prefix,
                    visible: session.visibleText
                )
            )
        }
        return steps
    }

    public static func finalVisible(
        _ keystrokes: String,
        method: VietnameseInputMethod = .telex
    ) -> String {
        replay(keystrokes: keystrokes, method: method).last?.visible ?? ""
    }

    public static func makeCase(
        category: String,
        keystrokes: String,
        note: String = "",
        method: VietnameseInputMethod = .telex
    ) -> TypingSequenceCase {
        TypingSequenceCase(
            category: category,
            keystrokes: keystrokes,
            expectedFinal: finalVisible(keystrokes, method: method),
            note: note,
            method: method
        )
    }

    /// `TelexEngine.transform(cả chuỗi)` phải trùng kết quả gõ từng phím (cùng input).
    public static func engineMatchesPerKeystroke(
        _ telex: String,
        method: VietnameseInputMethod = .telex
    ) -> Bool {
        VietnameseConverter.convert(telex, method: method) == finalVisible(telex, method: method)
    }

    public static func engineMismatchErrors(
        telex: String,
        label: String,
        method: VietnameseInputMethod = .telex
    ) -> String? {
        let batch = VietnameseConverter.convert(telex, method: method)
        let perKey = finalVisible(telex, method: method)
        if batch == perKey { return nil }
        return "\(label): engine batch=`\(batch)` ≠ gõ từng phím=`\(perKey)`"
    }
}

public enum PerKeystrokeTypingRunner {
    /// Chạy test: sau **mỗi** phím so sánh với `replay` (chuẩn người gõ).
    public static func run(_ cases: [TypingSequenceCase]) -> [TypingStepFailure] {
        cases.flatMap { runOne($0) }
    }

    public static func runOne(_ testCase: TypingSequenceCase) -> [TypingStepFailure] {
        let golden = PerKeystrokeTypingEngine.replay(
            keystrokes: testCase.keystrokes,
            method: testCase.method
        )
        var session = IMEComposeSession(method: testCase.method)
        var failures: [TypingStepFailure] = []

        for step in golden {
            session.typeCharacter(step.key)
            let actual = session.visibleText

            if actual != step.visible {
                failures.append(
                    TypingStepFailure(
                        testCase: testCase,
                        step: step.index,
                        keystrokePrefix: step.prefix,
                        expectedVisible: step.visible,
                        actualVisible: actual,
                        reason: "sau phím #\(step.index) (`\(step.key)`)"
                    )
                )
            }

            if !ComposeInvariantChecker.isValid(session) {
                failures.append(
                    TypingStepFailure(
                        testCase: testCase,
                        step: step.index,
                        keystrokePrefix: step.prefix,
                        expectedVisible: step.visible,
                        actualVisible: actual,
                        reason: "invariant preedit (committed + preedit)"
                    )
                )
            }

            if !testCase.category.hasPrefix("perkeystroke_long"),
               IMEDuplicatePatternDetector.hasGrowingPrefixGlitch(actual) {
                failures.append(
                    TypingStepFailure(
                        testCase: testCase,
                        step: step.index,
                        keystrokePrefix: step.prefix,
                        expectedVisible: step.visible,
                        actualVisible: actual,
                        reason: "phát hiện lỗi chồng KKiKiKiê"
                    )
                )
            }

            if !testCase.category.hasPrefix("perkeystroke_long"),
               IMEDuplicatePatternDetector.hasAdjacentDuplicateChunk(actual) {
                failures.append(
                    TypingStepFailure(
                        testCase: testCase,
                        step: step.index,
                        keystrokePrefix: step.prefix,
                        expectedVisible: step.visible,
                        actualVisible: actual,
                        reason: "phát hiện đoạn chữ lặp liền kề"
                    )
                )
            }

            if IMEDuplicatePatternDetector.hasExtraTrailingSpaces(actual: actual, keystrokePrefix: step.prefix) {
                failures.append(
                    TypingStepFailure(
                        testCase: testCase,
                        step: step.index,
                        keystrokePrefix: step.prefix,
                        expectedVisible: step.visible,
                        actualVisible: actual,
                        reason: "space thừa (đúp space)"
                    )
                )
            }

            if IMEDuplicatePatternDetector.hasExtraPunctuationDoubles(actual: actual, keystrokePrefix: step.prefix) {
                failures.append(
                    TypingStepFailure(
                        testCase: testCase,
                        step: step.index,
                        keystrokePrefix: step.prefix,
                        expectedVisible: step.visible,
                        actualVisible: actual,
                        reason: "dấu câu lặp (,, ..)"
                    )
                )
            }
        }

        if let last = golden.last, session.visibleText != testCase.expectedFinal {
            failures.append(
                TypingStepFailure(
                    testCase: testCase,
                    step: last.index,
                    keystrokePrefix: testCase.keystrokes,
                    expectedVisible: testCase.expectedFinal,
                    actualVisible: session.visibleText,
                    reason: "kết quả cuối sai"
                )
            )
        }

        return failures
    }

    /// Controller (replace vùng UTF-16) phải khớp **từng bước** với gõ từng phím.
    public static func controllerConformanceErrors(
        keystrokes: String,
        method: VietnameseInputMethod = .telex
    ) -> [String] {
        PerKeystrokeTypingEngine.replay(keystrokes: keystrokes, method: method).compactMap { step in
            let controller = IMEReplacementRangeSimulator.correctVisible(
                keystrokes: step.prefix,
                method: method
            )
            if controller == step.visible { return nil }
            return "bước \(step.index) `\(step.prefix)`: controller=`\(controller)` ≠ gõ phím=`\(step.visible)`"
        }
    }

    public static func runControllerConformance(samples: [String]) -> [String] {
        samples.flatMap { controllerConformanceErrors(keystrokes: $0) }
    }
}
