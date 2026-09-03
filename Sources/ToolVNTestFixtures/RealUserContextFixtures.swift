import Foundation
import ToolVNCore

/// Một kịch bản gõ Telex — kỳ vọng lấy từ **gõ từng phím** (`IMEComposeSession`), không phải chỉ `transform(cả chuỗi)`.
public struct RealUserTypingScenario: Sendable {
    public let category: String
    public let telex: String
    public let note: String

    public init(category: String, telex: String, note: String = "") {
        self.category = category
        self.telex = telex
        self.note = note
    }

    /// Văn bản người dùng thấy sau khi gõ hết `telex` (một phím một bước).
    public var expectedPerKeystroke: String {
        PerKeystrokeTypingEngine.finalVisible(telex)
    }
}

/// Tập case mô phỏng người dùng thật: từ / câu / hỗn ngữ / IME controller (document).
public enum RealUserContextFixtures {
    public static let scenarios: [RealUserTypingScenario] =
        toneGrid
        + vowelMarks
        + placementWords
        + dailyWords
        + trickyOWAndW
        + mixedLanguage
        + punctuationPhrases
        + shortSentences

    /// Gõ cả cụm (có space) qua simulator controller — mỗi ký tự một phím.
    public static let controllerPhrases: [UserTypingJourneyCase] = [
        journey("real_ctrl", "vieetj ", "việt ", "space chốt từ"),
        journey("real_ctrl", "vieetj xin ", "việt xin ", "hai từ + space"),
        journey("real_ctrl", "Kieemr tra quas ", "Kiểm tra quá ", "câu ngắn Docs"),
        journey("real_ctrl", "hopwj laf ", "hợp là ", "hợp + là"),
        journey("real_ctrl", "guiwr ddi ", "gửi đi ", "gửi + đi"),
        journey("real_ctrl", "how ", "how ", "tiếng Anh + space"),
        journey("real_ctrl", "Tooi laf nguowif Vieetj Nam ", "Tôi là người Việt Nam ", "câu quốc gia"),
        journey("real_ctrl", "Hoom nay trowif ddepj quas.", "Hôm nay trời đẹp quá.", "câu + chấm"),
        journey("real_ctrl", "dduwowcj, camr own.", "được, cảm ơn.", "dấu câu sau từ"),
    ]

    public static var typingSequenceCases: [TypingSequenceCase] {
        scenarios.map {
            TypingSequenceCase(
                category: $0.category,
                keystrokes: $0.telex,
                expectedFinal: $0.expectedPerKeystroke,
                note: $0.note
            )
        }
    }

    public static var engineCases: [IMETestCase] {
        scenarios.map {
            IMETestCase(
                category: $0.category,
                input: $0.telex,
                expected: $0.expectedPerKeystroke,
                note: $0.note
            )
        }
    }

    // MARK: - Builders

    private static func journey(
        _ category: String,
        _ telex: String,
        _ expected: String,
        _ note: String
    ) -> UserTypingJourneyCase {
        UserTypingJourneyCase(
            category: category,
            keys: IMEUserKeyBuilders.telex(telex),
            expectedFinal: expected,
            note: note
        )
    }

    private static func s(_ category: String, _ telex: String, _ note: String = "") -> RealUserTypingScenario {
        RealUserTypingScenario(category: category, telex: telex, note: note)
    }

    // MARK: - Thanht điệu (a e i o u y)

    private static let toneGrid: [RealUserTypingScenario] = {
        let stems: [(String, String)] = [
            ("a", "a"), ("aa", "â"), ("aw", "ă"),
            ("e", "e"), ("ee", "ê"),
            ("o", "o"), ("oo", "ô"), ("ow", "ơ"),
            ("u", "u"), ("uw", "ư"),
            ("i", "i"), ("y", "y"),
        ]
        let keys: [(Character, String)] = [
            ("s", "sắc"), ("f", "huyền"), ("r", "hỏi"), ("x", "ngã"), ("j", "nặng"),
        ]
        return stems.flatMap { stem, _ in
            keys.map { key, label in
                s("real_tone", stem + String(key), "\(stem)+\(key) (\(label))")
            }
        }
    }()

    // MARK: - Mũ / đ

    private static let vowelMarks: [RealUserTypingScenario] = [
        s("real_mark", "dd", "đ"),
        s("real_mark", "DD", "Đ"),
        s("real_mark", "uow", "ươ"),
        s("real_mark", "uows", "ướ"),
        s("real_mark", "uowj", "ượ"),
        s("real_mark", "uowng", "ương"),
        s("real_mark", "dduwowngf", "đường"),
        s("real_mark", "nguowif", "người"),
        s("real_mark", "truowngf", "trường"),
        s("real_mark", "dduwowcj", "được"),
        s("real_mark", "nuowcs", "nước"),
        s("real_mark", "phuwowng", "phương"),
        s("real_mark", "thuwowng", "thương"),
        s("real_mark", "quyeenf", "quyền"),
        s("real_mark", "bieeur", "biểu"),
        s("real_mark", "tieens", "tiến"),
        s("real_mark", "dduwx", "đứ"),
    ]

