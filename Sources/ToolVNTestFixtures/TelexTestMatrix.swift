import Foundation
import ToolVNCore

/// Ma trận test Telex có thứ tự: nguyên âm × thanh, mũ × thanh, câu dài, chuỗi gõ tích lũy.
public enum TelexTestMatrix {
    public static let plainVowels: [Character] = ["a", "e", "i", "o", "u", "y"]
    public static let toneKeys: [Character] = ["s", "f", "r", "x", "j"]

    /// Kỳ vọng cố định (không phụ thuộc engine) — 6×5 thanh trên nguyên âm trơn.
    private static let plainToneGolden: [String: String] = [
        "as": "á", "af": "à", "ar": "ả", "ax": "ã", "aj": "ạ",
        "es": "é", "ef": "è", "er": "ẻ", "ex": "ẽ", "ej": "ẹ",
        "is": "í", "if": "ì", "ir": "ỉ", "ix": "ĩ", "ij": "ị",
        "os": "ó", "of": "ò", "or": "ỏ", "ox": "õ", "oj": "ọ",
        "us": "ú", "uf": "ù", "ur": "ủ", "ux": "ũ", "uj": "ụ",
        "ys": "ý", "yf": "ỳ", "yr": "ỷ", "yx": "ỹ", "yj": "ỵ",
    ]

    /// Mũ + thanh (thứ tự: â → ă → ê → ô → ơ → ư, mỗi nhóm s f r x j).
    private static let markedToneGolden: [String: String] = [
        "aas": "ấ", "aaf": "ầ", "aar": "ẩ", "aax": "ẫ", "aaj": "ậ",
        "aws": "ắ", "awf": "ằ", "awr": "ẳ", "awx": "ẵ", "awj": "ặ",
        "ees": "ế", "eef": "ề", "eer": "ể", "eex": "ễ", "eej": "ệ",
        "oos": "ố", "oof": "ồ", "oor": "ổ", "oox": "ỗ", "ooj": "ộ",
        "ows": "ớ", "owf": "ờ", "owr": "ở", "owx": "ỡ", "owj": "ợ",
        "uws": "ứ", "uwf": "ừ", "uwr": "ử", "uwx": "ữ", "uwj": "ự",
    ]

    /// Phụ âm đầu × một âm tiết mẫu (ba, be, bi, …) — kiểm tra vị trí thanh.
    private static let consonantStarts: [String] = [
        "b", "c", "d", "đ", "g", "h", "k", "l", "m", "n", "p", "q", "r", "s", "t", "v", "x",
    ]

    private static let sampleSyllableTelex = "as" // → á

    // MARK: - Engine cases

    public static var plainToneMatrix: [IMETestCase] {
        orderedPlainInputs.map { key in
            IMETestCase(
                category: "matrix_plain",
                input: key,
                expected: plainToneGolden[key] ?? TelexEngine.transform(key),
                note: "vowel×tone"
            )
        }
    }

    public static var markedToneMatrix: [IMETestCase] {
        orderedMarkedInputs.map { key in
            IMETestCase(
                category: "matrix_marked",
                input: key,
                expected: markedToneGolden[key] ?? TelexEngine.transform(key),
                note: "mark×tone"
            )
        }
    }

    public static var consonantMatrix: [IMETestCase] {
        consonantStarts.enumerated().map { index, start in
            let input = start + sampleSyllableTelex
            let expected = TelexEngine.transform(input)
            return IMETestCase(
                category: "matrix_consonant",
                input: input,
                expected: expected,
                note: "C#\(index + 1) \(start)+as"
            )
        }
    }

    public static var passageMatrix: [IMETestCase] {
        orderedPassages.enumerated().map { index, row in
            IMETestCase(
                category: "matrix_passage",
                input: row.telex,
                expected: row.vietnamese,
                note: "đoạn #\(index + 1)"
            )
        }
    }

    public static var engineCases: [IMETestCase] {
        plainToneMatrix + markedToneMatrix + consonantMatrix + passageMatrix
    }

    // MARK: - Typing (IME session)

    /// Gõ tích lũy từng từ trong chuỗi hội thoại (thứ tự cố định).
    public static var cumulativeChainTyping: [TypingSequenceCase] {
        dialogChains.flatMap { chain in
            chainCumulativeCases(chainID: chain.id, words: chain.words)
        }
    }

    /// Cả câu + từng đoạn văn (một lần gõ hết).
    public static var passageTyping: [TypingSequenceCase] {
        orderedPassages.enumerated().map { index, row in
            PerKeystrokeTypingEngine.makeCase(
                category: "perkeystroke_matrix_passage",
                keystrokes: row.telex,
                note: "đoạn #\(index + 1)"
            )
        }
    }

