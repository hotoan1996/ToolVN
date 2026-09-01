import ToolVNCore

let samples: [(String, String)] = [
    ("vieetj", "việt"),
    ("hoocj", "h\u{1ED9}c"),
    ("khoongf", "khồng"),
    ("dd", "đ"),
    ("Kieemr", "Kiểm"),
    ("trowif", "trời"),
]
for (input, expected) in samples {
    let got = TelexEngine.transform(input)
    print("\(input) -> \(got == expected ? "OK" : "FAIL (\(got))")")
}
