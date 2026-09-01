import Foundation
import ToolVNTestFixtures

struct CLIOptions {
    var filterCategory: String?
    var telexOnly = false
    var vniOnly = false
    var typingOnly = false
    var matrixOnly = false
    var longOnly = false
    var strict = false

    static func parse(_ args: [String]) -> CLIOptions {
        var options = CLIOptions()
        var i = 0
        while i < args.count {
            switch args[i] {
            case "--category", "-c":
                i += 1
                if i < args.count { options.filterCategory = args[i] }
            case "--telex":
                options.telexOnly = true
            case "--vni":
                options.vniOnly = true
            case "--typing":
                options.typingOnly = true
            case "--matrix":
                options.matrixOnly = true
            case "--long":
                options.longOnly = true
            case "--strict":
                options.strict = true
            case "--help", "-h":
                printUsage()
                exit(0)
            default:
                break
            }
            i += 1
        }
        return options
    }
}

func printUsage() {
    print("""
    toolvn-test — kiểm tra engine + mô phỏng gõ IME ToolVN

    Cách dùng:
      swift run toolvn-test              # engine + typing + regression Safari
      swift run toolvn-test --strict     # chỉ golden engine
      swift run toolvn-test -c delete_continueCurrentWord
      swift run toolvn-test -c delete_startNewWord
      swift run toolvn-test -c delete_afterCommitted
      swift run toolvn-test --typing
      swift run toolvn-test --matrix     # ma trận + validate golden matrix
      swift run toolvn-test --long       # 20 đoạn Telex dài (engine + gõ từng phím)
      swift run toolvn-test -c telex_long
      swift run toolvn-test -c comprehensive # ma trận + xóa + focus + ngữ cảnh + VNI
      swift run toolvn-test -c vni_comprehensive # chỉ bộ VNI + parity Telex/VNI
      swift run toolvn-test -c method_parity
      swift run toolvn-test -c select_all_cursor   # ⌘A đang gõ (Cursor chat)
      swift run toolvn-test -c marked_commit       # marked text / commit / range
      swift run toolvn-test --vni --strict
    """)
}

func filter(_ cases: [IMETestCase], category: String?) -> [IMETestCase] {
    guard let category else { return cases }
    return cases.filter { $0.category == category }
}

func filterTyping(_ cases: [TypingSequenceCase], category: String?) -> [TypingSequenceCase] {
    guard let category else { return cases }
    return cases.filter { $0.category == category }
}

let options = CLIOptions.parse(Array(CommandLine.arguments.dropFirst()))
let suite: IMETestSuite = options.strict ? .golden : .full

var totalFailed = 0

    if options.filterCategory == "comprehensive" {
        print(ComprehensiveTypingRunner.summary())
        let errors = ComprehensiveTypingRunner.run()
        if !errors.isEmpty {
            print("\n[comprehensive] \(errors.count) lỗi:")
            for e in errors.prefix(80) { print("  \(e)") }
            if errors.count > 80 { print("  … và \(errors.count - 80) lỗi nữa") }
            exit(1)
        }
        print("\nBộ comprehensive: tất cả đạt (Telex + VNI + parity).")
        exit(0)
    }

    if options.filterCategory == "vni_comprehensive" {
        print(VNIComprehensiveRunner.summary())
        let errors = VNIComprehensiveRunner.run()
        if !errors.isEmpty {
            print("\n[vni_comprehensive] \(errors.count) lỗi:")
            for e in errors.prefix(80) { print("  \(e)") }
            if errors.count > 80 { print("  … và \(errors.count - 80) lỗi nữa") }
            exit(1)
        }
        print("\nBộ VNI comprehensive: tất cả đạt.")
        exit(0)
    }

    if options.filterCategory == "method_parity" {
        print(MethodParityRunner.summary())
        let errors = MethodParityRunner.run()
        if !errors.isEmpty {
            print("\n[method_parity] \(errors.count) lỗi:")
            for e in errors { print("  \(e)") }
            exit(1)
        }
        print("\nParity Telex/VNI: tất cả đạt.")
        exit(0)
    }

    if options.filterCategory == "select_all_cursor" {
        print(SelectAllWhileComposingRunner.summary())
        let errors = SelectAllWhileComposingRunner.run()
        if !errors.isEmpty {
            print("\n[select_all_cursor] \(errors.count) lỗi:")
            for e in errors { print("  \(e)") }
            exit(1)
        }
        print("\n⌘A khi đang gõ (Cursor chat): tất cả đạt — một lần chọn hết.")
        exit(0)
    }

    if options.filterCategory == "marked_commit" {
        print(MarkedTextCommitRegression.summary())
        let errors = MarkedTextCommitRegression.run()
        if !errors.isEmpty {
            print("\n[marked_commit] \(errors.count) lỗi:")
            for error in errors { print("  \(error)") }
            exit(1)
        }
        print("\nMarked text / commit: tất cả regression đạt.")
        exit(0)
    }

    if options.filterCategory == "real_user" {
        print(RealUserContextRunner.summary())
        let errors = RealUserContextRunner.run()
        if !errors.isEmpty {
            print("\n[real_user] \(errors.count) lỗi:")
            for e in errors.prefix(60) { print("  \(e)") }
            if errors.count > 60 { print("  … và \(errors.count - 60) lỗi nữa") }
            exit(1)
        }
        print("\nTất cả kịch bản real_user đạt.")
        exit(0)
    }

    if let deleteCat = options.filterCategory, deleteCat.hasPrefix("delete_") {
    print(DeleteAndContinueTypingRunner.summary())
    let errors = DeleteAndContinueTypingRunner.runFiltered(category: deleteCat)
    if !errors.isEmpty {
        print("\n[\(deleteCat)] \(errors.count) lỗi:")
        for e in errors { print("  \(e)") }
        exit(1)
    }
    let n = DeleteAndContinueTypingFixtures.all.filter { $0.category == deleteCat }.count
    print("\n\(n) kịch bản `\(deleteCat)` đạt.")
    exit(0)
}

