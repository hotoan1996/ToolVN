import Foundation
import ToolVNCore

public struct TypingSequenceCase: Sendable {
    public let category: String
    public let keystrokes: String
    public let expectedFinal: String
    public let note: String
    public let method: VietnameseInputMethod

    public init(
        category: String,
        keystrokes: String,
        expectedFinal: String,
        note: String = "",
        method: VietnameseInputMethod = .telex
    ) {
        self.category = category
        self.keystrokes = keystrokes
        self.expectedFinal = expectedFinal
        self.note = note
        self.method = method
    }
}

public struct TypingStepFailure: Sendable {
    public let testCase: TypingSequenceCase
    public let step: Int
    public let keystrokePrefix: String
    public let expectedVisible: String
    public let actualVisible: String
    public let reason: String
}

public enum TypingSessionFixtures {
    /// Gõ từng ký tự — kiểm tra preedit sau mỗi bước không bị chồng (Kiểm, việt, …).
    public static let incrementalWords: [TypingSequenceCase] = [
        .init(category: "incremental", keystrokes: "vieetj", expectedFinal: "việt"),
        .init(category: "incremental", keystrokes: "Kieemr", expectedFinal: "Kiểm", note: "Docs Safari — chữ hoa đầu"),
        .init(category: "incremental", keystrokes: "Kieemr tra", expectedFinal: "Kiểm tra"),
        .init(category: "incremental", keystrokes: "hoocj", expectedFinal: "h\u{1ED9}c"),
        .init(category: "incremental", keystrokes: "dduwowcj", expectedFinal: "được"),
        .init(category: "incremental", keystrokes: "nguowif", expectedFinal: "người"),
        .init(category: "incremental", keystrokes: "khoongf", expectedFinal: "khồng"),
        .init(category: "incremental", keystrokes: "tieens", expectedFinal: "tiến"),
        .init(category: "incremental", keystrokes: "dduwowngf", expectedFinal: "đường"),
        .init(category: "incremental", keystrokes: "truowngf", expectedFinal: "trường"),
        .init(category: "incremental", keystrokes: "nhieeuf", expectedFinal: "nhiều"),
        .init(category: "incremental", keystrokes: "mootj", expectedFinal: "một"),
        .init(category: "incremental", keystrokes: "camr", expectedFinal: "cảm"),
        .init(category: "incremental", keystrokes: "quys", expectedFinal: "quý"),
        .init(category: "incremental", keystrokes: "tuwf", expectedFinal: "từ"),
        .init(category: "incremental", keystrokes: "Tooi", expectedFinal: "Tôi"),
        .init(category: "incremental", keystrokes: "Vieetj", expectedFinal: "Việt"),
    ]

    public static let sentences: [TypingSequenceCase] = [
        .init(
            category: "sentence",
            keystrokes: "Kieemr tra quas",
            expectedFinal: "Kiểm tra quá"
        ),
        .init(
            category: "sentence",
            keystrokes: "Tooi laf nguowif Vieetj Nam",
            expectedFinal: "Tôi là người Việt Nam"
        ),
        .init(
            category: "sentence",
            keystrokes: "Hoom nay trowif ddepj quas",
            expectedFinal: "Hôm nay trời đẹp quá"
        ),
        .init(
            category: "sentence",
            keystrokes: "ToolVN hoox trowj gox tieesng Vieetj",
            expectedFinal: "ToolVN hỗ trợ gõ tiếng Việt"
        ),
    ]

    public static let punctuationAfterCompose: [TypingSequenceCase] = [
        .init(category: "punctuation", keystrokes: "vieetj,", expectedFinal: "việt,", note: "không ,,"),
        .init(category: "punctuation", keystrokes: "camr,", expectedFinal: "cảm,", note: "dấu sau thanh"),
        .init(category: "punctuation", keystrokes: "quas,", expectedFinal: "quá,", note: "sắc + phẩy"),
        .init(category: "punctuation", keystrokes: "xin chaf.", expectedFinal: "xin chà.", note: "chaf → chà"),
        .init(category: "punctuation", keystrokes: "mootj, hai.", expectedFinal: "một, hai.", note: "phẩy + chấm"),
        .init(category: "punctuation", keystrokes: "(mootj)", expectedFinal: "(một)", note: "ngoặc"),
        .init(category: "punctuation", keystrokes: "a,", expectedFinal: "a,", note: "một chữ + phẩy"),
        .init(category: "punctuation", keystrokes: "as,", expectedFinal: "á,", note: "một âm + phẩy"),
    ]

