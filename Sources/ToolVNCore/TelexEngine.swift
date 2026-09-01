import Foundation

/// Bộ gõ Telex (engine theo quy tắc xkey / Unikey phổ biến).
public enum TelexEngine {
    public static func transform(_ input: String) -> String {
        TelexTransform.transformBuffer(input)
    }
}

enum TelexTransform {
    static func transformBuffer(_ buffer: String) -> String {
        var result = ""
        var currentWord = ""

        for ch in buffer {
            if ch.isWhitespace || (ch.isASCII && ch.isPunctuation && ch != "[" && ch != "]") {
                result += processWord(currentWord)
                result.append(ch)
                currentWord = ""
            } else {
                currentWord.append(ch)
            }
        }
        result += processWord(currentWord)
        return result
    }

    private static func lowerChar(_ ch: Character) -> Character {
        String(ch).lowercased().first ?? ch
    }

    private static func processWord(_ word: String) -> String {
        if word.isEmpty { return "" }

        if shouldBypassBrandWord(word) {
            return word
        }

        var outChars: [Character] = []
        var outUpper: [Bool] = []
        var tone: Character?
        var bypass = false

        let original = Array(word)
        var i = 0

        while i < original.count {
            let current = original[i]
            let currentLower = lowerChar(current)

            if bypass {
                outChars.append(currentLower)
                outUpper.append(current.isUppercase)
                i += 1
                continue
            }

            let next = i + 1 < original.count ? original[i + 1] : nil
            let nextLower = next.map { lowerChar($0) }
            let thirdLower = i + 2 < original.count ? lowerChar(original[i + 2]) : nil

            switch (currentLower, nextLower, thirdLower) {
            case ("a", "a", "a"):
                outChars.append("a"); outUpper.append(original[i].isUppercase)
                outChars.append("a"); outUpper.append(original[i + 1].isUppercase)
                bypass = true; i += 3
            case ("e", "e", "e"):
                outChars.append("e"); outUpper.append(original[i].isUppercase)
                outChars.append("e"); outUpper.append(original[i + 1].isUppercase)
                bypass = true; i += 3
            case ("o", "o", "o"):
                outChars.append("o"); outUpper.append(original[i].isUppercase)
                outChars.append("o"); outUpper.append(original[i + 1].isUppercase)
                bypass = true; i += 3
            case ("a", "a", _):
                outChars.append("â"); outUpper.append(current.isUppercase); i += 2
            case ("e", "e", _):
                outChars.append("ê"); outUpper.append(current.isUppercase); i += 2
            case ("o", "o", _):
                outChars.append("ô"); outUpper.append(current.isUppercase); i += 2
            case ("a", "w", _):
                outChars.append("ă"); outUpper.append(current.isUppercase); i += 2
            case ("o", "w", let third):
                if third == nil, shouldKeepLiteralOWAtWordEnd(outChars: outChars) {
                    outChars.append("o"); outUpper.append(original[i].isUppercase)
                    outChars.append("w"); outUpper.append(original[i + 1].isUppercase)
                    i += 2
                } else {
                    outChars.append("ơ"); outUpper.append(current.isUppercase)
                    i += 2
                }
            case ("u", "w", _):
                outChars.append("ư"); outUpper.append(current.isUppercase); i += 2
            case ("d", "d", "d"):
                outChars.append("d"); outUpper.append(original[i].isUppercase)
                outChars.append("d"); outUpper.append(original[i + 1].isUppercase)
                bypass = true; i += 3
            case ("d", "d", _):
                outChars.append("đ"); outUpper.append(current.isUppercase); i += 2
            case ("w", "w", _):
                handleDoubleW(&outChars, &outUpper, original: original, at: i, bypass: &bypass)
                i += 2
            case ("w", _, _):
                handleStandaloneW(&outChars, &outUpper, current: current, bypass: &bypass)
                i += 1
            case ("[", _, _):
                outChars.append("ư"); outUpper.append(false); i += 1
            case ("]", _, _):
                outChars.append("ơ"); outUpper.append(false); i += 1
            case ("s", _, _), ("f", _, _), ("r", _, _), ("x", _, _), ("j", _, _):
                handleToneKey(
                    currentLower, current: current,
                    outChars: &outChars, outUpper: &outUpper,
                    tone: &tone, bypass: &bypass
                )
                i += 1
            case ("z", _, _):
                handleZ(outChars: &outChars, tone: &tone, bypass: &bypass, current: current, outUpper: &outUpper)
                i += 1
            default:
                outChars.append(currentLower)
                outUpper.append(current.isUppercase)
                i += 1
            }
        }

        var outStr = String(outChars)

        if bypass {
            return restoreCase(outStr, outUpper: outUpper)
        }

        if outStr.contains("uơ") {
            outStr = outStr.replacingOccurrences(of: "uơ", with: "ươ")
        }

        if let tone {
            outStr = applyTone(outStr, toneChar: tone)
        }

        var result = restoreCase(outStr, outUpper: outUpper)

        let hasUpper = word.contains { $0.isUppercase }
        if hasUpper && word.allSatisfy({ !$0.isLetter || $0.isUppercase }) {
            result = result.uppercased()
        }

        return relocateTone(result)
    }

