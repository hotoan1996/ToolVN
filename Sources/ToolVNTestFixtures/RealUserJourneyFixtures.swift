import Foundation
import ToolVNCore

/// Hành trình gõ có Delete / sửa dấu — mở rộng ngữ cảnh người dùng.
public enum RealUserJourneyFixtures {
    public static let all: [UserTypingJourneyCase] =
        hợpAndOW
        + gửiAndViệt
        + toneDoubleKey
        + spaceAndPunct

    private static func j(
        _ category: String,
        _ keys: [IMEUserKey],
        _ expected: String,
        _ note: String
    ) -> UserTypingJourneyCase {
        UserTypingJourneyCase(category: category, keys: keys, expectedFinal: expected, note: note)
    }

    private static func t(_ s: String) -> [IMEUserKey] { IMEUserKeyBuilders.telex(s) }

    private static let hợpAndOW: [UserTypingJourneyCase] = [
        j("real_journey", t("hopwj"), "hợp", "hợp một mạch"),
        j("real_journey", t("how"), "how", "how không thành hơ"),
        j(
            "real_journey",
            t("ho") + t("ww"),
            "how",
            "how qua ho+ww"
        ),
        j(
            "real_journey",
            t("hopw") + t("j"),
            "hợp",
            "hopw rồi j"
        ),
    ]

    private static let gửiAndViệt: [UserTypingJourneyCase] = [
        j("real_journey", t("guiwr"), "gửi", "gửi"),
        j(
            "real_journey",
            t("guiw") + t("r"),
            "gửi",
            "guiw + r"
        ),
        j(
            "real_journey",
            t("vieetj") + [.backspace] + t("j"),
            "việt",
            "việt sửa j"
        ),
        j(
            "real_journey",
            t("Kieemr") + [.backspace] + t("r"),
            "Kiểm",
            "Kiểm sửa r"
        ),
    ]

    private static let toneDoubleKey: [UserTypingJourneyCase] = [
        j("real_journey", t("hopwj") + t("s"), "hớp", "hợp + s → sắc trên ơ"),
        j("real_journey", t("quas") + t("s"), "quas", "quá + ss"),
        j("real_journey", t("camrs") + [.backspace], "cảm", "cảm xóa s thừa"),
    ]

    private static let spaceAndPunct: [UserTypingJourneyCase] = [
        j("real_journey", t("vieetj ") + t("xin "), "việt xin ", "hai từ space"),
        j("real_journey", t("vieetj,"), "việt,", "phẩy sau việt"),
        j(
            "real_journey",
            t("hopwj ") + t("laf "),
            "hợp là ",
            "hợp là space"
        ),
    ]
}

public enum RealUserJourneyRunner {
    public static func run() -> [String] {
        UserTypingJourneyRunner.run(RealUserJourneyFixtures.all)
    }
}
