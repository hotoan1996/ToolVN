import Foundation
import ToolVNCore

/// Kịch bản gõ như người dùng: gõ nhầm dấu / ký tự → Delete → gõ lại.
public struct UserTypingJourneyCase: Sendable {
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

public enum UserTypingJourneyFixtures {
    public static let all: [UserTypingJourneyCase] =
        deleteRetypeCharacter
        + toneMistakeAndFix
        + removeToneWithDoubleKey
        + wordXoaScenarios

    /// Sửa nguyên âm / ký tự (xoâ, xóa, …).
    private static let deleteRetypeCharacter: [UserTypingJourneyCase] = [
        j(
            "user_delete_char",
            IMEUserKeyBuilders.telex("xoaa") + [.backspace, .backspace] + IMEUserKeyBuilders.telex("a"),
            "xoa",
            "xoâ → xo → gõ a → xoa (không xoâ)"
        ),
        j(
            "user_delete_char",
            IMEUserKeyBuilders.telex("xoa") + [.backspace] + IMEUserKeyBuilders.telex("a"),
            "xoa",
            "xoa xóa a rồi gõ lại a"
        ),
        j(
            "user_delete_char",
            IMEUserKeyBuilders.telex("xoas") + [.backspace, .backspace] + IMEUserKeyBuilders.telex("a"),
            "xoa",
            "xóa: xóa s và a, gõ lại a"
        ),
        j(
            "user_delete_char",
            IMEUserKeyBuilders.telex("xoas") + [.backspace, .backspace] + IMEUserKeyBuilders.telex("as"),
            "xóa",
            "xóa: sửa a và s thành xóa"
        ),
        j(
            "user_delete_char",
            IMEUserKeyBuilders.telex("vieetj") + [.backspace, .backspace] + IMEUserKeyBuilders.telex("tj"),
            "việt",
            "việt: xóa tj rồi gõ lại"
        ),
        j(
            "user_delete_char",
            IMEUserKeyBuilders.telex("nguowif") + [.backspace] + IMEUserKeyBuilders.telex("f"),
            "người",
            "người: xóa f rồi gõ lại"
        ),
    ]

    /// Gõ nhầm thanh (s/f/r/x/j) rồi Delete và gõ lại.
    private static let toneMistakeAndFix: [UserTypingJourneyCase] = [
        j(
            "user_tone_fix",
            IMEUserKeyBuilders.telex("camrs") + [.backspace],
            "cảm",
            "cảm + s thừa → xóa s"
        ),
        j(
            "user_tone_fix",
            IMEUserKeyBuilders.telex("quass") + [.backspace],
            "quá",
            "quá + s (ss) → quas, xóa s telex"
        ),
        j(
            "user_tone_fix",
            IMEUserKeyBuilders.telex("mootjf") + [.backspace],
            "một",
            "một + f nhầm → xóa f"
        ),
        j(
            "user_tone_fix",
            IMEUserKeyBuilders.telex("tieenf") + [.backspace] + IMEUserKeyBuilders.telex("s"),
            "tiến",
            "nhầm f, xóa, gõ s"
        ),
        j(
            "user_tone_fix",
            IMEUserKeyBuilders.telex("asf") + [.backspace, .backspace] + IMEUserKeyBuilders.telex("s"),
            "á",
            "asf → xóa f và s → as → gõ s"
        ),
    ]