    /// Tên riêng / thương hiệu kiểu ToolVN — không gõ dấu, nhiều chữ hoa.
    private static func shouldBypassBrandWord(_ word: String) -> Bool {
        let letters = word.filter(\.isLetter)
        guard !letters.isEmpty else { return false }
        let hasLower = letters.contains { $0.isLowercase }
        let upperCount = letters.filter(\.isUppercase).count
        let hasToneKey = word.last.map { "sfrxj".contains($0.lowercased()) } ?? false
        return hasLower && upperCount >= 2 && !hasToneKey
    }

    private static func handleDoubleW(
        _ outChars: inout [Character],
        _ outUpper: inout [Bool],
        original: [Character],
        at i: Int,
        bypass: inout Bool
    ) {
        if let last = outChars.last {
            let lastLower = lowerChar(last)
            if lastLower == "ư" {
                let wasUpper = outUpper.last ?? false
                outChars.removeLast(); outUpper.removeLast()
                outChars.append("u"); outUpper.append(wasUpper)
                outChars.append("w"); outUpper.append(original[i].isUppercase)
                bypass = true
            } else if lastLower == "ơ" {
                let wasUpper = outUpper.last ?? false
                outChars.removeLast(); outUpper.removeLast()
                outChars.append("o"); outUpper.append(wasUpper)
                outChars.append("w"); outUpper.append(original[i].isUppercase)
                bypass = true
            } else {
                outChars.append("w"); outUpper.append(original[i].isUppercase)
                bypass = true
            }
        } else {
            outChars.append("w"); outUpper.append(original[i].isUppercase)
            bypass = true
        }
    }

    private static func handleStandaloneW(
        _ outChars: inout [Character],
        _ outUpper: inout [Bool],
        current: Character,
        bypass: inout Bool
    ) {
        if let last = outChars.last {
            let lastLower = lowerChar(last)
            if lastLower == "u" {
                let wasUpper = outUpper.last ?? false
                outChars.removeLast(); outUpper.removeLast()
                outChars.append(wasUpper ? "Ư" : "ư")
                outUpper.append(wasUpper)
            } else if lastLower == "o" {
                let wasUpper = outUpper.last ?? false
                outChars.removeLast(); outUpper.removeLast()
                outChars.append(wasUpper ? "Ơ" : "ơ")
                outUpper.append(wasUpper)
            } else if lastLower == "a" {
                let wasUpper = outUpper.last ?? false
                outChars.removeLast(); outUpper.removeLast()
                outChars.append(wasUpper ? "Ă" : "ă")
                outUpper.append(wasUpper)
            } else if lastLower == "ă" {
                let wasUpper = outUpper.last ?? false
                outChars.removeLast(); outUpper.removeLast()
                outChars.append("a"); outUpper.append(wasUpper)
                outChars.append("w"); outUpper.append(current.isUppercase)
                bypass = true
            } else if lastLower == "ơ" {
                let wasUpper = outUpper.last ?? false
                outChars.removeLast(); outUpper.removeLast()
                outChars.append("o"); outUpper.append(wasUpper)
                outChars.append("w"); outUpper.append(current.isUppercase)
                bypass = true
            } else if lastLower == "i", outChars.count >= 2, lowerChar(outChars[outChars.count - 2]) == "u" {
                let uIdx = outChars.count - 2
                let wasUpper = outUpper[uIdx]
                outChars[uIdx] = wasUpper ? "Ư" : "ư"
            } else if isTelexConsonant(lastLower), applyWToPrecedingVowel(outChars: &outChars, outUpper: &outUpper) {
                // hopw → hơp (w sau phụ âm vẫn tác lên o/u/a trước đó)
            } else {
                outChars.append("ư")
                outUpper.append(current.isUppercase)
            }
        } else {
            outChars.append("ư")
            outUpper.append(current.isUppercase)
        }
    }