    // MARK: - Từ vựng hàng ngày

    private static let dailyWords: [RealUserTypingScenario] = [
        s("real_word", "xin", "xin"),
        s("real_word", "chaof", "chào"),
        s("real_word", "camr", "cảm"),
        s("real_word", "own", "ơn"),
        s("real_word", "Vieetj", "Việt"),
        s("real_word", "Nam", "Nam"),
        s("real_word", "Tooi", "Tôi"),
        s("real_word", "banj", "bạn"),
        s("real_word", "nha", "nha"),
        s("real_word", "khoongf", "không"),
        s("real_word", "coos", "có"),
        s("real_word", "mootj", "một"),
        s("real_word", "hai", "hai"),
        s("real_word", "ba", "ba"),
        s("real_word", "nhieeuf", "nhiều"),
        s("real_word", "it", "it"),
        s("real_word", "rat", "rat"),
        s("real_word", "quas", "quá"),
        s("real_word", "ratj", "rất"),
        s("real_word", "hoocj", "học"),
        s("real_word", "lamf", "làm"),
        s("real_word", "vieecj", "việc"),
        s("real_word", "nawm", "năm"),
        s("real_word", "thang", "thang"),
        s("real_word", "ngayf", "ngày"),
        s("real_word", "dem", "dem"),
        s("real_word", "trowif", "trời"),
        s("real_word", "mua", "mua"),
        s("real_word", "nong", "nong"),
        s("real_word", "lanh", "lanh"),
        s("real_word", "depj", "đẹp"),
        s("real_word", "xau", "xau"),
        s("real_word", "tot", "tot"),
        s("real_word", "gox", "gõ"),
        s("real_word", "tieesng", "tiếng"),
        s("real_word", "chuwx", "chữ"),
        s("real_word", "Kieemr", "Kiểm"),
        s("real_word", "tra", "tra"),
        s("real_word", "thuws", "thứ"),
        s("real_word", "tuwf", "từ"),
        s("real_word", "cau", "cau"),
        s("real_word", "hoi", "hoi"),
        s("real_word", "traaloi", "traaloi"),
        s("real_word", "cuocj", "cuộc"),
        s("real_word", "song", "song"),
        s("real_word", "ddoi", "đoi"),
        s("real_word", "gia", "gia"),
        s("real_word", "dinfh", "dinfh"),
        s("real_word", "thanh", "thanh"),
        s("real_word", "phoos", "phố"),
        s("real_word", "quan", "quan"),
        s("real_word", "xa", "xa"),
        s("real_word", "nho", "nho"),
        s("real_word", "lon", "lon"),
    ]

    private static let placementWords: [RealUserTypingScenario] = [
        s("real_place", "laf", "là"),
        s("real_place", "lafm", "làm"),
        s("real_place", "dduwowngf", "đường"),
        s("real_place", "truowngf", "trường"),
        s("real_place", "huwowng", "hướng"),
        s("real_place", "tuowng", "tường"),
        s("real_place", "suwowng", "sường"),
        s("real_place", "quang", "quang"),
        s("real_place", "quangj", "quangj"),
        s("real_place", "giuwx", "giữ"),
        s("real_place", "giuwxa", "giữa"),
        s("real_place", "tuaan", "tuaan"),
        s("real_place", "dduwa", "đưa"),
        s("real_place", "dduwowng", "đường"),
    ]

    private static let trickyOWAndW: [RealUserTypingScenario] = [
        s("real_tricky", "hopw", "hơp"),
        s("real_tricky", "hopwj", "hợp"),
        s("real_tricky", "Hopwj", "Hợp"),
        s("real_word", "cow", "cơ"),
        s("real_word", "cowj", "cợ"),
        s("real_tricky", "how", "how"),
        s("real_tricky", "How", "How"),
        s("real_tricky", "show", "show"),
        s("real_tricky", "gowj", "gợ"),
        s("real_tricky", "guiwr", "gửi"),
        s("real_tricky", "guiw", "gưi"),
        s("real_tricky", "guwr", "gử"),
        s("real_tricky", "hoow", "hoow"),
        s("real_tricky", "hoowj", "hoowj"),
        s("real_tricky", "thow", "thơ"),
        s("real_tricky", "thoww", "thow"),
        s("real_tricky", "low", "lơ"),
        s("real_tricky", "loww", "low"),
        s("real_tricky", "hopf", "hòp"),
        s("real_tricky", "hopj", "họp"),
        s("real_tricky", "hopx", "hõp"),
        s("real_tricky", "hops", "hóp"),
        s("real_tricky", "hopr", "hỏp"),
    ]