    public static let toneKeystrokes: [TypingSequenceCase] = [
        .init(category: "tone", keystrokes: "as", expectedFinal: "á"),
        .init(category: "tone", keystrokes: "asf", expectedFinal: "à", note: "đổi sắc → huyền"),
        .init(category: "tone", keystrokes: "asr", expectedFinal: "ả"),
        .init(category: "tone", keystrokes: "asx", expectedFinal: "ã"),
        .init(category: "tone", keystrokes: "asj", expectedFinal: "ạ"),
        .init(category: "tone", keystrokes: "aas", expectedFinal: "ấ"),
        .init(category: "tone", keystrokes: "aasf", expectedFinal: "ầ", note: "â + đổi thanh"),
        .init(category: "tone", keystrokes: "uws", expectedFinal: "ứ"),
        .init(category: "tone", keystrokes: "uwsf", expectedFinal: "ừ"),
        .init(category: "tone", keystrokes: "ows", expectedFinal: "ớ"),
        .init(category: "tone", keystrokes: "ees", expectedFinal: "ế"),
        .init(category: "tone", keystrokes: "tieens", expectedFinal: "tiến"),
        .init(category: "tone", keystrokes: "dduwowngf", expectedFinal: "đường"),
        .init(category: "tone", keystrokes: "nuowcs", expectedFinal: "nước"),
        .init(category: "tone", keystrokes: "trowif", expectedFinal: "trời"),
        .init(category: "tone", keystrokes: "ddeem", expectedFinal: "đêm"),
        .init(category: "tone", keystrokes: "sass", expectedFinal: "sas", note: "s + a + ss bỏ dấu"),
        .init(category: "tone", keystrokes: "quass", expectedFinal: "quas", note: "quá rồi ss"),
        .init(category: "tone", keystrokes: "vieetjz", expectedFinal: "viêt", note: "z bỏ thanh"),
    ]

    public static let navigationCommit: [TypingSequenceCase] = [
        .init(category: "navigation", keystrokes: "vieetj", expectedFinal: "việt", note: "commit khi rời từ (mũi tên)"),
        .init(category: "navigation", keystrokes: "Kieemr", expectedFinal: "Kiểm"),
        .init(category: "navigation", keystrokes: "dduwowcj", expectedFinal: "được"),
    ]

    public static let spaceCases: [TypingSequenceCase] = [
        .init(category: "space", keystrokes: "vieetj ", expectedFinal: "việt ", note: "một space sau từ"),
        .init(category: "space", keystrokes: "vieetj  ", expectedFinal: "việt  ", note: "hai space cố ý"),
        .init(category: "space", keystrokes: "vieetj xin", expectedFinal: "việt xin"),
        .init(category: "space", keystrokes: "a  b", expectedFinal: "a  b", note: "giữ khoảng đôi giữa ký tự"),
        .init(category: "space", keystrokes: "mootj hai", expectedFinal: "một hai"),
    ]

    public static let dupGuardCases: [TypingSequenceCase] = [
        .init(category: "dup_guard", keystrokes: "Kieemr", expectedFinal: "Kiểm"),
        .init(category: "dup_guard", keystrokes: "Kieemr tra quas", expectedFinal: "Kiểm tra quá"),
        .init(category: "dup_guard", keystrokes: "vieetj xin chaf", expectedFinal: "việt xin chà"),
        .init(category: "dup_guard", keystrokes: "trowif", expectedFinal: "trời"),
        .init(category: "dup_guard", keystrokes: "gox tieesng Vieetj", expectedFinal: "gõ tiếng Việt"),
        .init(category: "dup_guard", keystrokes: "vieetj,", expectedFinal: "việt,"),
        .init(category: "dup_guard", keystrokes: "vieetj ", expectedFinal: "việt "),
    ]

    public static var all: [TypingSequenceCase] {
        incrementalWords + spaceCases + dupGuardCases + punctuationAfterCompose + toneKeystrokes
            + navigationCommit + TelexTestMatrix.typingCases + TelexLongPassages.allTypingCases + sentences
            + TelexCorpus.typingCases.filter { c in
            !incrementalWords.contains(where: { $0.keystrokes == c.keystrokes })
                && !sentences.contains(where: { $0.keystrokes == c.keystrokes })
        }
    }
}

