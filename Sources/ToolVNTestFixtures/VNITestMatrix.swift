import Foundation
import ToolVNCore

/// Ma trận VNI (1–5 thanh, 6/7 mũ, đ, câu) — song song `TelexTestMatrix`.
public enum VNITestMatrix {
    public static let plainVowels: [Character] = ["a", "e", "i", "o", "u", "y"]
    public static let toneDigits: [Character] = ["1", "2", "3", "4", "5"]

    private static let plainToneGolden: [String: String] = [
        "a1": "á", "a2": "à", "a3": "ả", "a4": "ã", "a5": "ạ",
        "e1": "é", "e2": "è", "e3": "ẻ", "e4": "ẽ", "e5": "ẹ",
        "i1": "í", "i2": "ì", "i3": "ỉ", "i4": "ĩ", "i5": "ị",
        "o1": "ó", "o2": "ò", "o3": "ỏ", "o4": "õ", "o5": "ọ",
        "u1": "ú", "u2": "ù", "u3": "ủ", "u4": "ũ", "u5": "ụ",
        "y1": "ý", "y2": "ỳ", "y3": "ỷ", "y4": "ỹ", "y5": "ỵ",
    ]

    private static let markedToneGolden: [String: String] = [
        "a61": "ấ", "a62": "ầ", "a63": "ẩ", "a64": "ẫ", "a65": "ậ",
        "a71": "ắ", "a72": "ằ", "a73": "ẳ", "a74": "ẵ", "a75": "ặ",
        "e61": "ế", "e62": "ề", "e63": "ể", "e64": "ễ", "e65": "ệ",
        "o61": "ố", "o62": "ồ", "o63": "ổ", "o64": "ỗ", "o65": "ộ",
        "o71": "ớ", "o72": "ờ", "o73": "ở", "o74": "ỡ", "o75": "ợ",
        "u71": "ứ", "u72": "ừ", "u73": "ử", "u74": "ữ", "u75": "ự",
    ]

    private static let markOnlyGolden: [String: String] = [
        "d9": "đ", "dd": "đ",
        "a6": "â", "a7": "ă", "e6": "ê", "o6": "ô", "o7": "ơ", "u7": "ư",
    ]

    private static let consonantStarts: [String] = [
        "b", "c", "d", "g", "h", "k", "l", "m", "n", "p", "q", "r", "s", "t", "v", "x",
    ]

    private static let sampleSyllableVNI = "a1"

    public static var plainToneMatrix: [IMETestCase] {
        orderedPlainInputs.map { key in
            IMETestCase(
                category: "vni_matrix_plain",
                input: key,
                expected: plainToneGolden[key] ?? VNIEngine.transform(key),
                note: "vowel×tone VNI"
            )
        }
    }

    public static var markedToneMatrix: [IMETestCase] {
        orderedMarkedInputs.map { key in
            IMETestCase(
                category: "vni_matrix_marked",
                input: key,
                expected: markedToneGolden[key] ?? VNIEngine.transform(key),
                note: "mark×tone VNI"
            )
        }
    }

    public static var markOnlyMatrix: [IMETestCase] {
        markOnlyGolden.keys.sorted().map { key in
            IMETestCase(
                category: "vni_matrix_mark",
                input: key,
                expected: markOnlyGolden[key] ?? VNIEngine.transform(key),
                note: "mũ/đ VNI"
            )
        }
    }

    public static var consonantMatrix: [IMETestCase] {
        consonantStarts.enumerated().map { index, start in
            let input = start + sampleSyllableVNI
            return IMETestCase(
                category: "vni_matrix_consonant",
                input: input,
                expected: VNIEngine.transform(input),
                note: "C#\(index + 1) \(start)+a1"
            )
        }
    }

    public static var passageMatrix: [IMETestCase] {
        orderedPassages.enumerated().map { index, row in
            IMETestCase(
                category: "vni_matrix_passage",
                input: row.vni,
                expected: row.vietnamese,
                note: "đoạn #\(index + 1)"
            )
        }
    }

    public static var engineCases: [IMETestCase] {
        plainToneMatrix + markedToneMatrix + markOnlyMatrix + consonantMatrix + passageMatrix
    }

    public static var wordTypingCases: [TypingSequenceCase] {
        vniWordKeystrokes.map { row in
            PerKeystrokeTypingEngine.makeCase(
                category: "vni_perkeystroke_word",
                keystrokes: row.vni,
                note: row.note,
                method: .vni
            )
        }
    }

    public static var plainToneTyping: [TypingSequenceCase] {
        orderedPlainInputs.map { key in
            PerKeystrokeTypingEngine.makeCase(
                category: "vni_perkeystroke_plain",
                keystrokes: key,
                note: plainToneGolden[key] ?? "",
                method: .vni
            )
        }
    }

    public static var markedToneTyping: [TypingSequenceCase] {
        orderedMarkedInputs.map { key in
            PerKeystrokeTypingEngine.makeCase(
                category: "vni_perkeystroke_marked",
                keystrokes: key,
                method: .vni
            )
        }
    }

