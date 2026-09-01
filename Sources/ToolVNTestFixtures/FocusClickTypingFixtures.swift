import Foundation
import ToolVNCore

/// Click chỉnh vị trí con trỏ rồi gõ tiếp (focus không loạn).
public enum FocusClickTypingFixtures {
    public static let cases: [DeleteAndContinueCase] = [
        c(
            t("vieetj ") + [.caretAtUTF16(0)] + t("xin"),
            "click đầu dòng, gõ xin",
            "xinviệt "
        ),
        c(
            t("vieetj ") + [.caretAtUTF16(0)] + t("guiwr"),
            "đầu dòng gõ gửi",
            "gửiviệt "
        ),
        c(
            t("abc ") + [.caretAtUTF16(0)] + t("guiwr") + [.character(" ")],
            "abc + gửi ở đầu",
            "gửi abc "
        ),
        c(
            t("guiwr") + [.caretAtUTF16(0)] + t("xin"),
            "chốt gửi, click đầu xin",
            "xingửi"
        ),
        c(
            t("Hoom nay ") + [.caretAtUTF16(4)] + t("trowif"),
            "giữa câu click, gõ trời",
            nil
        ),
    ]

    private static func t(_ s: String) -> [IMEUserKey] { IMEUserKeyBuilders.telex(s) }

    private static func c(_ keys: [IMEUserKey], _ note: String, _ mustBe: String?) -> DeleteAndContinueCase {
        let expected = mustBe ?? FocusClickTypingSimulator.finalDocument(keys: keys)
        return DeleteAndContinueCase(intent: .afterCommitted, keys: keys, expectedFinal: expected, note: note)
    }
}

public enum FocusClickTypingRunner {
    public static func run() -> [String] {
        FocusClickTypingFixtures.cases.compactMap { testCase in
            let got = FocusClickTypingSimulator.finalDocument(keys: testCase.keys)
            if got == testCase.expectedFinal { return nil }
            return "[focus_click] cuối: `\(got)` mong `\(testCase.expectedFinal)` — \(testCase.note)"
        }
    }
}