    /// Bỏ dấu bằng phím lặp (ss/ff) hoặc xóa rồi gõ lại.
    private static let removeToneWithDoubleKey: [UserTypingJourneyCase] = [
        j(
            "user_untone",
            IMEUserKeyBuilders.telex("as") + IMEUserKeyBuilders.telex("s"),
            "as",
            "as + s (ss) bỏ dấu → as"
        ),
        j(
            "user_untone",
            IMEUserKeyBuilders.telex("quas") + IMEUserKeyBuilders.telex("s"),
            "quas",
            "quá + s → quas"
        ),
        j(
            "user_untone",
            IMEUserKeyBuilders.telex("as") + [.backspace] + IMEUserKeyBuilders.telex("s"),
            "á",
            "đã có á, xóa s telex rồi gõ lại s"
        ),
        j(
            "user_untone",
            IMEUserKeyBuilders.telex("aas") + IMEUserKeyBuilders.telex("s"),
            "âs",
            "ấ + ss → âs"
        ),
        j(
            "user_untone",
            IMEUserKeyBuilders.telex("vieetj") + IMEUserKeyBuilders.telex("z") + [.backspace],
            "việt",
            "việt: z bỏ dấu nhầm, xóa z"
        ),
    ]

  /// Từ «xóa» và biến thể.
    private static let wordXoaScenarios: [UserTypingJourneyCase] = [
        j("user_xoa", IMEUserKeyBuilders.telex("xoas"), "xóa", "gõ đúng một lần"),
        j(
            "user_xoa",
            IMEUserKeyBuilders.telex("xoax") + [.backspace] + IMEUserKeyBuilders.telex("s"),
            "xóa",
            "nhầm x thay vì s"
        ),
        j(
            "user_xoa",
            IMEUserKeyBuilders.telex("xos") + [.backspace] + IMEUserKeyBuilders.telex("as"),
            "xóa",
            "xos → xóa s → as"
        ),
    ]

    private static func j(
        _ category: String,
        _ keys: [IMEUserKey],
        _ expected: String,
        _ note: String
    ) -> UserTypingJourneyCase {
        UserTypingJourneyCase(category: category, keys: keys, expectedFinal: expected, note: note)
    }
}

public enum UserTypingJourneyRunner {
    public static func run(_ cases: [UserTypingJourneyCase] = UserTypingJourneyFixtures.all) -> [String] {
        cases.flatMap { runOne($0) }
    }

    public static func runOne(_ testCase: UserTypingJourneyCase) -> [String] {
        let controllerSteps = IMEControllerTypingSimulator.replay(keys: testCase.keys)
        let legacyDocSteps = IMEReplacementRangeSimulator.documentSteps(keys: testCase.keys)
        let sessionSteps = IMEInteractionReplay.sessionVisibleSteps(keys: testCase.keys)
        var errors: [String] = []

        if controllerSteps.count != legacyDocSteps.count {
            errors.append(
                "[\(testCase.category)] simulator/legacy lệch số bước — \(testCase.note)"
            )
        }

        for (index, step) in controllerSteps.enumerated() {
            let doc = step.document
            if index < legacyDocSteps.count, doc != legacyDocSteps[index] {
                errors.append(
                    "[\(testCase.category)] bước \(step.index): controller=`\(doc)` legacy=`\(legacyDocSteps[index])` — \(testCase.note)"
                )
            }
            if index < sessionSteps.count, doc != sessionSteps[index] {
                errors.append(
                    "[\(testCase.category)] bước \(step.index): document=`\(doc)` session=`\(sessionSteps[index])` — \(testCase.note)"
                )
            }
            if let last = controllerSteps.last?.document,
               last.contains("xoâ"),
               testCase.expectedFinal == "xoa" {
                errors.append(
                    "[\(testCase.category)] cuối: không được xoâ khi mong xoa — \(testCase.note)"
                )
            }
            if IMEDuplicatePatternDetector.hasGrowingPrefixGlitch(doc) {
                errors.append("[\(testCase.category)] bước \(step.index): glitch prefix — \(testCase.note)")
            }
            if IMEDuplicatePatternDetector.hasAdjacentDuplicateChunk(doc) {
                errors.append("[\(testCase.category)] bước \(step.index): chunk lặp — \(testCase.note)")
            }
        }

        if let last = controllerSteps.last?.document, last != testCase.expectedFinal {
            errors.append(
                "[\(testCase.category)] cuối: `\(last)` mong `\(testCase.expectedFinal)` — \(testCase.note)"
            )
        }

        return errors
    }
}