    private static let telexVowels = "aeiouyâăêôơư"

    private static func isTelexConsonant(_ ch: Character) -> Bool {
        ch.isLetter && !telexVowels.contains(ch)
    }

    /// Giữ `ow` literal (how, show): phụ âm ngay trước `o` và chưa có nguyên âm nào trong buffer (tránh hopow → sai).
    private static func shouldKeepLiteralOWAtWordEnd(outChars: [Character]) -> Bool {
        guard let last = outChars.last, isTelexConsonant(lowerChar(last)) else { return false }
        return !outChars.contains { telexVowels.contains(lowerChar($0)) }
    }

  /// w sau phụ âm: đổi nguyên âm o/u/a gần nhất phía trước (hopw → hơp).
    private static func applyWToPrecedingVowel(
        outChars: inout [Character],
        outUpper: inout [Bool]
    ) -> Bool {
        guard outChars.count >= 2 else { return false }
        for idx in stride(from: outChars.count - 2, through: 0, by: -1) {
            let ch = lowerChar(outChars[idx])
            switch ch {
            case "o":
                let wasUpper = outUpper[idx]
                outChars[idx] = wasUpper ? "Ơ" : "ơ"
                return true
            case "u":
                let wasUpper = outUpper[idx]
                outChars[idx] = wasUpper ? "Ư" : "ư"
                return true
            case "a":
                let wasUpper = outUpper[idx]
                outChars[idx] = wasUpper ? "Ă" : "ă"
                return true
            default:
                if isTelexConsonant(ch) { continue }
                return false
            }
        }
        return false
    }

    private static func handleToneKey(
        _ key: Character,
        current: Character,
        outChars: inout [Character],
        outUpper: inout [Bool],
        tone: inout Character?,
        bypass: inout Bool
    ) {
        let vowels = "aeiouyâăêôơư"
        let hasVowel = outChars.contains { vowels.contains(lowerChar($0)) }
        if hasVowel {
            if tone == key {
                // Gõ lại cùng phím dấu → bỏ dấu, ký tự dấu thành chữ (as + s → as, không phải ás).
                tone = nil
                outChars.append(key)
                outUpper.append(current.isUppercase)
            } else {
                tone = key
            }
        } else {
            outChars.append(current)
            outUpper.append(current.isUppercase)
        }
    }

    private static func handleZ(
        outChars: inout [Character],
        tone: inout Character?,
        bypass: inout Bool,
        current: Character,
        outUpper: inout [Bool]
    ) {
        let vowels = "aeiouyâăêôơư"
        let hasVowel = outChars.contains { vowels.contains(lowerChar($0)) }
        if hasVowel && tone != nil {
            tone = nil
            bypass = true
        } else {
            outChars.append("z")
            outUpper.append(current.isUppercase)
        }
    }

    private static func restoreCase(_ text: String, outUpper: [Bool]) -> String {
        var result = ""
        for (i, ch) in text.enumerated() {
            if outUpper.indices.contains(i), outUpper[i] {
                result.append(String(ch).uppercased())
            } else {
                result.append(ch)
            }
        }
        return result
    }

