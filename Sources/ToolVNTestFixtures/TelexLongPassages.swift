import Foundation
import ToolVNCore

/// Đoạn văn Telex dài — kỳ vọng = `TelexEngine.transform` (chỉ dùng từ/cụm đã ổn trong corpus).
public enum TelexLongPassages {
    public struct Row: Sendable {
        public let id: String
        public let telex: String
        public let vietnamese: String
        public let note: String
    }

    /// Thứ tự cố định #01 … #n (đọc từ trên xuống).
    public static let ordered: [Row] = telexBodies.enumerated().map { index, telex in
        let id = String(format: "long_%02d", index + 1)
        return Row(
            id: id,
            telex: telex,
            vietnamese: TelexEngine.transform(telex),
            note: "đoạn dài Telex #\(index + 1)"
        )
    }

    public static var engineCases: [IMETestCase] {
        ordered.map {
            IMETestCase(category: "telex_long", input: $0.telex, expected: $0.vietnamese, note: $0.id)
        }
    }

    public static var typingFullCases: [TypingSequenceCase] {
        ordered.map {
            PerKeystrokeTypingEngine.makeCase(
                category: "perkeystroke_long",
                keystrokes: $0.telex,
                note: $0.id
            )
        }
    }

    /// Gõ tích lũy từng câu trong đoạn (dấu chấm + space).
    public static var typingBySentenceCases: [TypingSequenceCase] {
        ordered.flatMap { row in
            sentenceCumulativeCases(parentID: row.id, telex: row.telex)
        }
    }

    public static var allTypingCases: [TypingSequenceCase] {
        typingFullCases + typingBySentenceCases
    }

    public static func validateAgainstEngine() -> [String] {
        ordered.compactMap { row in
            PerKeystrokeTypingEngine.engineMismatchErrors(telex: row.telex, label: row.id)
        }
    }

    public static func summary() -> String {
        let chars = ordered.reduce(0) { $0 + $1.telex.count }
        let words = ordered.reduce(0) { $0 + $1.telex.split(separator: " ").count }
        return "TelexLongPassages: \(ordered.count) đoạn, ~\(words) từ Telex, ~\(chars) ký tự gõ"
    }

    // MARK: - Nội dung (ASCII Telex)

    private static let telexBodies: [String] = [
        // #01 — giới thiệu
        """
        Tooi laf nguowif Vieetj Nam. Hoom nay trowif ddepj quas. \
        ToolVN hoox trowj gox tieesng Vieetj.
        """.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces),

        // #02 — kiểm tra
        """
        Kieemr tra quas truwowng hopf tieeu bieeur. Camr on banj dda doc. \
        Xin chaof banj.
        """.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces),

        // #03 — học tập
        """
        Hoocj taapj la qua trinh tieens trif lau dai. Vieecj hoc tap lien tuc \
        giup nguowif tieen bo moi ngayf.
        """.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces),

        // #04 — địa danh
        """
        Thanhf phoos Haf Nooij la thu do nuoc ta. Dduwowngf phoos Saans \
        thoong tin va nhieeuf danh lamf depj.
        """.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces),

        // #05 — công việc
        """
        Banj co the dungf Telex hoac VNI de gox. Lamf vieecj hieu qua \
        can coos gang va tapj trung.
        """.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces),

        // #06 — thiên nhiên
        """
        Nuowcs Vietj Nam co bieenr dai va nhieeuf song. Mua he nong, \
        mua ddoong mat me.
        """.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces),

        // #07 — giao thông
        """
        Dduwowngf truowngf dda duowcj mo rong. Nguowif dan di lai \
        thuawn tien hon truowc day.
        """.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces),

        // #08 — văn hóa
        """
        Am nhac va tieesng Vieetj la tai san van hoa. Giuwx gin tieesng me \
        de cho the he sau.
        """.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces),

        // #09 — công nghệ
        """
        ToolVN la bo gox tieesng Vietj tren macOS. Banj gox Telex: \
        vieetj, Kieemr tra, dduwowcj, nguowif.
        """.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces),

        // #10 — chuỗi từ corpus (một dòng dài)
        """
        mootj hai ba bon nam sau bay tam chin muowif. camr on quys \
        tuwf lanhs giuwx thoong tin tieesp theo danh tapj.
        """.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces),

        // #11 — hỗ trợ IME
        """
        Gox Telex: dd la ddawt, aa la aa, ow la ow, uws la uws. \
        Ddaay la ma tran thanh de kiem tra.
        """.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces),

        // #12 — đoạn trộn hoa/thường
        """
        Tooi laf nguowif Vieetj Nam. Vieetj Nam ddat nuowcs chuw S \
        va hinh chuwx Z tren ban do.
        """.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces),

        // #13 — nhiều dấu thanh
        """
        quas camr on tuwf tieens len phas trieenr quoocsj gia. \
        nghieepj phat trieenr ben vung.
        """.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces),

        // #14 — câu hỏi/ghi chú (ký tự ASCII)
        """
        Banj dda gox dduwngf Telex chua? Hay thu: Kieemr tra, hoocj taapj, \
        dduwowngf truowngf.
        """.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces),

        // #15 — đoạn dài lặp mẫu (stress test)
        """
        Hoom nay trowif ddepj quas. Hoom nay trowif ddepj quas. \
        Tooi thich di dao quanh ho nuowcs va nghe nhac.
        """.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces),

        // #16 — liên kết câu
        """
        Chuc banj mot ngay lamf vieecj hieu qua. Toi laf nguowif yeu \
        tieesng Vietj va muoon gox chuan xac.
        """.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces),

        // #17 — từ điển ngắn trong câu
        """
        vieetj Vieetj vieetj nam, tuwf tuwf tieens tieens, \
        phuwowng thuowng mucj tieesp.
        """.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces),

        // #18 — paragraph essay style
        """
        Giao duc mo ra tuong lai. Hoocj taapj giup ta hieu biet va \
        song tot hon. Camr on thay co da day chung toi.
        """.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces),

        // #19 — mixed marks
        """
        dduwowcj lamf viec voi ToolVN thuat tien hon. Gox tieesng Vietj \
        khong con lo dup chu hay dup space.
        """.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces),

        // #20 — kết
        """
        Day la doan van dai so 20 trong bo test Telex. \
        Neu ban doc den day, camr on va chuc banj thanh cong.
        """.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces),
    ]

    private static func sentenceCumulativeCases(parentID: String, telex: String) -> [TypingSequenceCase] {
        let parts = telex.split(separator: ".", omittingEmptySubsequences: true)
        guard parts.count > 1 else { return [] }

        var cumulative = ""
        var cases: [TypingSequenceCase] = []
        for (index, part) in parts.enumerated() {
            let segment = part.trimmingCharacters(in: .whitespaces)
            guard !segment.isEmpty else { continue }
            if cumulative.isEmpty {
                cumulative = segment + "."
            } else {
                cumulative += " " + segment + "."
            }
            let expected = PerKeystrokeTypingEngine.finalVisible(cumulative)
            cases.append(
                TypingSequenceCase(
                    category: "perkeystroke_long_sentence",
                    keystrokes: cumulative,
                    expectedFinal: expected,
                    note: "\(parentID) câu \(index + 1)/\(parts.count)"
                )
            )
        }
        return cases
    }
}
