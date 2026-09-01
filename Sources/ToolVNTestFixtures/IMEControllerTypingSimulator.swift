import Foundation
import ToolVNCore

/// Mô phỏng `VietnameseInputController` với **setMarkedText** (preedit không nằm trong document cho tới khi chốt).
public enum IMEControllerTypingSimulator {
    public struct Step: Sendable {
        public let index: Int
        public let key: IMEUserKey
        /// Chữ người dùng thấy (đã chốt + đang gõ marked).
        public let document: String
        public let rawBuffer: String
    }

    public static func replay(
        keys: [IMEUserKey],
        method: VietnameseInputMethod = .telex
    ) -> [Step] {
        var rawBuffer = ""
        var committedDocument = ""
        var markedPreedit = ""
        var steps: [Step] = []

        func visible() -> String { committedDocument + markedPreedit }

        func syncMarked() {
            guard !rawBuffer.isEmpty else {
                markedPreedit = ""
                return
            }
            let composed = VietnameseConverter.convert(rawBuffer, method: method)
            markedPreedit = composed.isEmpty ? "" : composed
        }

        func commitWord() {
            guard !rawBuffer.isEmpty else { return }
            syncMarked()
            committedDocument += markedPreedit
            rawBuffer = ""
            markedPreedit = ""
        }

        func clearStaleMarkedIfBufferEmpty() {
            if rawBuffer.isEmpty, !markedPreedit.isEmpty {
                markedPreedit = ""
            }
        }

        func passThroughDeleteOneChar() {
            markedPreedit = ""
            committedDocument = deleteOneUTF16BeforeEnd(committedDocument)
        }

        for (offset, key) in keys.enumerated() {
            switch key {
            case .caretAtUTF16:
                commitWord()

            case .backspace:
                if !rawBuffer.isEmpty {
                    rawBuffer.removeLast()
                    syncMarked()
                } else if !markedPreedit.isEmpty {
                    // Preedit marked còn sót (tương đương controller clear marked, nuốt phím).
                    markedPreedit = ""
                } else {
                    passThroughDeleteOneChar()
                }

            case .character(let ch):
                if ch == " " {
                    commitWord()
                    committedDocument.append(" ")
                } else if ch.isWhitespace || ",.;:!?()[]{}\"'\\/".contains(ch) {
                    commitWord()
                    committedDocument.append(ch)
                } else if ch.isASCII, ch.isLetter || "sfrxjzw".contains(ch.lowercased()) {
                    clearStaleMarkedIfBufferEmpty()
                    IMEComposeSession.appendTelexKey(&rawBuffer, ch)
                    syncMarked()
                } else {
                    commitWord()
                    committedDocument.append(ch)
                }
            }

            steps.append(
                Step(
                    index: offset + 1,
                    key: key,
                    document: visible(),
                    rawBuffer: rawBuffer
                )
            )
        }
        return steps
    }

    public static func finalDocument(keys: [IMEUserKey], method: VietnameseInputMethod = .telex) -> String {
        replay(keys: keys, method: method).last?.document ?? ""
    }

    private static func deleteOneUTF16BeforeEnd(_ document: String) -> String {
        let ns = document as NSString
        guard ns.length > 0 else { return document }
        let start = ns.rangeOfComposedCharacterSequence(at: ns.length - 1).location
        return ns.replacingCharacters(in: NSRange(location: start, length: ns.length - start), with: "")
    }
}

public enum IMEUserKeyBuilders {
    public static func telex(_ s: String) -> [IMEUserKey] {
        s.map { .character($0) }
    }

    public static func caret(_ utf16Offset: Int) -> IMEUserKey {
        .caretAtUTF16(utf16Offset)
    }
}
