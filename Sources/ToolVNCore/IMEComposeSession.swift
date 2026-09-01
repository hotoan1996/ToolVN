import Foundation

/// Mô phỏng gõ IME dùng preedit (`committed` + `preedit`) — **một nhấn phím = một lần `typeCharacter`**.
public struct IMEComposeSession: Sendable {
    public private(set) var committed: String = ""
    public private(set) var rawBuffer: String = ""
    public var method: VietnameseInputMethod = .telex

    public init(method: VietnameseInputMethod = .telex) {
        self.method = method
    }

    public var preedit: String {
        guard !rawBuffer.isEmpty else { return "" }
        return VietnameseConverter.convert(rawBuffer, method: method)
    }

    /// Văn bản người dùng thấy (đã commit + đang gõ).
    public var visibleText: String {
        committed + preedit
    }

  /// Gõ một ký tự (chữ, dấu Telex/VNI, hoặc space để commit từ + dấu cách).
    public mutating func typeCharacter(_ character: Character) {
        if character == " " {
            commitCurrentWord()
            committed.append(" ")
            return
        }
        if isWordBreak(character) {
            commitCurrentWord()
            committed.append(character)
            return
        }
        guard character.isASCII, character.isLetter || isModifierKey(character) else {
            commitCurrentWord()
            committed.append(character)
            return
        }
        Self.appendTelexKey(&rawBuffer, character)
    }

    /// Tránh `xo` + gõ lại `xoas` → `xoxoas` / `xoóa`.
    public static func appendTelexKey(_ rawBuffer: inout String, _ key: Character) {
        if rawBuffer.hasSuffix("xo"), key == "x" {
            rawBuffer = "x"
            return
        }
        rawBuffer.append(key)
    }

    /// Một lần xóa lùi: ưu tiên telex đang gõ; nếu không còn thì xóa ký tự đã commit (giống app khi IME pass-through Delete).
    public mutating func backspace() {
        if !rawBuffer.isEmpty {
            rawBuffer.removeLast()
            return
        }
        guard !committed.isEmpty else { return }
        committed.removeLast()
    }

    public mutating func commitCurrentWord() {
        guard !rawBuffer.isEmpty else { return }
        committed += preedit
        rawBuffer = ""
    }

    public mutating func cancelComposition() {
        rawBuffer = ""
    }

    private func isModifierKey(_ character: Character) -> Bool {
        switch method {
        case .telex:
            return "sfrxjzw".contains(character.lowercased())
        case .vni:
            return character.isNumber
        }
    }

    private func isWordBreak(_ character: Character) -> Bool {
        if character.isWhitespace { return true }
        return ",.;:!?()[]{}\"'\\/".contains(character)
    }
}

/// Phát hiện lỗi kiểu Safari/Docs khi insertText không thay thế: KKiKiKiê...
public enum IMEDuplicatePatternDetector {
    public static func hasGrowingPrefixGlitch(_ text: String) -> Bool {
        let chars = Array(text)
        guard chars.count >= 4 else { return false }
        for i in 1..<(chars.count - 1) {
            let prefix = String(chars[0...i])
            if text.dropFirst(i + 1).hasPrefix(prefix) {
                return true
            }
        }
        return false
    }

    /// Hai đoạn giống nhau liền kề (vd. `việtviệt`, `KiểmKiểm`).
    public static func hasAdjacentDuplicateChunk(_ text: String, minChunkLength: Int = 2) -> Bool {
        let chars = Array(text)
        guard chars.count >= minChunkLength * 2 else { return false }
        let maxLen = min(24, chars.count / 2)
        guard maxLen >= minChunkLength else { return false }
        for len in stride(from: maxLen, through: minChunkLength, by: -1) {
            for start in 0...(chars.count - len * 2) {
                let first = chars[start..<(start + len)]
                let second = chars[(start + len)..<(start + len * 2)]
                guard first.elementsEqual(second) else { continue }
                // Bỏ qua chuỗi ASCII thuần (telex chưa convert) — tránh báo nhầm "the"/"he".
                if first.allSatisfy({ $0.isASCII }) { continue }
                return true
            }
        }
        return false
    }

    /// Space thừa so với số space người dùng gõ (một phím space → không được thêm space ẩn).
    public static func hasExtraTrailingSpaces(actual: String, keystrokePrefix: String) -> Bool {
        let expected = trailingSpaceCount(keystrokePrefix)
        let got = trailingSpaceCount(actual)
        return got > expected
    }

    public static func trailingSpaceCount(_ text: String) -> Int {
        var count = 0
        for ch in text.reversed() {
            if ch == " " { count += 1 } else { break }
        }
        return count
    }

    /// Dấu câu lặp do IME + app cùng chèn (`,,` khi prefix chỉ một dấu phẩy).
    public static func hasExtraPunctuationDoubles(actual: String, keystrokePrefix: String) -> Bool {
        for punct in [",", ".", "!", "?"] {
            let expected = keystrokePrefix.filter { String($0) == punct }.count
            let got = actual.filter { String($0) == punct }.count
            if got > expected { return true }
        }
        return false
    }
}
