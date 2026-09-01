import Foundation

/// Bộ gõ VNI: dấu 1–5, mũ 6/7, đ = d9 (hoặc dd + quy tắc tương tự).
public enum VNIEngine {
    public static func transform(_ input: String) -> String {
        guard !input.isEmpty else { return input }
        return input
            .split(separator: " ", omittingEmptySubsequences: false)
            .map { transformToken(String($0)) }
            .joined(separator: " ")
    }

    private static func transformToken(_ token: String) -> String {
        guard !token.isEmpty else { return token }
        var result = ""
        var i = token.startIndex

        while i < token.endIndex {
            let ch = token[i]
            if ch.isLetter || ch.isNumber {
                var j = token.index(after: i)
                while j < token.endIndex, token[j].isLetter || token[j].isNumber {
                    j = token.index(after: j)
                }
                result += transformSyllable(String(token[i..<j]))
                i = j
            } else {
                result.append(ch)
                i = token.index(after: i)
            }
        }
        return result
    }

    private static func transformSyllable(_ syllable: String) -> String {
        var chars = Array(syllable)
        if chars.count >= 2,
           chars[0].lowercased() == "d",
           chars[1].lowercased() == "d" {
            let upper = chars[0].isUppercase || chars[1].isUppercase
            chars[0] = upper ? "Đ" : "đ"
            chars.remove(at: 1)
        }
        var changed = true
        while changed {
            changed = false
            var i = 0
            while i < chars.count {
                let ch = chars[i]
                if ch.lowercased() == "d", i + 1 < chars.count, chars[i + 1] == "9" {
                    chars[i] = ch.isUppercase ? "Đ" : "đ"
                    chars.remove(at: i + 1)
                    changed = true
                    continue
                }
                if ch.isLetter, i + 1 < chars.count, let digit = chars[i + 1].wholeNumberValue {
                    if let replaced = replaceVNI(vowel: ch, digit: digit) {
                        let target = (1...5).contains(digit)
                            ? toneTargetIndex(chars: chars, at: i, digit: digit) ?? i
                            : i
                        if target == i {
                            chars[i] = replaced
                            chars.remove(at: i + 1)
                        } else {
                            if let toned = replaceVNI(vowel: chars[target], digit: digit) {
                                chars[target] = toned
                                chars.remove(at: i + 1)
                            }
                        }
                        changed = true
                        continue
                    }
                    if (1...5).contains(digit), !isVowel(ch) {
                        if let vowelIndex = lastVowelIndex(in: chars, before: i) {
                            if let toned = replaceVNI(vowel: chars[vowelIndex], digit: digit) {
                                chars[vowelIndex] = toned
                                chars.remove(at: i + 1)
                                changed = true
                                continue
                            }
                        }
                    }
                }
                i += 1
            }
        }
        return String(chars)
    }

    private static func isVowel(_ ch: Character) -> Bool {
        "aeiouyAEIOUYâăêôơưÂĂÊÔƠƯ".contains(ch)
    }

    private static func lastVowelIndex(in chars: [Character], before index: Int) -> Int? {
        guard index > 0 else { return nil }
        for i in stride(from: index - 1, through: 0, by: -1) {
            if isVowel(chars[i]) { return i }
        }
        return nil
    }

    /// Vị trí đặt dấu thanh VNI (ươ + i cuối → dấu trên ơ).
    private static func toneTargetIndex(chars: [Character], at index: Int, digit: Int) -> Int? {
        guard (1...5).contains(digit) else { return nil }
        let ch = chars[index]
        guard lowerChar(ch) == "i", index >= 2 else { return nil }
        let prev = lowerChar(chars[index - 1])
        let prev2 = lowerChar(chars[index - 2])
        if prev == "ơ", prev2 == "ư" {
            return index - 1
        }
        return nil
    }

    private static func lowerChar(_ ch: Character) -> Character {
        Character(String(ch).lowercased())
    }

    private static func replaceVNI(vowel: Character, digit: Int) -> Character? {
        let lower = Character(String(vowel).lowercased())
        let upper = vowel.isUppercase

        switch digit {
        case 1...5:
            guard let toned = toneRow(for: lower)?[digit] else { return nil }
            return upper ? Character(String(toned).uppercased()) : toned
        case 6:
            let map: [Character: Character] = ["a": "â", "e": "ê", "o": "ô"]
            guard let m = map[lower] else { return nil }
            return upper ? Character(String(m).uppercased()) : m
        case 7:
            let map: [Character: Character] = ["a": "ă", "o": "ơ", "u": "ư"]
            guard let m = map[lower] else { return nil }
            return upper ? Character(String(m).uppercased()) : m
        default:
            return nil
        }
    }

    private static func toneRow(for base: Character) -> [Int: Character]? {
        let table: [Character: [Character]] = [
            "a": ["a", "á", "à", "ả", "ã", "ạ"],
            "ă": ["ă", "ắ", "ằ", "ẳ", "ẵ", "ặ"],
            "â": ["â", "ấ", "ầ", "ẩ", "ẫ", "ậ"],
            "e": ["e", "é", "è", "ẻ", "ẽ", "ẹ"],
            "ê": ["ê", "ế", "ề", "ể", "ễ", "ệ"],
            "i": ["i", "í", "ì", "ỉ", "ĩ", "ị"],
            "o": ["o", "ó", "ò", "ỏ", "õ", "ọ"],
            "ô": ["ô", "ố", "ồ", "ổ", "ỗ", "ộ"],
            "ơ": ["ơ", "ớ", "ờ", "ở", "ỡ", "ợ"],
            "u": ["u", "ú", "ù", "ủ", "ũ", "ụ"],
            "ư": ["ư", "ứ", "ừ", "ử", "ữ", "ự"],
            "y": ["y", "ý", "ỳ", "ỷ", "ỹ", "ỵ"],
        ]
        guard let row = table[base] else { return nil }
        var out: [Int: Character] = [:]
        for idx in 1...5 where idx < row.count {
            out[idx] = row[idx]
        }
        return out
    }
}