if options.matrixOnly {
    print(TelexTestMatrix.summary())
    let matrixErrors = TelexTestMatrix.validateGoldenMatrixAgainstEngine()
    if !matrixErrors.isEmpty {
        print("\n[matrix golden vs engine] \(matrixErrors.count) lỗi:")
        for e in matrixErrors.prefix(40) { print("  \(e)") }
        totalFailed += matrixErrors.count
    }
    let engineCases = filter(TelexTestMatrix.engineCases, category: options.filterCategory)
    let telexFailures = IMETestRunner.runTelex(engineCases)
    print("Matrix engine: \(engineCases.count - telexFailures.count)/\(engineCases.count) đạt")
    printIMEFailures(telexFailures, method: "Telex matrix")

    let typingCases = filterTyping(TelexTestMatrix.typingCases, category: options.filterCategory)
    let typingFailures = TypingSessionRunner.run(typingCases)
    let steps = typingCases.reduce(0) { $0 + $1.keystrokes.count }
    print("Matrix typing: \(typingCases.count - Set(typingFailures.map(\.testCase.keystrokes)).count)/\(typingCases.count) chuỗi, \(steps) bước")
    printTypingFailures(typingFailures)
    totalFailed += telexFailures.count + typingFailures.count

    if totalFailed > 0 {
        print("\nTổng: \(totalFailed) lỗi.")
        exit(1)
    }
    print("\nMa trận: tất cả test đạt.")
    exit(0)
}

if options.longOnly {
    print(TelexLongPassages.summary())
    let longErrors = TelexLongPassages.validateAgainstEngine()
    if !longErrors.isEmpty {
        for e in longErrors { print("  \(e)") }
        totalFailed += longErrors.count
    }
    let engineCases = filter(TelexLongPassages.engineCases, category: options.filterCategory)
    let telexFailures = IMETestRunner.runTelex(engineCases)
    print("Telex long engine: \(engineCases.count - telexFailures.count)/\(engineCases.count) đạt")
    printIMEFailures(telexFailures, method: "Telex long")

    let typingCases = filterTyping(TelexLongPassages.allTypingCases, category: options.filterCategory)
    let typingFailures = TypingSessionRunner.run(typingCases)
    let steps = typingCases.reduce(0) { $0 + $1.keystrokes.count }
    print("Telex long typing: \(typingCases.count - Set(typingFailures.map(\.testCase.keystrokes)).count)/\(typingCases.count) chuỗi, \(steps) bước")
    printTypingFailures(typingFailures)
    totalFailed += telexFailures.count + typingFailures.count

    if totalFailed > 0 {
        print("\nTổng: \(totalFailed) lỗi.")
        exit(1)
    }
    print("\nĐoạn dài Telex: tất cả test đạt.")
    exit(0)
}

let runEngine = !options.typingOnly
let runTyping = options.typingOnly || !options.strict

