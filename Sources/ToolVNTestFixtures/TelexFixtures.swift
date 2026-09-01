import Foundation

/// Case đã rà soát — `swift run toolvn-test --strict` phải pass 100%.
public enum TelexGoldenFixtures {
    public static let all: [IMETestCase] =
        marks
        + tonePlain
        + toneMarked
        + placement
        + words
        + punctuation
        + casing
        + regression
}

/// Case mở rộng (câu dài, biên, tương lai) — có thể fail cho đến khi engine hoàn thiện.
public enum TelexExtendedFixtures {
    public static let all: [IMETestCase] =
        sentences + edgeCases + aspirationalWords + TelexCorpus.telexCases + TelexTestMatrix.engineCases
        + TelexLongPassages.engineCases
}

public enum TelexFixtures {
    public static var all: [IMETestCase] { TelexGoldenFixtures.all + TelexExtendedFixtures.all }
}

// MARK: - Golden

private let marks: [IMETestCase] = [
    .init(category: "marks", input: "dd", expected: "đ"),
    .init(category: "marks", input: "DD", expected: "Đ"),
    .init(category: "marks", input: "aa", expected: "â"),
    .init(category: "marks", input: "aw", expected: "ă"),
    .init(category: "marks", input: "ee", expected: "ê"),
    .init(category: "marks", input: "oo", expected: "ô"),
    .init(category: "marks", input: "ow", expected: "ơ"),
    .init(category: "marks", input: "uw", expected: "ư"),
    .init(category: "marks", input: "uow", expected: "ươ"),
    .init(category: "marks", input: "uown", expected: "ươn"),
]

private let tonePlain: [IMETestCase] = [
    .init(category: "tone_plain", input: "as", expected: "á"),
    .init(category: "tone_plain", input: "af", expected: "à"),
    .init(category: "tone_plain", input: "ar", expected: "ả"),
    .init(category: "tone_plain", input: "ax", expected: "ã"),
    .init(category: "tone_plain", input: "aj", expected: "ạ"),
    .init(category: "tone_plain", input: "es", expected: "é"),
    .init(category: "tone_plain", input: "ef", expected: "è"),
    .init(category: "tone_plain", input: "is", expected: "í"),
    .init(category: "tone_plain", input: "of", expected: "ò"),
    .init(category: "tone_plain", input: "us", expected: "ú"),
    .init(category: "tone_plain", input: "yj", expected: "ỵ"),
    .init(category: "tone_plain", input: "asf", expected: "à", note: "đổi thanh s→f"),
    .init(category: "tone_plain", input: "asr", expected: "ả"),
    .init(category: "tone_plain", input: "asx", expected: "ã"),
    .init(category: "tone_plain", input: "asj", expected: "ạ"),
    .init(category: "tone_plain", input: "ass", expected: "as", note: "ss bỏ dấu sắc, giữ chữ s"),
    .init(category: "tone_plain", input: "aff", expected: "af", note: "ff bỏ dấu huyền"),
    .init(category: "tone_plain", input: "quass", expected: "quas", note: "quá + s → quas"),
]

private let toneMarked: [IMETestCase] = [
    .init(category: "tone_marked", input: "aas", expected: "ấ"),
    .init(category: "tone_marked", input: "aaf", expected: "ầ"),
    .init(category: "tone_marked", input: "aasf", expected: "ầ", note: "đổi thanh trên â"),
    .init(category: "tone_marked", input: "aws", expected: "ắ"),
    .init(category: "tone_marked", input: "ees", expected: "ế"),
    .init(category: "tone_marked", input: "oos", expected: "ố"),
    .init(category: "tone_marked", input: "ows", expected: "ớ"),
    .init(category: "tone_marked", input: "uws", expected: "ứ"),
    .init(category: "tone_marked", input: "uwsf", expected: "ừ"),
    .init(category: "tone_marked", input: "owf", expected: "ờ"),
    .init(category: "tone_marked", input: "eef", expected: "ề"),
]

private let placement: [IMETestCase] = [
    .init(category: "placement", input: "vieetj", expected: "việt"),
    .init(category: "placement", input: "tieens", expected: "tiến"),
    .init(category: "placement", input: "hoocj", expected: "h\u{1ED9}c"),
    .init(category: "placement", input: "tuwf", expected: "từ"),
    .init(category: "placement", input: "quys", expected: "quý"),
    .init(category: "placement", input: "lanhs", expected: "lánh"),
]