public enum TypingSessionRunner {
    public static func run(_ cases: [TypingSequenceCase] = TypingSessionFixtures.all) -> [TypingStepFailure] {
        PerKeystrokeTypingRunner.run(cases)
    }

    public static func runOne(_ testCase: TypingSequenceCase) -> [TypingStepFailure] {
        PerKeystrokeTypingRunner.runOne(testCase)
    }

    /// Đảm bảo mô hình lỗi Safari tạo glitch; mô hình đúng thì không.
    public static func runSafariRegression() -> [String] {
        var errors: [String] = []
        if !SafariInsertBugSimulator.producesKnownGlitch(keystrokes: "Kieemr") {
            errors.append("Safari simulator: Kieemr phải tạo lỗi chồng chữ")
        }
        var session = IMEComposeSession()
        for ch in "Kieemr" {
            session.typeCharacter(ch)
        }
        if IMEDuplicatePatternDetector.hasGrowingPrefixGlitch(session.visibleText) {
            errors.append("IMEComposeSession: Kieemr không được chồng chữ")
        }
        if session.visibleText != "Kiểm" {
            errors.append("IMEComposeSession: Kieemr → Kiểm, got \(session.visibleText)")
        }

        let legacyComma = IMEDoublePunctuationSimulator.legacyVisibleAfterPunctuation(
            committedVisible: "việt",
            punctuation: ","
        )
        if legacyComma != "việt,," {
            errors.append("Double-punct simulator: kỳ vọng việt,, got \(legacyComma)")
        }
        var punctSession = IMEComposeSession()
        for ch in "vieetj," {
            punctSession.typeCharacter(ch)
        }
        if punctSession.visibleText != "việt," {
            errors.append("Dấu câu: vieetj, → việt,, got \(punctSession.visibleText)")
        }
        if IMEDoublePunctuationSimulator.hasDuplicatedPunctuation(punctSession.visibleText) {
            errors.append("Dấu câu: không được ,, trong visible")
        }

        let brokenNav = IMEMarkedCommitSimulator.brokenCommit(committed: "abc ", preedit: "việt")
        if brokenNav != "abc việtviệt" {
            errors.append("Marked commit simulator: kỳ vọng nhân đôi preedit")
        }
        var navSession = IMEComposeSession()
        for ch in "vieetj" { navSession.typeCharacter(ch) }
        navSession.commitCurrentWord()
        if navSession.visibleText != "việt" {
            errors.append("Navigation commit: vieetj → việt, got \(navSession.visibleText)")
        }

        let legacySpace = IMEDoubleSpaceSimulator.legacyAfterOneSpaceKey(visibleBeforeSpace: "việt")
        if legacySpace != "việt  " {
            errors.append("Double-space simulator: một phím space → hai space")
        }
        var spaceSession = IMEComposeSession()
        for ch in "vieetj " { spaceSession.typeCharacter(ch) }
        if spaceSession.visibleText != "việt " {
            errors.append("Space: vieetj + space → «việt », got «\(spaceSession.visibleText)»")
        }
        if spaceSession.visibleText == IMEDoubleSpaceSimulator.legacyAfterOneSpaceKey(visibleBeforeSpace: "việt") {
            errors.append("Space: không được thêm space đôi sau một lần gõ space")
        }

        let replaceModel = IMEReplacementRangeSimulator.correctVisible(keystrokes: "Kieemr tra")
        if replaceModel != PerKeystrokeTypingEngine.finalVisible("Kieemr tra") {
            errors.append("Replacement range cuối: Kieemr tra khác gõ từng phím")
        }
        errors.append(
            contentsOf: PerKeystrokeTypingRunner.runControllerConformance(
                samples: ["Kieemr", "Kieemr tra", "vieetj ", "vieetj xin", "Hoom nay trowif ddepj quas."]
            )
        )

        if IMEDoubleSpaceEventSimulator.twoPassThroughAfterWord("việt") != "việt  " {
            errors.append("Simulator: hai pass-through space")
        }

        errors.append(contentsOf: IMEControllerPolicyRegression.run())

        errors.append(contentsOf: BackspaceInteractionRunner.run())

        errors.append(contentsOf: UserTypingJourneyRunner.run())

        errors.append(contentsOf: DeleteAndContinueTypingRunner.run())

        errors.append(contentsOf: FocusClickTypingRunner.run())

        errors.append(contentsOf: RealUserContextRunner.run())

        errors.append(contentsOf: ComprehensiveFocusAndEditRunner.run())

        return errors
    }
}
