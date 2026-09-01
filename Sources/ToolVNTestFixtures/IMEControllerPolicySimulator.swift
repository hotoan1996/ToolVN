import Foundation
import ToolVNCore

/// Mô phỏng chính sách controller: preedit một vùng (IMEComposeSession), so với các lỗi IME thực tế.
public enum IMEControllerPolicySimulator {
    /// Đúng: setMarkedText / preedit — không insertText từng phím.
    public static func correctVisible(keystrokes: String, method: VietnameseInputMethod = .telex) -> String {
        var session = IMEComposeSession(method: method)
        for ch in keystrokes {
            session.typeCharacter(ch)
        }
        return session.visibleText
    }

    /// Sai: mỗi phím insertText full buffer (Safari/Docs).
    public static func brokenInsertEachKeyVisible(keystrokes: String, method: VietnameseInputMethod = .telex) -> String {
        SafariInsertBugSimulator.brokenVisibleText(keystrokes: keystrokes, method: method)
    }

    /// Sai: commit không thay marked → từ lặp hai lần trước space/dấu câu.
    public static func brokenCommitVisible(keystrokes: String, method: VietnameseInputMethod = .telex) -> String {
        var committed = ""
        var raw = ""
        for ch in keystrokes {
            if ch == " " {
                let word = VietnameseConverter.convert(raw, method: method)
                committed += word + word + " "
                raw = ""
            } else if ",.;:!?".contains(ch) {
                let word = VietnameseConverter.convert(raw, method: method)
                committed += word + word + String(ch)
                raw = ""
            } else if ch.isLetter || "sfrxjzw".contains(ch.lowercased()) {
                raw.append(ch)
            }
        }
        let tail = raw.isEmpty ? "" : VietnameseConverter.convert(raw, method: method)
        return committed + tail
    }

    /// Sai: mỗi lần bấm space, app chèn thêm một space (IME đã insert).
    public static func brokenSpaceVisible(keystrokes: String, method: VietnameseInputMethod = .telex) -> String {
        let correct = correctVisible(keystrokes: keystrokes, method: method)
        let spaceKeys = keystrokes.filter { $0 == " " }.count
        return correct + String(repeating: " ", count: spaceKeys)
    }
}

public enum IMEControllerPolicyRegression {
    public static func run() -> [String] {
        var errors: [String] = []

        let phrases = [
            ("Kieemr", "Kiểm"),
            ("Kieemr tra", "Kiểm tra"),
            ("vieetj ", "việt "),
            ("vieetj xin", "việt xin"),
            ("vieetj,", "việt,"),
            ("trowif", "trời"),
            ("gox tieesng", "gõ tiếng"),
        ]

        for (keys, expected) in phrases {
            let got = IMEControllerPolicySimulator.correctVisible(keystrokes: keys)
            if got != expected {
                errors.append("Policy đúng [\(keys)] → «\(expected)», got «\(got)»")
            }
            if IMEDuplicatePatternDetector.hasGrowingPrefixGlitch(got) {
                errors.append("Policy đúng không được glitch prefix: \(keys)")
            }
            if IMEDuplicatePatternDetector.hasAdjacentDuplicateChunk(got) {
                errors.append("Policy đúng không được chunk lặp: \(keys)")
            }
        }

        if !SafariInsertBugSimulator.producesKnownGlitch(keystrokes: "Kieemr") {
            errors.append("Mô hình insert từng phím phải glitch Kieemr")
        }

        let badCommit = IMEControllerPolicySimulator.brokenCommitVisible(keystrokes: "vieetj ")
        if !IMEDuplicatePatternDetector.hasAdjacentDuplicateChunk(badCommit) {
            errors.append("Mô hình commit sai phải lặp việt")
        }

        if IMEControllerPolicySimulator.brokenSpaceVisible(keystrokes: "vieetj ") != "việt  " {
            errors.append("Mô hình space đôi: vieetj → việt  ")
        }

        if IMEControllerPolicySimulator.correctVisible(keystrokes: "vieetj ")
            == IMEControllerPolicySimulator.brokenSpaceVisible(keystrokes: "vieetj ") {
            errors.append("Session đúng phải khác mô hình space đôi")
        }

        return errors
    }
}
