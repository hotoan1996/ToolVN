import Foundation
import ToolVNCore

/// Xóa (Delete) rồi gõ tiếp — trong cùng từ đang compose hoặc bắt đầu từ mới.
public enum DeleteContinueIntent: String, Sendable, CaseIterable {
    case continueCurrentWord
    case startNewWord
    case afterCommitted
}

public struct DeleteAndContinueCase: Sendable {
    public let intent: DeleteContinueIntent
    public let keys: [IMEUserKey]
    public let expectedFinal: String
    public let note: String

    public var category: String { "delete_\(intent.rawValue)" }

    public init(
        intent: DeleteContinueIntent,
        keys: [IMEUserKey],
        expectedFinal: String,
        note: String = ""
    ) {
        self.intent = intent
        self.keys = keys
        self.expectedFinal = expectedFinal
        self.note = note
    }
}

public enum DeleteAndContinueTypingFixtures {
    public static let all: [DeleteAndContinueCase] =
        continueInCurrentWord
        + startNewWordAfterClear
        + afterCommittedWord
        + markAndMangleChains

    // MARK: - Tiếp tục trong từ đang gõ

    private static let continueInCurrentWord: [DeleteAndContinueCase] = [
        c(.continueCurrentWord, t("xoa") + bs(1) + t("a"), note: "xoa sửa a", mustBe: "xoa"),
        c(.continueCurrentWord, t("xoaa") + bs(2) + t("a"), note: "xoâ → xo → a", mustBe: "xoa"),
        c(.continueCurrentWord, t("xoas") + bs(2) + t("as"), note: "xóa sửa s", mustBe: "xóa"),
        c(.continueCurrentWord, t("xoas") + bs(1) + t("s"), note: "xóa sửa s cuối", mustBe: "xóa"),
        c(.continueCurrentWord, t("vieetj") + bs(2) + t("tj"), note: "việt gõ lại tj"),
        c(.continueCurrentWord, t("vieetj") + bs(1) + t("j"), note: "việt xóa j gõ lại"),
        c(.continueCurrentWord, t("Kieemr") + bs(1) + t("r tra"), note: "Kiểm tra"),
        c(.continueCurrentWord, t("nguowif") + bs(1) + t("f"), note: "người"),
        c(.continueCurrentWord, t("trowif") + bs(1) + t("f"), note: "trời"),
        c(.continueCurrentWord, t("hoocj") + bs(1) + t("j"), note: "học"),
        c(.continueCurrentWord, t("dduwowcj") + bs(1) + t("j"), note: "được"),
        c(.continueCurrentWord, t("dduwowngf") + bs(2) + t("gf"), note: "đường"),
        c(.continueCurrentWord, t("tuowng") + bs(2) + t("ng"), note: "tương"),
        c(.continueCurrentWord, t("giuwx") + bs(1) + t("x"), note: "giữ"),
        c(.continueCurrentWord, t("mootj") + bs(1) + t("j"), note: "một"),
        c(.continueCurrentWord, t("camr") + bs(1) + t("r"), note: "cảm"),
        c(.continueCurrentWord, t("quys") + bs(1) + t("s"), note: "quý"),
        c(.continueCurrentWord, t("aas") + bs(1) + t("s"), note: "ấ → ss → âs"),
        c(.continueCurrentWord, t("as") + bs(1) + t("s"), note: "as xóa s gõ lại"),
        c(.continueCurrentWord, t("xoax") + bs(1) + t("s"), note: "nhầm x → s", mustBe: "xóa"),
        c(.continueCurrentWord, t("xo") + t("as"), note: "xo + as trong cùng từ", mustBe: "xóa"),
        c(.continueCurrentWord, t("xo") + bs(1) + t("as"), note: "x xóa o gõ as"),
        c(.continueCurrentWord, t("tieens") + bs(1) + t("s"), note: "tiến"),
        c(.continueCurrentWord, t("nhieeuf") + bs(1) + t("f"), note: "nhiều"),
        c(.continueCurrentWord, t("khoongf") + bs(1) + t("f"), note: "khồng"),
        c(.continueCurrentWord, t("Vieetj") + bs(1) + t("j"), note: "Việt hoa"),
        c(.continueCurrentWord, t("truowngf") + bs(1) + t("f"), note: "trường"),
    ]

    // MARK: - Xóa hết / chuyển sang từ mới

