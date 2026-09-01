import Foundation
import ToolVNCore

/// Từ điển Telex đã đối chiếu với `TelexEngine` (mỗi cặp pass `convert(telex) == vietnamese`).
public enum TelexCorpus {
    public static let pairs: [(telex: String, vietnamese: String)] = [
        ("vieetj", "việt"),
        ("Vieetj", "Việt"),
        ("Vieejt Nam", "Việt Nam"),
        ("chaof", "chào"),
        ("xin", "xin"),
        ("Kieemr", "Kiểm"),
        ("Kieemr tra", "Kiểm tra"),
        ("tra", "tra"),
        ("quas", "quá"),
        ("hoocj", "h\u{1ED9}c"),
        ("dduwowcj", "được"),
        ("nguowif", "người"),
        ("khoongf", "khồng"),
        ("tieens", "tiến"),
        ("dduwowngf", "đường"),
        ("truowngf", "trường"),
        ("nhieeuf", "nhiều"),
        ("mootj", "một"),
        ("camr", "cảm"),
        ("quys", "quý"),
        ("tuwf", "từ"),
        ("Tooi", "Tôi"),
        ("laf", "là"),
        ("dd", "đ"),
        ("ddaasy", "đấy"),
        ("tuowng", "tương"),
        ("cuw", "cư"),
        ("lanhs", "lánh"),
        ("thoong", "thông"),
        ("tin", "tin"),
        ("giuwx", "giữ"),
        ("nuowcs", "nước"),
        ("thanhf", "thành"),
        ("phoos", "phố"),
        ("Hoom nay", "Hôm nay"),
        ("trowif", "trời"),
        ("ddepj", "đẹp"),
        ("hoox", "hỗ"),
        ("trowj", "trợ"),
        ("gox", "gõ"),
        ("tieesng", "tiếng"),
        ("lamf", "làm"),
        ("vieecj", "việc"),
        ("phuwowng", "phương"),
        ("ngayf", "ngày"),
        ("banj", "bạn"),
        ("coos", "cố"),
        ("cos", "có"),
        ("nghieepj", "nghiệp"),
        ("phas", "phá"),
        ("trieenr", "triển"),
        ("quoocsj", "quộc"),
        ("taapj", "tập"),
        ("ddifnh", "đình"),
        ("Haf", "Hà"),
        ("Nooij", "Nội"),
        ("Saans", "Sấn"),
        ("ddeem", "đêm"),
        ("maays", "mấy"),
        ("ddang", "đang"),
        ("chuw", "chư"),
        ("thuowng", "thương"),
        ("mucj", "mục"),
        ("tieesp", "tiếp"),
        ("theo", "theo"),
        ("danh", "danh"),
        ("tapj", "tạp"),
        ("hoocj taapj", "hộc tập"),
        ("Tooi laf nguowif Vieetj Nam", "Tôi là người Việt Nam"),
        ("Hoom nay trowif ddepj quas", "Hôm nay trời đẹp quá"),
    ]

    public static var telexCases: [IMETestCase] {
        pairs.map { IMETestCase(category: "corpus", input: $0.telex, expected: $0.vietnamese) }
    }

    public static var typingCases: [TypingSequenceCase] {
        pairs.map { pair in
            PerKeystrokeTypingEngine.makeCase(
                category: "perkeystroke_corpus",
                keystrokes: pair.telex,
                note: pair.vietnamese
            )
        }
    }

    /// Kiểm tra corpus khớp engine (gọi trong test).
    public static func validateAgainstEngine() -> [String] {
        pairs.compactMap { pair in
            if let mismatch = PerKeystrokeTypingEngine.engineMismatchErrors(
                telex: pair.telex,
                label: "corpus `\(pair.telex)`"
            ) {
                return mismatch
            }
            let perKey = PerKeystrokeTypingEngine.finalVisible(pair.telex)
            if perKey != pair.vietnamese {
                return "corpus gõ từng phím: `\(pair.telex)` → `\(perKey)`, mong `\(pair.vietnamese)`"
            }
            return nil
        }
    }
}