private let words: [IMETestCase] = [
    .init(category: "words", input: "khoongf", expected: "khồng", note: "cùng từ không; ô + huyền"),
    .init(category: "words", input: "mootj", expected: "một"),
    .init(category: "words", input: "nhieeuf", expected: "nhiều"),
    .init(category: "words", input: "camr", expected: "cảm"),
    .init(category: "words", input: "thoong", expected: "thông"),
]

private let punctuation: [IMETestCase] = [
    .init(category: "punctuation", input: "(vieetj)", expected: "(việt)"),
    .init(category: "punctuation", input: "vieetj,", expected: "việt,"),
    .init(category: "punctuation", input: "camr,", expected: "cảm,"),
    .init(category: "punctuation", input: "quas,", expected: "quá,"),
    .init(category: "punctuation", input: "xin chaf.", expected: "xin chà."),
    .init(category: "punctuation", input: "mootj hai", expected: "một hai"),
    .init(category: "punctuation", input: "co,", expected: "co,", note: "chưa đủ nguyên âm — giữ telex"),
]

private let casing: [IMETestCase] = [
    .init(category: "casing", input: "Vieetj", expected: "Việt"),
]

private let regression: [IMETestCase] = [
    .init(category: "regression", input: "vieetj", expected: "việt", note: "không thành vịêt"),
    .init(category: "regression", input: "hoocj", expected: "h\u{1ED9}c"),
    .init(category: "regression", input: "tuowng", expected: "tương"),
    .init(category: "regression", input: "cuw", expected: "cư"),
]

// MARK: - Extended

private let sentences: [IMETestCase] = [
    .init(
        category: "sentences",
        input: "Tooi laf nguowif Vieetj Nam",
        expected: "Tôi là người Việt Nam"
    ),
    .init(
        category: "sentences",
        input: "Hoom nay trowif ddepj quas",
        expected: "Hôm nay trời đẹp quá"
    ),
    .init(
        category: "sentences",
        input: "ToolVN hoox trowj gox tieesng Vieetj",
        expected: "ToolVN hỗ trợ gõ tiếng Việt"
    ),
]

private let edgeCases: [IMETestCase] = [
    .init(category: "edge", input: "a   b", expected: "a   b", note: "giữ khoảng trắng kép"),
    .init(category: "edge", input: "aasz", expected: "â", note: "z bỏ dấu thanh"),
    .init(category: "edge", input: "aass", expected: "âs", note: "ss bỏ dấu trên â"),
    .init(category: "edge", input: "vieetjz", expected: "viêt", note: "z bỏ dấu thanh"),
    .init(category: "edge", input: "camrr", expected: "camr", note: "rr bỏ hỏi trên cảm"),
    .init(category: "edge", input: "giuwx", expected: "giữ"),
    .init(category: "edge", input: "guwr", expected: "gử", note: "gư + r (không có i)"),
    .init(category: "edge", input: "guiwr", expected: "gửi", note: "gui + w → gưi + r"),
    .init(category: "edge", input: "guiw", expected: "gưi", note: "không guiư"),
    .init(category: "edge", input: "hopw", expected: "hơp", note: "w sau phụ âm → o thành ơ"),
    .init(category: "edge", input: "hopwj", expected: "hợp", note: "hợp — không hopự"),
    .init(category: "edge", input: "Hopwj", expected: "Hợp"),
    .init(category: "edge", input: "how", expected: "how", note: "tiếng Anh — không hơ / hơư"),
    .init(category: "edge", input: "How", expected: "How"),
    .init(category: "edge", input: "show", expected: "show"),
    .init(category: "edge", input: "gowj", expected: "gợ", note: "ow + dấu vẫn thành ơ"),
    .init(category: "edge", input: "thanhf phoos", expected: "thành phố"),
    .init(category: "placement", input: "dduwowngf", expected: "đường"),
    .init(category: "placement", input: "nguowif", expected: "người"),
    .init(category: "placement", input: "truowngf", expected: "trường"),
    .init(category: "casing", input: "DDUWOWNGF", expected: "ĐƯỜNG"),
    .init(category: "regression", input: "ddaasy", expected: "đấy"),
    .init(category: "words", input: "thoong tin", expected: "thông tin"),
    .init(category: "words", input: "dduwowcj", expected: "được"),
    .init(category: "words", input: "nuowcs", expected: "nước"),
]

private let aspirationalWords: [IMETestCase] = [
    .init(category: "aspirational", input: "ddieenr", expected: "điển"),
    .init(category: "aspirational", input: "hoocj", expected: "h\u{1ED9}c"),
]
