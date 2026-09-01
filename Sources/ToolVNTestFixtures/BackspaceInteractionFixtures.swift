import Foundation
import ToolVNCore

public struct BackspaceInteractionCase: Sendable {
    public let category: String
    public let keys: [IMEUserKey]
    public let expectedFinal: String
    public let note: String

    public init(category: String, keys: [IMEUserKey], expectedFinal: String, note: String = "") {
        self.category = category
        self.keys = keys
        self.expectedFinal = expectedFinal
        self.note = note
    }
}

public enum BackspaceInteractionFixtures {
    /// Gõ xong từ → xóa 1 phím telex → gõ tiếp (lỗi hay gặp trên IME).
    public static let cases: [BackspaceInteractionCase] = [
        k(chars("vieetj") + [.backspace] + chars("m"), note: "sửa cuối từ việt"),
        k(chars("vieetj") + [.backspace, .backspace] + chars("tj"), note: "xóa 2 rồi gõ lại tj"),
        k(chars("Kieemr") + [.backspace] + chars("r tra"), note: "Kiểm tra — xóa rồi gõ tiếp"),
        k(chars("vieetj ") + [.backspace] + chars("t"), note: "đã space, xóa 1 ký tự committed rồi gõ t"),
        k(chars("vieetj ") + [.backspace, .backspace] + chars("tr"), note: "xóa space + 1 chữ rồi gõ tr"),
        k(
            chars("Hoom nay ") + chars("trowif") + [.backspace] + chars("f"),
            note: "giữa câu — xóa trong từ đang gõ"
        ),
        k(chars("dduwowcj") + [.backspace] + chars("j"), note: "được — xóa j rồi gõ lại"),
        k(
            chars("xoaa") + [.backspace, .backspace] + chars("a"),
            expected: "xoa",
            note: "xoâ → xo → gõ lại a phải là xoa không phải xoâ"
        ),
        k(chars("xoa") + [.backspace] + chars("a"), expected: "xoa", note: "xoa sửa chữ a"),
        k(
            chars("xoas") + [.backspace, .backspace] + chars("a"),
            expected: "xoa",
            note: "xóa — xóa s và a rồi gõ lại a"
        ),
        k(
            chars("hopwj") + [.backspace],
            expected: "hơp",
            note: "hợp xóa phím j → hơp"
        ),
        k(
            chars("hopwj ") + [.backspace, .backspace] + chars("laf "),
            note: "hợp space, xóa space + 1 rồi gõ là"
        ),
        k(
            chars("vieetj") + [.backspace],
            expected: "viêt",
            note: "xóa phím telex cuối (j) → viêt"
        ),
    ]

    private static func chars(_ s: String) -> [IMEUserKey] {
        s.map { .character($0) }
    }

    private static func k(_ keys: [IMEUserKey], expected: String? = nil, note: String) -> BackspaceInteractionCase {
        let final = expected ?? IMEInteractionReplay.sessionFinal(keys)
        return BackspaceInteractionCase(category: "backspace", keys: keys, expectedFinal: final, note: note)
    }
}

public enum BackspaceInteractionRunner {
    public static func run(_ cases: [BackspaceInteractionCase] = BackspaceInteractionFixtures.cases) -> [String] {
        cases.flatMap { runOne($0) }
    }

    public static func runOne(_ testCase: BackspaceInteractionCase) -> [String] {
        let sessionSteps = IMEInteractionReplay.sessionVisibleSteps(keys: testCase.keys)
        let controllerSteps = IMEControllerTypingSimulator.replay(keys: testCase.keys).map(\.document)
        var errors: [String] = []

        if sessionSteps.count != controllerSteps.count {
            errors.append(
                "\(testCase.category): số bước session \(sessionSteps.count) ≠ controller \(controllerSteps.count) — \(testCase.note)"
            )
            return errors
        }

        for (index, pair) in zip(sessionSteps, controllerSteps).enumerated() {
            if pair.0 != pair.1 {
                errors.append(
                    "\(testCase.category) bước \(index + 1): session=`\(pair.0)` controller=`\(pair.1)` — \(testCase.note)"
                )
            }
            if IMEDuplicatePatternDetector.hasGrowingPrefixGlitch(pair.1) {
                errors.append("\(testCase.category) bước \(index + 1): glitch prefix — \(testCase.note)")
            }
            if IMEDuplicatePatternDetector.hasAdjacentDuplicateChunk(pair.1) {
                errors.append("\(testCase.category) bước \(index + 1): chunk lặp — \(testCase.note)")
            }
        }

        if let last = controllerSteps.last, last != testCase.expectedFinal {
            errors.append(
                "\(testCase.category) cuối: `\(last)` mong `\(testCase.expectedFinal)` — \(testCase.note)"
            )
        }

        return errors
    }
}