    private static let mixedLanguage: [RealUserTypingScenario] = [
        s("real_mixed", "ToolVN", "ToolVN"),
        s("real_mixed", "how are you", "how are you"),
        s("real_mixed", "show me vieetj", "show me việt"),
        s("real_mixed", "email test@gmail.com", "email test@gmail.com"),
        s("real_mixed", "API chaof", "API chào"),
        s("real_mixed", "MacBook camr", "MacBook cảm"),
    ]

    private static let punctuationPhrases: [RealUserTypingScenario] = [
        s("real_punct", "vieetj,", "việt,"),
        s("real_punct", "vieetj.", "việt."),
        s("real_punct", "vieetj?", "việt?"),
        s("real_punct", "vieetj!", "việt!"),
        s("real_punct", "(mootj)", "(một)"),
        s("real_punct", "camr own.", "cảm ơn."),
        s("real_punct", "a,", "a,"),
        s("real_punct", "as,", "á,"),
        s("real_punct", "dduwowcj;", "được;"),
    ]

    private static let shortSentences: [RealUserTypingScenario] = [
        s("real_sentence", "xin chaof", "xin chào"),
        s("real_sentence", "camr on banj", "cảm ơn bạn"),
        s("real_sentence", "Tooi laf nguowif Vieetj Nam", "Tôi là người Việt Nam"),
        s("real_sentence", "Hoom nay trowif ddepj quas", "Hôm nay trời đẹp quá"),
        s("real_sentence", "Kieemr tra quas", "Kiểm tra quá"),
        s("real_sentence", "ToolVN hoox trowj gox tieesng Vieetj", "ToolVN hỗ trợ gõ tiếng Việt"),
        s("real_sentence", "dduwowngf ddepj quas", "đường đẹp quá"),
        s("real_sentence", "hopwj ddongf y kieens", "hợp đồng ý kiến"),
        s("real_sentence", "guiwr thu xin", "gửi thư xin"),
        s("real_sentence", "khoongf co gi", "không có gì"),
    ]
}

public enum RealUserContextRunner {
    public static func summary() -> String {
        let n = RealUserContextFixtures.scenarios.count
        let c = RealUserContextFixtures.controllerPhrases.count
        let j = RealUserJourneyFixtures.all.count
        let byCat = Dictionary(grouping: RealUserContextFixtures.scenarios, by: \.category)
        let lines = byCat.keys.sorted().map { "\($0): \(byCat[$0]?.count ?? 0)" }
        return "Ngữ cảnh người dùng: \(n) chuỗi gõ (\(lines.joined(separator: ", "))) + \(c) câu controller + \(j) hành trình Delete/sửa"
    }

    public static func run() -> [String] {
        var errors: [String] = []

        for scenario in RealUserContextFixtures.scenarios {
            let telex = scenario.telex
            let perKey = scenario.expectedPerKeystroke
            let batch = VietnameseConverter.convert(telex)

            if batch != perKey {
                errors.append(
                    "[real_consistency] `\(telex)`: engine batch=`\(batch)` ≠ gõ từng phím=`\(perKey)` — \(scenario.note)"
                )
            }

            if IMEDuplicatePatternDetector.hasGrowingPrefixGlitch(perKey) {
                errors.append("[real_glitch] `\(telex)` cuối glitch prefix — \(scenario.note)")
            }
        }

        errors.append(contentsOf: PerKeystrokeTypingRunner.run(RealUserContextFixtures.typingSequenceCases).map {
            "[real_typing] \($0.reason) `\( $0.testCase.keystrokes)` — \($0.testCase.note)"
        })

        let engineFailures = IMETestRunner.runTelex(RealUserContextFixtures.engineCases)
        for f in engineFailures {
            errors.append(
                "[real_engine] [\(f.testCase.category)] \(f.testCase.input) → «\(f.testCase.expected)» got «\(f.actual)»"
            )
        }

        errors.append(contentsOf: UserTypingJourneyRunner.run(RealUserContextFixtures.controllerPhrases))

        errors.append(contentsOf: RealUserJourneyRunner.run())

        let stepSamples = RealUserContextFixtures.scenarios.map(\.telex)
            + RealUserContextFixtures.controllerPhrases.map { keys in
                keys.keys.compactMap { if case .character(let c) = $0 { return c }; return nil }.map(String.init).joined()
            }
        errors.append(
            contentsOf: PerKeystrokeTypingRunner.runControllerConformance(samples: Array(Set(stepSamples)))
        )

        return errors
    }
}