    private static let startNewWordAfterClear: [DeleteAndContinueCase] = [
        c(.startNewWord, t("xoaa") + bs(4) + t("trowif"), note: "xoâ xóa hết → trời"),
        c(.startNewWord, t("vieetj") + bs(6) + t("xin"), note: "việt xóa hết telex → xin"),
        c(.startNewWord, t("xoas") + bs(4) + t("vieetj"), note: "xóa xóa hết → việt"),
        c(.startNewWord, t("Kieemr") + bs(6) + t("hoocj"), note: "Kiểm xóa hết → học"),
        c(.startNewWord, t("nguowif") + bs(7) + t("Vieetj"), note: "người xóa hết → Việt"),
        c(.startNewWord, t("dduwowcj") + bs(8) + t("camr"), note: "được xóa hết → cảm"),
        c(.startNewWord, t("xoaa") + bs(2) + t("as"), note: "từ xo gõ as → xóa", mustBe: "xóa"),
        c(
            .startNewWord,
            t("xoaa") + bs(2) + t("xoas"),
            note: "regression: buffer xo mà gõ lại xoas",
            mustBe: "xóa"
        ),
        c(.startNewWord, t("aas") + bs(3) + t("vieetj"), note: "ấ xóa hết → việt"),
        c(.startNewWord, t("quas") + bs(4) + t("quys"), note: "quá xóa hết → quý"),
        c(.startNewWord, t("hoocj") + bs(5) + t("mootj"), note: "học xóa hết → một"),
        c(.startNewWord, t("trowif") + bs(5) + t("mootj"), note: "trời → một"),
        c(.startNewWord, t("xoas") + bs(4) + t("xin"), note: "xóa hết → xin"),
    ]

    // MARK: - Sau space (chữ đã nằm trên document)

    private static let afterCommittedWord: [DeleteAndContinueCase] = [
        c(.afterCommitted, t("vieetj ") + t("trowif"), note: "việt + trời có space"),
        c(.afterCommitted, t("vieetj ") + bs(1) + t("trowif"), note: "xóa space rồi trời dính"),
        c(.afterCommitted, t("vieetj ") + bs(1) + t(" trowif"), note: "xóa rồi space + trời"),
        c(.afterCommitted, t("Tooi ") + t("laf"), note: "Tôi là"),
        c(.afterCommitted, t("vieetj ") + bs(2) + t("xin"), note: "xóa cuối việt + xin"),
        c(.afterCommitted, t("camr ") + t("on"), note: "cảm + on"),
        c(.afterCommitted, t("Hoom nay ") + t("trowif"), note: "Hôm nay trời"),
        c(.afterCommitted, t("vieetj ") + bs(2) + t("t"), note: "việt xóa 2 rồi t"),
        c(.afterCommitted, t("mootj ") + t("hai"), note: "một hai"),
        c(.afterCommitted, t("xoas ") + bs(2) + t("vieetj"), note: "xóa + việt"),
        c(.afterCommitted, t("Kieemr tra ") + t("quas"), note: "Kiểm tra quá"),
        c(.afterCommitted, t("vieetj ") + bs(1) + t(" "), note: "thêm space"),
        c(.afterCommitted, t("Tooi laf ") + t("nguowif"), note: "Tôi là người"),
    ]

    // MARK: - Chuỗi dấu / mũ / đổi thanh

    private static let markAndMangleChains: [DeleteAndContinueCase] = [
        c(.continueCurrentWord, t("asf") + bs(2) + t("s"), note: "asf → á"),
        c(.continueCurrentWord, t("camrs") + bs(1), note: "thừa s"),
        c(.continueCurrentWord, t("quass") + bs(1), note: "ss bỏ dấu"),
        c(.continueCurrentWord, t("mootjf") + bs(1), note: "nhầm f"),
        c(.continueCurrentWord, t("vieetj") + t("z") + bs(1), note: "z nhầm"),
        c(.continueCurrentWord, t("aasf") + bs(1) + t("s"), note: "â đổi thanh"),
        c(.continueCurrentWord, t("uwsf") + bs(2) + t("s"), note: "ư đổi thanh"),
        c(.startNewWord, t("vieetj") + t("z") + bs(2) + t("hoocj"), note: "z + xóa z → học mới"),
        c(.continueCurrentWord, t("dd") + bs(1) + t("d"), note: "đ"),
        c(.continueCurrentWord, t("dd") + bs(2) + t("d"), note: "dd → d"),
        c(.continueCurrentWord, t("ass") + bs(1), note: "ass xóa s"),
        c(.continueCurrentWord, t("hopwj") + bs(1) + t("j"), note: "hợp sửa j", mustBe: "hợp"),
        c(.continueCurrentWord, t("hopw") + t("j"), note: "hơp + j → hợp", mustBe: "hợp"),
        c(.continueCurrentWord, t("guiwr") + bs(1) + t("r"), note: "gửi sửa r"),
        c(.continueCurrentWord, t("guiw") + bs(1) + t("r"), note: "gưi + r"),
        c(.continueCurrentWord, t("how") + bs(1) + t("w"), note: "how sửa w"),
        c(.afterCommitted, t("hopwj ") + bs(1) + t("laf "), note: "hợp space xóa space là"),
        c(.afterCommitted, t("guiwr ") + bs(2) + t("ddi"), note: "gửi xóa 2 gõ đi"),
        c(.startNewWord, t("hopwj") + bs(5) + t("how"), note: "hợp xóa hết → how"),
        c(.startNewWord, t("guiwr") + bs(5) + t("vieetj"), note: "gửi xóa hết → việt"),
        c(.continueCurrentWord, t("uowj") + bs(1) + t("j"), note: "ượ sửa j"),
        c(.continueCurrentWord, t("dduwowngf") + bs(3) + t("ngf"), note: "đường sửa ngf"),
        c(.continueCurrentWord, t("vieetjs") + bs(1) + t("j"), note: "việts xóa s gõ j"),
    ]

