import Foundation
import ToolVNCore

/// Bao phủ Telex + hành vi người dùng (gõ từng phím, xóa, focus, batch vs session).
public enum ComprehensiveTypingRunner {
    public static func summary() -> String {
        """
        \(TelexTestMatrix.summary())
        \(RealUserContextRunner.summary())
        \(DeleteAndContinueTypingRunner.summary())
        \(ComprehensiveFocusAndEditRunner.summary())
        Backspace: \(BackspaceInteractionFixtures.cases.count) kịch bản
        Hành trình: \(UserTypingJourneyFixtures.all.count) kịch bản
        \(SelectAllWhileComposingRunner.summary())
        \(MarkedTextCommitRegression.summary())
        \(VNIComprehensiveRunner.summary())
        """
    }

    public static func run() -> [String] {
        var errors: [String] = []

        errors.append(contentsOf: TelexTestMatrix.validateGoldenMatrixAgainstEngine())

        let matrixEngine = IMETestRunner.runTelex(TelexTestMatrix.engineCases)
        errors.append(contentsOf: matrixEngine.map {
            "[matrix_engine] \($0.testCase.input) → \($0.testCase.expected) got \($0.actual)"
        })

        errors.append(contentsOf: PerKeystrokeTypingRunner.run(TelexTestMatrix.fullTypingCases).map {
            "[matrix_typing] \($0.reason) `\($0.testCase.keystrokes)`"
        })

        errors.append(contentsOf: RealUserContextRunner.run())
        errors.append(contentsOf: DeleteAndContinueTypingRunner.run())
        errors.append(contentsOf: BackspaceInteractionRunner.run())
        errors.append(contentsOf: UserTypingJourneyRunner.run())
        errors.append(contentsOf: ComprehensiveFocusAndEditRunner.run())
        errors.append(contentsOf: FocusClickTypingRunner.run())
        errors.append(contentsOf: syllableConsistencyErrors())
        errors.append(contentsOf: VNIComprehensiveRunner.run())
        errors.append(contentsOf: SelectAllWhileComposingRunner.run())
        errors.append(contentsOf: MarkedTextCommitRegression.run())

        return errors
    }

    private static func syllableConsistencyErrors() -> [String] {
        var errors: [String] = []
        let inputs =
            TelexTestMatrix.engineCases.map(\.input)
            + RealUserContextFixtures.scenarios.map(\.telex)
            + extraSyllables
        for input in Set(inputs) {
            if input.count > 48 { continue }
            if let err = PerKeystrokeTypingEngine.engineMismatchErrors(telex: input, label: input) {
                errors.append("[consistency] \(err)")
            }
        }
        return errors
    }

    private static let extraSyllables: [String] = [
        "hopwj", "hopw", "how", "show", "guiwr", "guiw", "guwr",
        "dduwowngf", "nguowif", "truowngf", "dduwowcj", "nuowcs",
        "Kieemr", "vieetj", "xoas", "xoa", "trowif", "mootj",
        "camr", "quys", "tieens", "phuwowng", "quyeenf", "uowj", "uowng",
    ]
}
