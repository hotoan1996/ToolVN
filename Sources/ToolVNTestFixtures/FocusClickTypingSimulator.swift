import Foundation
import ToolVNCore

/// Mô phỏng click đặt con trỏ rồi gõ (UTF-16).
public enum FocusClickTypingSimulator {
    public static func finalDocument(keys: [IMEUserKey], method: VietnameseInputMethod = .telex) -> String {
        var rawBuffer = ""
        var document = ""
        var rangeLocation = 0
        var rangeLength = 0
        var caret = 0

        func docLen() -> Int { (document as NSString).length }

        func replace(_ loc: Int, _ len: Int, _ text: String) -> String {
            let ns = document as NSString
            guard loc <= ns.length else { return document + text }
            return ns.replacingCharacters(in: NSRange(location: loc, length: len), with: text)
        }

        func clearPreedit() {
            guard rangeLength > 0 else { return }
            document = replace(rangeLocation, rangeLength, "")
            if caret > rangeLocation + rangeLength { caret -= rangeLength }
            else if caret > rangeLocation { caret = rangeLocation }
            rangeLength = 0
        }

        func freezeIfNeeded() {
            guard !rawBuffer.isEmpty, rangeLength > 0 else { return }
            let end = rangeLocation + rangeLength
            guard caret < rangeLocation || caret > end else { return }
            let composed = VietnameseConverter.convert(rawBuffer, method: method)
            if !composed.isEmpty {
                document = replace(rangeLocation, rangeLength, composed)
            }
            rawBuffer = ""
            rangeLength = 0
        }

        func sync() {
            guard !rawBuffer.isEmpty else { clearPreedit(); return }
            let composed = VietnameseConverter.convert(rawBuffer, method: method)
            guard !composed.isEmpty else { clearPreedit(); return }
            if rangeLength > 0 {
                document = replace(rangeLocation, rangeLength, composed)
            } else {
                rangeLocation = min(caret, docLen())
                document = replace(rangeLocation, 0, composed)
            }
            rangeLength = (composed as NSString).length
            caret = rangeLocation + rangeLength
        }

        func commit() {
            guard !rawBuffer.isEmpty else { return }
            sync()
            let endOfWord = rangeLocation + rangeLength
            rawBuffer = ""
            rangeLength = 0
            caret = endOfWord
            rangeLocation = caret
        }

        for key in keys {
            switch key {
            case .caretAtUTF16(let pos):
                commit()
                caret = min(max(0, pos), docLen())
                rangeLocation = caret
                rangeLength = 0

            case .backspace:
                if !rawBuffer.isEmpty {
                    rawBuffer.removeLast()
                    sync()
                } else if rangeLength > 0 {
                    clearPreedit()
                } else if caret > 0 {
                    let ns = document as NSString
                    let start = ns.rangeOfComposedCharacterSequence(at: caret - 1).location
                    document = ns.replacingCharacters(in: NSRange(location: start, length: caret - start), with: "")
                    caret = start
                }

            case .character(let ch):
                if ch == " " {
                    commit()
                    document = replace(caret, 0, " ")
                    caret += 1
                    rangeLocation = caret
                    continue
                }
                if rawBuffer.isEmpty, rangeLength > 0 { clearPreedit() }
                if !rawBuffer.isEmpty { freezeIfNeeded() }
                if rawBuffer.isEmpty {
                    rangeLength = 0
                    rangeLocation = min(caret, docLen())
                }
                IMEComposeSession.appendTelexKey(&rawBuffer, ch)
                sync()
            }
        }
        return document
    }
}