    private static func applyTone(_ word: String, toneChar: Character) -> String {
        let vowels = "aeiouyâăêôơư"
        let markedVowels = "âăêôơư"
        var chars = Array(word)
        let lastChar = lowerChar(chars.last ?? " ")
        let endsWithConsonant = !vowels.contains(lastChar)

        var wordLower = String(chars.map { lowerChar($0) })
        let hasUoPattern = wordLower.contains("ưo") && !wordLower.contains("ươ")

        if hasUoPattern && endsWithConsonant {
            for idx in 0..<(chars.count - 1) {
                if lowerChar(chars[idx]) == "ư", lowerChar(chars[idx + 1]) == "o" {
                    chars[idx + 1] = chars[idx + 1].isUppercase ? "Ơ" : "ơ"
                    break
                }
            }
            wordLower = String(chars.map { lowerChar($0) })
        }

        var vowelIndices: [Int] = []
        for (idx, ch) in chars.enumerated() where vowels.contains(lowerChar(ch)) {
            vowelIndices.append(idx)
        }

        if vowelIndices.isEmpty {
            var s = String(chars)
            s.append(toneChar)
            return s
        }

        if vowelIndices.count > 1, chars.count >= 2 {
            let first = lowerChar(chars[0])
            let second = lowerChar(chars[1])
            if (first == "q" && second == "u") || (first == "g" && second == "i") {
                vowelIndices.removeFirst()
            }
        }

        let hasUoCluster = wordLower.contains("ươ")
        let targetIdx: Int

        if hasUoCluster && endsWithConsonant && vowelIndices.count >= 2 {
            let uoPair = vowelIndices.filter {
                let ch = lowerChar(chars[$0])
                return ch == "ư" || ch == "ơ"
            }
            if uoPair.count >= 2 {
                targetIdx = uoPair[1]
            } else {
                targetIdx = vowelIndices[vowelIndices.count - 1]
            }
        } else if let marked = vowelIndices.last(where: { markedVowels.contains(lowerChar(chars[$0])) }) {
            targetIdx = marked
        } else if endsWithConsonant {
            targetIdx = vowelIndices[vowelIndices.count - 1]
        } else if vowelIndices.count >= 2 {
            targetIdx = vowelIndices[vowelIndices.count - 2]
        } else {
            targetIdx = vowelIndices[0]
        }

        var result = ""
        for (idx, ch) in chars.enumerated() {
            if idx == targetIdx {
                result.append(addMark(ch, tone: toneChar))
            } else {
                result.append(ch)
            }
        }
        return result
    }

    private static func addMark(_ ch: Character, tone: Character) -> Character {
        let upper = ch.isUppercase
        let lower = lowerChar(ch)
        let mapped: Character? = {
            switch (lower, tone) {
            case ("a", "s"): return "á"
            case ("a", "f"): return "à"
            case ("a", "r"): return "ả"
            case ("a", "x"): return "ã"
            case ("a", "j"): return "ạ"
            case ("â", "s"): return "ấ"
            case ("â", "f"): return "ầ"
            case ("â", "r"): return "ẩ"
            case ("â", "x"): return "ẫ"
            case ("â", "j"): return "ậ"
            case ("ă", "s"): return "ắ"
            case ("ă", "f"): return "ằ"
            case ("ă", "r"): return "ẳ"
            case ("ă", "x"): return "ẵ"
            case ("ă", "j"): return "ặ"
            case ("e", "s"): return "é"
            case ("e", "f"): return "è"
            case ("e", "r"): return "ẻ"
            case ("e", "x"): return "ẽ"
            case ("e", "j"): return "ẹ"
            case ("ê", "s"): return "ế"
            case ("ê", "f"): return "ề"
            case ("ê", "r"): return "ể"
            case ("ê", "x"): return "ễ"
            case ("ê", "j"): return "ệ"
            case ("o", "s"): return "ó"
            case ("o", "f"): return "ò"
            case ("o", "r"): return "ỏ"
            case ("o", "x"): return "õ"
            case ("o", "j"): return "ọ"
            case ("ô", "s"): return "ố"
            case ("ô", "f"): return "ồ"
            case ("ô", "r"): return "ổ"
            case ("ô", "x"): return "ỗ"
            case ("ô", "j"): return "ộ"
            case ("ơ", "s"): return "ớ"
            case ("ơ", "f"): return "ờ"
            case ("ơ", "r"): return "ở"
            case ("ơ", "x"): return "ỡ"
            case ("ơ", "j"): return "ợ"
            case ("u", "s"): return "ú"
            case ("u", "f"): return "ù"
            case ("u", "r"): return "ủ"
            case ("u", "x"): return "ũ"
            case ("u", "j"): return "ụ"
            case ("ư", "s"): return "ứ"
            case ("ư", "f"): return "ừ"
            case ("ư", "r"): return "ử"
            case ("ư", "x"): return "ữ"
            case ("ư", "j"): return "ự"
            case ("i", "s"): return "í"
            case ("i", "f"): return "ì"
            case ("i", "r"): return "ỉ"
            case ("i", "x"): return "ĩ"
            case ("i", "j"): return "ị"
            case ("y", "s"): return "ý"
            case ("y", "f"): return "ỳ"
            case ("y", "r"): return "ỷ"
            case ("y", "x"): return "ỹ"
            case ("y", "j"): return "ỵ"
            default: return nil
            }
        }()
        guard let mapped else { return ch }
        return upper ? Character(String(mapped).uppercased()) : mapped
    }

