import Foundation
import ToolVNCore

/// Click / focus + gõ / xóa / sửa — mô phỏng document có vị trí con trỏ (UTF-16).
public enum ComprehensiveFocusAndEditFixtures {
    public struct Case: Sendable {
        public let category: String
        public let keys: [IMEUserKey]
        public let expectedFinal: String
        public let note: String
    }

    public static let all: [Case] =
        clickInsert
        + clickMidEdit
        + clickThenDeleteRetype
        + clickAfterSpace
        + trickyWordsAtCaret

    public static func expectedDocument(keys: [IMEUserKey]) -> String {
        FocusClickTypingSimulator.finalDocument(keys: keys)
    }

    // MARK: - Data

    private static let clickInsert: [Case] = [
        fc("focus_insert", t("vieetj ") + click(0) + t("xin"), "xinviệt ", "đầu dòng + xin"),
        fc("focus_insert", t("vieetj ") + click(0) + t("chaof "), nil, "đầu + chào space"),
        fc("focus_insert", t("abc ") + click(0) + t("guiwr "), "gửi abc ", "gửi đầu dòng"),
        fc("focus_insert", t("Tooi laf ") + click(0) + t("ratj "), nil, "rất đầu câu"),
        fc("focus_insert", t("guiwr") + click(0) + t("xin"), "xingửi", "chưa space, đầu xin"),
        fc("focus_insert", t("hopwj ") + click(0) + t("laf "), "là hợp ", "hợp, đầu là"),
        fc("focus_insert", t("vieetj Nam ") + click(0) + t("dduwowngf "), nil, "đường đầu"),
    ]

    private static let clickMidEdit: [Case] = [
        fc("focus_mid", t("Hoom nay ") + click(4) + t("trowif"), nil, "giữa Hôm → trời"),
        fc("focus_mid", t("xin chaof ") + click(3) + t("banj"), nil, "giữa xin chào"),
        fc("focus_mid", t("Kieemr tra ") + click(5) + t("quas"), nil, "giữa Kiểm"),
        fc("focus_mid", t("nguowif Vieetj ") + click(7) + t("dduwowngf"), nil, "giữa người"),
        fc("focus_mid", t("camr on banj ") + click(4) + t("nhieeuf"), nil, "giữa cảm ơn"),
    ]

    private static let clickThenDeleteRetype: [Case] = [
        fc(
            "focus_edit",
            t("vieetj") + click(0) + bs(2) + t("Vieetj"),
            "Việtviệt",
            "click đầu, xóa 2 telex, gõ Việt"
        ),
        fc(
            "focus_edit",
            t("vieetj ") + click(0) + t("xin") + bs(3) + t("chaof"),
            "chàoviệt ",
            "đầu xin → xóa → chào"
        ),
        fc(
            "focus_edit",
            t("hopwj ") + click(0) + bs(1) + t("H"),
            nil,
            "đầu xóa 1 rồi H"
        ),
        fc(
            "focus_edit",
            t("guiwr ddi ") + click(0) + bs(2) + t("Nhanh"),
            "Nhanhgửi đi ",
            "sửa đầu câu"
        ),
        fc(
            "focus_edit",
            t("xoas ") + click(0) + bs(4) + t("vieetj"),
            "việtxóa ",
            "đầu xóa xóa → việt"
        ),
    ]

    private static let clickAfterSpace: [Case] = [
        fc("focus_after_space", t("vieetj ") + click(end("vieetj ")) + t("xin"), "việt xin", "cuối từ, thêm xin"),
        fc("focus_after_space", t("hopwj ") + click(end("hopwj ")) + bs(1) + t("l"), "hợpl", "cuối xóa space"),
        fc(
            "focus_after_space",
            t("Tooi ") + click(end("Tooi ")) + t("laf nguowif"),
            "Tôi là người",
            "cuối Tôi + là người"
        ),
    ]

    private static let trickyWordsAtCaret: [Case] = [
        fc("focus_tricky", t("how ") + click(0) + t("vieetj "), "việt how ", "how + việt"),
        fc("focus_tricky", t("show ") + click(0) + t("hopwj "), "hợp show ", "show + hợp"),
        fc("focus_tricky", t("vieetj ") + click(0) + t("guiwr "), "gửi việt ", "việt + gửi đầu"),
        fc("focus_tricky", t("dduwowngf ") + click(0) + t("truowngf "), "trường đường ", "đường trường"),
    ]

    // MARK: - Builders

    private static func t(_ s: String) -> [IMEUserKey] { IMEUserKeyBuilders.telex(s) }

    private static func click(_ utf16: Int) -> [IMEUserKey] { [.caretAtUTF16(utf16)] }

    private static func bs(_ n: Int) -> [IMEUserKey] { Array(repeating: .backspace, count: n) }

    private static func end(_ telexPrefix: String) -> Int {
        (expectedDocument(keys: t(telexPrefix)) as NSString).length
    }

    private static func fc(
        _ category: String,
        _ keys: [IMEUserKey],
        _ mustBe: String?,
        _ note: String
    ) -> Case {
        Case(
            category: category,
            keys: keys,
            expectedFinal: mustBe ?? expectedDocument(keys: keys),
            note: note
        )
    }
}

public enum ComprehensiveFocusAndEditRunner {
    public static func summary() -> String {
        let all = ComprehensiveFocusAndEditFixtures.all
        let by = Dictionary(grouping: all, by: \.category)
        let parts = by.keys.sorted().map { "\($0): \(by[$0]?.count ?? 0)" }
        return "Focus/sửa/click: \(all.count) (\(parts.joined(separator: ", ")))"
    }

    public static func run() -> [String] {
        ComprehensiveFocusAndEditFixtures.all.compactMap { testCase in
            let got = ComprehensiveFocusAndEditFixtures.expectedDocument(keys: testCase.keys)
            if got == testCase.expectedFinal { return nil }
            return "[\(testCase.category)] cuối: `\(got)` mong `\(testCase.expectedFinal)` — \(testCase.note)"
        }
    }
}