if runEngine {
    let telexCases = filter(suite.telexCases, category: options.filterCategory)
    let vniCases = filter(suite.vniCases, category: options.filterCategory)

    var telexFailures: [IMETestFailure] = []
    var vniFailures: [IMETestFailure] = []

    if !options.vniOnly {
        telexFailures = IMETestRunner.runTelex(telexCases)
    }
    if !options.telexOnly {
        vniFailures = IMETestRunner.runVNI(vniCases)
    }

    let mode = options.strict ? "golden" : "full"
    print("Chế độ engine: \(mode)")
    if !options.vniOnly {
        print("Telex: \(telexCases.count - telexFailures.count)/\(telexCases.count) đạt")
        printIMEFailures(telexFailures, method: "Telex")
    }
    if !options.telexOnly {
        print("VNI:   \(vniCases.count - vniFailures.count)/\(vniCases.count) đạt")
        printIMEFailures(vniFailures, method: "VNI")
    }
    totalFailed += telexFailures.count + vniFailures.count
}

if runTyping {
    let corpusErrors = TelexCorpus.validateAgainstEngine()
    if !corpusErrors.isEmpty {
        print("\n[corpus validate] \(corpusErrors.count) cặp sai engine:")
        for e in corpusErrors.prefix(15) { print("  \(e)") }
        totalFailed += corpusErrors.count
    }

    let matrixGoldenErrors = TelexTestMatrix.validateGoldenMatrixAgainstEngine()
    if !matrixGoldenErrors.isEmpty {
        print("\n[matrix golden] \(matrixGoldenErrors.count) lỗi:")
        for e in matrixGoldenErrors.prefix(15) { print("  \(e)") }
        totalFailed += matrixGoldenErrors.count
    }

    let longErrors = TelexLongPassages.validateAgainstEngine()
    if !longErrors.isEmpty {
        print("\n[telex_long] \(longErrors.count) lỗi:")
        for e in longErrors.prefix(10) { print("  \(e)") }
        totalFailed += longErrors.count
    }

    let typingCases = filterTyping(TypingSessionFixtures.all, category: options.filterCategory)
    let typingFailures = TypingSessionRunner.run(typingCases)
    let steps = typingCases.reduce(0) { $0 + $1.keystrokes.count }

    print("Gõ từng phím (mỗi phím 1 bước): \(typingCases.count - Set(typingFailures.map { $0.testCase.keystrokes }).count)/\(typingCases.count) chuỗi, \(steps) bước phím")
    printTypingFailures(typingFailures)

    let safariErrors = TypingSessionRunner.runSafariRegression()
    if !safariErrors.isEmpty {
        print("\n[Safari regression]")
        for e in safariErrors { print("  \(e)") }
        totalFailed += safariErrors.count
    }

    let journeyErrors = UserTypingJourneyRunner.run()
    let deleteContinueErrors = DeleteAndContinueTypingRunner.run()
    if !journeyErrors.isEmpty {
        print("\n[Hành trình gõ + Delete] \(journeyErrors.count) lỗi:")
        for e in journeyErrors.prefix(30) { print("  \(e)") }
        totalFailed += journeyErrors.count
    }
    if !deleteContinueErrors.isEmpty {
        print("\n[Xóa + gõ tiếp] \(deleteContinueErrors.count) lỗi:")
        for e in deleteContinueErrors.prefix(40) { print("  \(e)") }
        totalFailed += deleteContinueErrors.count
    }
    if runTyping, journeyErrors.isEmpty, deleteContinueErrors.isEmpty {
        print(DeleteAndContinueTypingRunner.summary())
        print(RealUserContextRunner.summary())
        print("Hành trình gõ: \(UserTypingJourneyFixtures.all.count) + xóa/gõ tiếp: \(DeleteAndContinueTypingFixtures.all.count) kịch bản đạt")
    }

    totalFailed += typingFailures.count
}

if totalFailed > 0 {
    print("\nTổng: \(totalFailed) lỗi.")
    exit(1)
}
print("\nTất cả test đạt.")
exit(0)

func printIMEFailures(_ failures: [IMETestFailure], method: String) {
    guard !failures.isEmpty else { return }
    print("\n[\(method)] \(failures.count) lỗi:")
    for f in failures.prefix(30) {
        let note = f.testCase.note.isEmpty ? "" : " — \(f.testCase.note)"
        print("  [\(f.testCase.category)] \(f.testCase.input)")
        print("    mong đợi: \(f.testCase.expected)")
        print("    thực tế:  \(f.actual)\(note)")
    }
    if failures.count > 30 { print("  … và \(failures.count - 30) lỗi nữa") }
}

func printTypingFailures(_ failures: [TypingStepFailure]) {
    guard !failures.isEmpty else { return }
    print("\n[typing] \(failures.count) lỗi:")
    for f in failures.prefix(25) {
        print("  [\(f.testCase.category)] bước \(f.step) `\(f.keystrokePrefix)` — \(f.reason)")
        print("    mong đợi: \(f.expectedVisible)")
        print("    thực tế:  \(f.actualVisible)")
    }
    if failures.count > 25 { print("  … và \(failures.count - 25) lỗi nữa") }
}