    // MARK: - Builders

    private static func t(_ s: String) -> [IMEUserKey] { IMEUserKeyBuilders.telex(s) }

    private static func bs(_ count: Int) -> [IMEUserKey] {
        Array(repeating: .backspace, count: count)
    }

    /// `mustBe`: kỳ vọng hành vi người dùng (IME phải đạt). Không truyền thì lấy từ simulator (hợp đồng nội bộ).
    private static func c(
        _ intent: DeleteContinueIntent,
        _ keys: [IMEUserKey],
        note: String,
        mustBe: String? = nil
    ) -> DeleteAndContinueCase {
        let simulated = IMEControllerTypingSimulator.finalDocument(keys: keys)
        let expected = mustBe ?? simulated
        return DeleteAndContinueCase(intent: intent, keys: keys, expectedFinal: expected, note: note)
    }
}

public enum DeleteAndContinueTypingRunner {
    public static func run(_ cases: [DeleteAndContinueCase] = DeleteAndContinueTypingFixtures.all) -> [String] {
        cases.flatMap { runOne($0) }
    }

    public static func runOne(_ testCase: DeleteAndContinueCase) -> [String] {
        let steps = IMEControllerTypingSimulator.replay(keys: testCase.keys)
        let sessionSteps = IMEInteractionReplay.sessionVisibleSteps(keys: testCase.keys)
        var errors: [String] = []
        let tag = "[\(testCase.category)]"

        for step in steps {
            let doc = step.document
            let idx = step.index
            let skipSession = testCase.keys.contains(where: { if case .caretAtUTF16 = $0 { return true }; return false })
            if !skipSession, idx <= sessionSteps.count, doc != sessionSteps[idx - 1] {
                errors.append("\(tag) bước \(idx): document=`\(doc)` session=`\(sessionSteps[idx - 1])` — \(testCase.note)")
            }
            if IMEDuplicatePatternDetector.hasGrowingPrefixGlitch(doc) {
                errors.append("\(tag) bước \(idx): glitch prefix — \(testCase.note)")
            }
            if IMEDuplicatePatternDetector.hasAdjacentDuplicateChunk(doc) {
                errors.append("\(tag) bước \(idx): chunk lặp — \(testCase.note)")
            }
        }

        if let last = steps.last?.document {
            if last != testCase.expectedFinal {
                errors.append("\(tag) cuối: `\(last)` mong `\(testCase.expectedFinal)` — \(testCase.note)")
            }
            if testCase.expectedFinal == "xoa", last == "xoâ" {
                errors.append("\(tag) cuối: xoâ thay vì xoa — \(testCase.note)")
            }
            if testCase.expectedFinal == "xóa", last == "xoóa" || last == "xoâ" {
                errors.append("\(tag) cuối: `\(last)` sai (mong xóa) — \(testCase.note)")
            }
        }

        return errors
    }

    public static func summary() -> String {
        let all = DeleteAndContinueTypingFixtures.all
        let byIntent = Dictionary(grouping: all, by: \.intent)
        let lines = DeleteContinueIntent.allCases.map { intent in
            let n = byIntent[intent]?.count ?? 0
            return "  delete_\(intent.rawValue): \(n)"
        }
        return "Xóa + gõ tiếp: \(all.count) kịch bản (\(lines.joined(separator: ", ")))"
    }

    public static func runFiltered(category: String) -> [String] {
        let cases = DeleteAndContinueTypingFixtures.all.filter { $0.category == category }
        return run(cases)
    }
}
