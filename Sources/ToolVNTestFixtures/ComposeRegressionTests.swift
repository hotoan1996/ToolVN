import Foundation
import ToolVNCore

/// Phím người dùng (gồm Delete/Backspace) — dùng test mô phỏng controller.
public enum IMEUserKey: Sendable, Equatable {
    case character(Character)
    case backspace
    /// Click chuột / đặt con trỏ (UTF-16 offset trong document).
    case caretAtUTF16(Int)
}

public enum IMEInteractionReplay {
    public static func sessionVisibleSteps(keys: [IMEUserKey], method: VietnameseInputMethod = .telex) -> [String] {
        var session = IMEComposeSession(method: method)
        var steps: [String] = []
        for key in keys {
            switch key {
            case .character(let ch):
                session.typeCharacter(ch)
            case .backspace:
                session.backspace()
            case .caretAtUTF16:
                session.commitCurrentWord()
            }
            steps.append(session.visibleText)
        }
        return steps
    }

    public static func sessionFinal(_ keys: [IMEUserKey], method: VietnameseInputMethod = .telex) -> String {
        sessionVisibleSteps(keys: keys, method: method).last ?? ""
    }
}

public enum SafariInsertBugSimulator {
    /// Mô phỏng lỗi Safari/Docs: mỗi phím `insertText` full chuỗi đã gõ mà không xóa bản trước → KKiKiKiê…
    public static func brokenVisibleText(keystrokes: String, method: VietnameseInputMethod = .telex) -> String {
        var buffer = ""
        var document = ""
        for ch in keystrokes where ch != " " {
            buffer.append(ch)
            document += VietnameseConverter.convert(buffer, method: method)
        }
        return document
    }

    public static func producesKnownGlitch(keystrokes: String = "Kieemr") -> Bool {
        let broken = brokenVisibleText(keystrokes: keystrokes)
        let correct = IMEControllerPolicySimulator.correctVisible(keystrokes: keystrokes)
        if broken.count > correct.count + 2 { return true }
        return IMEDuplicatePatternDetector.hasGrowingPrefixGlitch(broken)
            || IMEDuplicatePatternDetector.hasAdjacentDuplicateChunk(broken)
    }
}

public enum IMEMarkedCommitSimulator {
    /// Sai: chèn thêm khi vẫn còn preedit → nhân đôi / nhảy con trỏ.
    public static func brokenCommit(committed: String, preedit: String) -> String {
        committed + preedit + preedit
    }

    /// Đúng: thay preedit bằng chữ đã gõ.
    public static func correctCommit(committed: String, preedit: String) -> String {
        committed + preedit
    }
}

/// Mô phỏng controller IME cũ: `insertText(dấu)` + `return false` → app chèn thêm → `,,`.
public enum IMEDoublePunctuationSimulator {
    public static func legacyVisibleAfterPunctuation(committedVisible: String, punctuation: Character) -> String {
        committedVisible + String(punctuation) + String(punctuation)
    }

    public static func hasDuplicatedPunctuation(_ text: String) -> Bool {
        text.contains(",,") || text.contains("..") || text.contains("!!") || text.contains("??")
    }
}

/// Mô phỏng gõ đúng trên web: mỗi phím thay **một** vùng UTF-16, không append full buffer.
public enum IMEReplacementRangeSimulator {
    public static func correctVisible(keystrokes: String, method: VietnameseInputMethod = .telex) -> String {
        var buffer = ""
        var document = ""
        var rangeLocation = 0
        var rangeLength = 0

        for ch in keystrokes {
            if ch == " " {
                if !buffer.isEmpty {
                    let word = VietnameseConverter.convert(buffer, method: method)
                    document = replaceUTF16(document, location: rangeLocation, length: rangeLength, with: word)
                    buffer = ""
                    rangeLength = 0
                }
                document.append(" ")
                rangeLocation = (document as NSString).length
                continue
            }
            if ch.isLetter || "sfrxjzw".contains(ch.lowercased()) {
                if buffer.isEmpty {
                    rangeLocation = (document as NSString).length
                    rangeLength = 0
                }
                buffer.append(ch)
                let composed = VietnameseConverter.convert(buffer, method: method)
                document = replaceUTF16(document, location: rangeLocation, length: rangeLength, with: composed)
                rangeLength = (composed as NSString).length
            } else {
                if !buffer.isEmpty {
                    let word = VietnameseConverter.convert(buffer, method: method)
                    document = replaceUTF16(document, location: rangeLocation, length: rangeLength, with: word)
                    buffer = ""
                    rangeLength = 0
                }
                document.append(ch)
                rangeLocation = (document as NSString).length
            }
        }
        if !buffer.isEmpty {
            let word = VietnameseConverter.convert(buffer, method: method)
            document = replaceUTF16(document, location: rangeLocation, length: rangeLength, with: word)
        }
        return document
    }

    /// Mô phỏng `VietnameseInputController` (replace vùng UTF-16 + Delete), con trỏ luôn cuối document.
    public static func documentSteps(
        keys: [IMEUserKey],
        method: VietnameseInputMethod = .telex
    ) -> [String] {
        IMEControllerTypingSimulator.replay(keys: keys, method: method).map(\.document)
    }

    public static func documentFinal(keys: [IMEUserKey], method: VietnameseInputMethod = .telex) -> String {
        IMEControllerTypingSimulator.finalDocument(keys: keys, method: method)
    }

  /// Sai: commit lại insert thêm sau khi đã sync (dup từ).
    public static func brokenCommitAgainVisible(keystrokes: String, method: VietnameseInputMethod = .telex) -> String {
        let once = correctVisible(keystrokes: keystrokes, method: method)
        guard keystrokes.contains(" ") else { return once }
        let parts = keystrokes.split(separator: " ", omittingEmptySubsequences: false)
        var out = ""
        var buf = ""
        for (i, part) in parts.enumerated() {
            for ch in part { buf.append(ch) }
            let word = VietnameseConverter.convert(buf, method: method)
            out += word + word
            buf = ""
            if i < parts.count - 1 { out += " " }
        }
        return out
    }

    private static func replaceUTF16(_ document: String, location: Int, length: Int, with text: String) -> String {
        let ns = document as NSString
        guard location <= ns.length else { return document + text }
        return ns.replacingCharacters(in: NSRange(location: location, length: length), with: text)
    }
}

/// Mô phỏng hai lần pass-through space (keyCode 49 + ký tự ' ') trên một lần bấm.
public enum IMEDoubleSpaceEventSimulator {
    public static func twoPassThroughAfterWord(_ word: String) -> String {
        word + "  "
    }
}

/// Mô phỏng IME cũ: `insertText(" ")` + `return false` → app chèn thêm space.
public enum IMEDoubleSpaceSimulator {
    public static func legacyAfterOneSpaceKey(visibleBeforeSpace: String) -> String {
        visibleBeforeSpace + "  "
    }
}

public enum ComposeInvariantChecker {
    public static func isValid(_ session: IMEComposeSession) -> Bool {
        if session.rawBuffer.isEmpty {
            return session.visibleText == session.committed
        }
        return session.visibleText == session.committed + session.preedit
    }
}