    private static func extractTone(_ ch: Character) -> (Character, Character?) {
        let upper = ch.isUppercase
        let lower = lowerChar(ch)
        let pair: (Character, Character?)? = {
            switch lower {
            case "á": return ("a", "s")
            case "à": return ("a", "f")
            case "ả": return ("a", "r")
            case "ã": return ("a", "x")
            case "ạ": return ("a", "j")
            case "ấ": return ("â", "s")
            case "ầ": return ("â", "f")
            case "ẩ": return ("â", "r")
            case "ẫ": return ("â", "x")
            case "ậ": return ("â", "j")
            case "ắ": return ("ă", "s")
            case "ằ": return ("ă", "f")
            case "ẳ": return ("ă", "r")
            case "ẵ": return ("ă", "x")
            case "ặ": return ("ă", "j")
            case "é": return ("e", "s")
            case "è": return ("e", "f")
            case "ẻ": return ("e", "r")
            case "ẽ": return ("e", "x")
            case "ẹ": return ("e", "j")
            case "ế": return ("ê", "s")
            case "ề": return ("ê", "f")
            case "ể": return ("ê", "r")
            case "ễ": return ("ê", "x")
            case "ệ": return ("ê", "j")
            case "ó": return ("o", "s")
            case "ò": return ("o", "f")
            case "ỏ": return ("o", "r")
            case "õ": return ("o", "x")
            case "ọ": return ("o", "j")
            case "ố": return ("ô", "s")
            case "ồ": return ("ô", "f")
            case "ổ": return ("ô", "r")
            case "ỗ": return ("ô", "x")
            case "ộ": return ("ô", "j")
            case "ớ": return ("ơ", "s")
            case "ờ": return ("ơ", "f")
            case "ở": return ("ơ", "r")
            case "ỡ": return ("ơ", "x")
            case "ợ": return ("ơ", "j")
            case "ú": return ("u", "s")
            case "ù": return ("u", "f")
            case "ủ": return ("u", "r")
            case "ũ": return ("u", "x")
            case "ụ": return ("u", "j")
            case "ứ": return ("ư", "s")
            case "ừ": return ("ư", "f")
            case "ử": return ("ư", "r")
            case "ữ": return ("ư", "x")
            case "ự": return ("ư", "j")
            case "í": return ("i", "s")
            case "ì": return ("i", "f")
            case "ỉ": return ("i", "r")
            case "ĩ": return ("i", "x")
            case "ị": return ("i", "j")
            case "ý": return ("y", "s")
            case "ỳ": return ("y", "f")
            case "ỷ": return ("y", "r")
            case "ỹ": return ("y", "x")
            case "ỵ": return ("y", "j")
            default: return nil
            }
        }()
        guard let (base, tone) = pair else { return (ch, nil) }
        let baseChar = upper ? Character(String(base).uppercased()) : base
        return (baseChar, tone)
    }

    private static func relocateTone(_ word: String) -> String {
        var foundTone: Character?
        var without = ""
        for ch in word {
            let (base, tone) = extractTone(ch)
            if tone != nil, foundTone == nil { foundTone = tone }
            without.append(base)
        }
        guard let tone = foundTone else { return word }
        return applyTone(without, toneChar: tone)
    }
}
