import Foundation

public enum VNIGoldenFixtures {
    public static let all: [IMETestCase] = tones + marks
}

public enum VNIExtendedFixtures {
    public static let all: [IMETestCase] = words + parity
}

public enum VNIFixtures {
    public static var all: [IMETestCase] { VNIGoldenFixtures.all + VNIExtendedFixtures.all }
}

private let tones: [IMETestCase] = [
    .init(category: "vni_tone", input: "a1", expected: "á"),
    .init(category: "vni_tone", input: "a2", expected: "à"),
    .init(category: "vni_tone", input: "a3", expected: "ả"),
    .init(category: "vni_tone", input: "a4", expected: "ã"),
    .init(category: "vni_tone", input: "a5", expected: "ạ"),
    .init(category: "vni_tone", input: "e1", expected: "é"),
    .init(category: "vni_tone", input: "o2", expected: "ò"),
    .init(category: "vni_tone", input: "u3", expected: "ủ"),
    .init(category: "vni_tone", input: "y5", expected: "ỵ"),
]

private let marks: [IMETestCase] = [
    .init(category: "vni_mark", input: "d9", expected: "đ"),
    .init(category: "vni_mark", input: "a6", expected: "â"),
    .init(category: "vni_mark", input: "a7", expected: "ă"),
    .init(category: "vni_mark", input: "e6", expected: "ê"),
    .init(category: "vni_mark", input: "o6", expected: "ô"),
    .init(category: "vni_mark", input: "o7", expected: "ơ"),
    .init(category: "vni_mark", input: "u7", expected: "ư"),
    .init(category: "vni_mark", input: "a61", expected: "ấ"),
    .init(category: "vni_mark", input: "u72", expected: "ừ"),
]

private let words: [IMETestCase] = [
    .init(category: "vni_word", input: "ho6c5", expected: "h\u{1ED9}c"),
]

private let parity: [IMETestCase] = [
    .init(category: "vni_parity", input: "ddu7o7c5", expected: "được"),
    .init(category: "vni_parity", input: "Vie6t5", expected: "Việt"),
    .init(category: "vni_parity", input: "tie6n1", expected: "tiến"),
    .init(category: "vni_parity", input: "ngu7o7i2", expected: "người"),
]