    /// Ma trận ngắn: mỗi ô plain tone gõ từng phím (đã có expected cuối).
    public static var plainToneTyping: [TypingSequenceCase] {
        orderedPlainInputs.map { key in
            PerKeystrokeTypingEngine.makeCase(
                category: "perkeystroke_matrix_plain",
                keystrokes: key,
                note: "vowel×tone"
            )
        }
    }

    public static var markedToneTyping: [TypingSequenceCase] {
        orderedMarkedInputs.map { key in
            PerKeystrokeTypingEngine.makeCase(
                category: "perkeystroke_matrix_marked",
                keystrokes: key,
                note: "mark×tone"
            )
        }
    }

    public static var typingCases: [TypingSequenceCase] {
        plainToneTyping + markedToneTyping + cumulativeChainTyping + passageTyping
    }

    /// Toàn bộ ma trận gõ từng phím (plain + marked + chuỗi + đoạn).
    public static var fullTypingCases: [TypingSequenceCase] {
        typingCases
    }

    // MARK: - Validation

    /// So khớp golden matrix với engine (bắt lệch logic Telex).
    public static func validateGoldenMatrixAgainstEngine() -> [String] {
        var errors: [String] = []
        let golden = plainToneGolden.merging(markedToneGolden) { _, new in new }
        for (input, expected) in golden.sorted(by: { $0.key < $1.key }) {
            let got = TelexEngine.transform(input)
            if got != expected {
                errors.append("matrix golden: `\(input)` engine=`\(got)` golden=`\(expected)`")
            }
        }
        for row in orderedPassages {
            let got = TelexEngine.transform(row.telex)
            if got != row.vietnamese {
                errors.append("matrix passage: `\(row.telex)` engine=`\(got)` snapshot=`\(row.vietnamese)`")
            }
        }
        return errors
    }

    public static func summary() -> String {
        """
        Ma trận Telex:
          matrix_plain     \(plainToneMatrix.count) (6 nguyên âm × 5 thanh)
          matrix_marked    \(markedToneMatrix.count) (6 mũ × 5 thanh)
          matrix_consonant \(consonantMatrix.count) phụ âm × mẫu á
          matrix_passage   \(passageMatrix.count) đoạn văn
          typing cumulative \(cumulativeChainTyping.count) bước chuỗi
          typing passages   \(passageTyping.count)
        """
    }

    // MARK: - Private data

    private static var orderedPlainInputs: [String] {
        plainVowels.flatMap { v in toneKeys.map { t in "\(v)\(t)" } }
    }

    private static var orderedMarkedInputs: [String] {
        ["aa", "aw", "ee", "oo", "ow", "uw"].flatMap { base in
            toneKeys.map { t in base + String(t) }
        }
    }

    private static func passage(_ telex: String) -> PassageRow {
        PassageRow(telex: telex, vietnamese: TelexEngine.transform(telex))
    }

    /// Đoạn văn dài — `vietnamese` là snapshot engine (đồng bộ qua `validateGoldenMatrixAgainstEngine`).
    private static let orderedPassages: [PassageRow] = [
        passage("Tooi laf nguowif Vieetj Nam."),
        passage("Hoom nay trowif ddepj quas."),
        passage("ToolVN hoox trowj gox tieesng Vieetj."),
        passage("Kieemr tra quas truwowng hopf tieeu bieeur."),
        passage("Banj co the dungf Telex hoac VNI de gox."),
        passage("Hoocj taapj la qua trinh tieens trif lau dai."),
        passage("Thanhf phoos Haf Nooij la thu do nuoc ta."),
        passage("Camr on banj dda su dungf ToolVN."),
        passage("Chuc banj mot ngay lamf vieecj hieu qua."),
    ]

    private struct PassageRow: Sendable {
        let telex: String
        let vietnamese: String
    }

    private struct DialogChain: Sendable {
        let id: String
        let words: [String]
    }

    private static let dialogChains: [DialogChain] = [
        DialogChain(id: "chain_greeting", words: ["Xin", "chaof", "banj"]),
        DialogChain(id: "chain_identity", words: ["Tooi", "laf", "nguowif", "Vieetj", "Nam"]),
        DialogChain(id: "chain_weather", words: ["Hoom", "nay", "trowif", "ddepj", "quas"]),
        DialogChain(id: "chain_toolvn", words: ["ToolVN", "hoox", "trowj", "gox", "tieesng", "Vieetj"]),
    ]

    private static func chainCumulativeCases(chainID: String, words: [String]) -> [TypingSequenceCase] {
        var keystrokes = ""
        var cases: [TypingSequenceCase] = []
        for (index, word) in words.enumerated() {
            if index > 0 { keystrokes += " " }
            keystrokes += word
            let expected = PerKeystrokeTypingEngine.finalVisible(keystrokes)
            cases.append(
                TypingSequenceCase(
                    category: "perkeystroke_chain",
                    keystrokes: keystrokes,
                    expectedFinal: expected,
                    note: "\(chainID) bước \(index + 1)/\(words.count)"
                )
            )
        }
        return cases
    }
}