    public static var passageTyping: [TypingSequenceCase] {
        orderedPassages.map { row in
            TypingSequenceCase(
                category: "vni_perkeystroke_passage",
                keystrokes: row.vni,
                expectedFinal: row.vietnamese,
                note: "full passage",
                method: .vni
            )
        }
    }

    public static var fullTypingCases: [TypingSequenceCase] {
        plainToneTyping + markedToneTyping + wordTypingCases + passageTyping
    }

    public static func validateGoldenMatrixAgainstEngine() -> [String] {
        var errors: [String] = []
        let golden = plainToneGolden
            .merging(markedToneGolden) { _, n in n }
            .merging(markOnlyGolden) { _, n in n }
        for (input, expected) in golden.sorted(by: { $0.key < $1.key }) {
            let got = VNIEngine.transform(input)
            if got != expected {
                errors.append("VNI matrix golden: `\(input)` engine=`\(got)` golden=`\(expected)`")
            }
        }
        for row in orderedPassages {
            let got = VNIEngine.transform(row.vni)
            if got != row.vietnamese {
                errors.append("VNI passage: `\(row.vni)` engine=`\(got)` snapshot=`\(row.vietnamese)`")
            }
        }
        return errors
    }

    public static func summary() -> String {
        """
        Ma trận VNI:
          vni_matrix_plain     \(plainToneMatrix.count) (6 nguyên âm × 5 thanh)
          vni_matrix_marked    \(markedToneMatrix.count) (6 mũ × 5 thanh)
          vni_matrix_mark       \(markOnlyMatrix.count) (đ + mũ đơn)
          vni_matrix_consonant \(consonantMatrix.count) phụ âm × mẫu á
          vni_matrix_passage   \(passageMatrix.count) đoạn
          vni_perkeystroke     \(fullTypingCases.count) chuỗi gõ từng phím
        """
    }

    private static var orderedPlainInputs: [String] {
        plainVowels.flatMap { v in toneDigits.map { d in "\(v)\(d)" } }
    }

    private static var orderedMarkedInputs: [String] {
        ["a6", "a7", "e6", "o6", "o7", "u7"].flatMap { base in
            toneDigits.map { d in base + String(d) }
        }
    }

    private struct PassageRow: Sendable {
        let vni: String
        let vietnamese: String
    }

    private struct WordRow: Sendable {
        let vni: String
        let note: String
    }

    /// Cùng nội dung tiếng Việt với ma trận Telex (keystroke VNI).
    private static let orderedPassages: [PassageRow] = [
        PassageRow(vni: "To6i la2 ngu7o7i2 Vie6t5 Nam.", vietnamese: VNIEngine.transform("To6i la2 ngu7o7i2 Vie6t5 Nam.")),
        PassageRow(vni: "Ho6m nay tro72i ddep5 qua2.", vietnamese: VNIEngine.transform("Ho6m nay tro72i ddep5 qua2.")),
        PassageRow(vni: "ToolVN ho7 tro7 go5 tie61 Vie6t5.", vietnamese: VNIEngine.transform("ToolVN ho7 tro7 go5 tie61 Vie6t5.")),
        PassageRow(vni: "Kie63m tra qua2 tru7o7ng ho7p tie61 bie63u.", vietnamese: VNIEngine.transform("Kie63m tra qua2 tru7o7ng ho7p tie61 bie63u.")),
        PassageRow(vni: "Ban2 co2 the63 du2ng5 Telex hoa7c5 VNI de5 go5.", vietnamese: VNIEngine.transform("Ban2 co2 the63 du2ng5 Telex hoa7c5 VNI de5 go5.")),
        PassageRow(vni: "Ho9c ta61p la2 qua2 tri2nh tie61n tri2 lau2 da2i.", vietnamese: VNIEngine.transform("Ho9c ta61p la2 qua2 tri2nh tie61n tri2 lau2 da2i.")),
        PassageRow(vni: "Cam2 on ban2 dda9 su5 du2ng5 ToolVN.", vietnamese: VNIEngine.transform("Cam2 on ban2 dda9 su5 du2ng5 ToolVN.")),
        PassageRow(vni: "Chu1c ban2 mo6t5 nga2y la2m vie6c5 hie6u qua3.", vietnamese: VNIEngine.transform("Chu1c ban2 mo6t5 nga2y la2m vie6c5 hie6u qua3.")),
    ]

    private static let vniWordKeystrokes: [WordRow] = [
        WordRow(vni: "vie6t5", note: "việt"),
        WordRow(vni: "Vie6t5", note: "Việt"),
        WordRow(vni: "ho6c5", note: "học"),
        WordRow(vni: "ngu7o7i2", note: "người"),
        WordRow(vni: "ddu7o7c5", note: "được"),
        WordRow(vni: "kho6ng2", note: "không"),
        WordRow(vni: "tie6n1", note: "tiến"),
        WordRow(vni: "mo6t5", note: "một"),
        WordRow(vni: "tro72i", note: "trời"),
        WordRow(vni: "Kie63m", note: "Kiểm"),
        WordRow(vni: "Kie63m tra qua2", note: "Kiểm tra quá"),
        WordRow(vni: "To6i la2 ngu7o7i2 Vie6t5 Nam", note: "câu danh từ"),
    ]
}
