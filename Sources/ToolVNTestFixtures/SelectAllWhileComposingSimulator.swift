import Foundation
import ToolVNCore

/// Client giả lập ô chat Cursor (Electron): committed + marked preedit cuối document.
public enum CursorChatSelectAllSimulator {
    public struct Outcome: Sendable {
        public let documentText: String
        public let markedUTF16Length: Int
        public let selectionUTF16Length: Int
        public let selectionStartsAtZero: Bool
        public let selectAllInvokeCount: Int
        /// IME nuốt ⌘A (return true) — Cursor không nhận Select All.
        public let imeConsumedSelectAllKey: Bool
        public let rawBufferEmpty: Bool

        public var isFullDocumentSelected: Bool {
            let docLen = (documentText as NSString).length
            return docLen > 0
                && selectionStartsAtZero
                && selectionUTF16Length >= docLen
        }

        public var hasNoMarkedText: Bool {
            markedUTF16Length == 0
        }
    }

    /// Hành vi client Electron: lần `selectAll:` đầu ngay sau khi gỡ marked đôi khi **không** chọn hết (cần gọi lại trong cùng một ⌘A).
    public enum ClientBehavior: Sendable {
        case cursorElectron
    }

    /// Một thao tác ⌘A của người dùng — policy ToolVN (flush + completeSelectAll + không nuốt phím).
    public static func simulateOneCommandA(
        prefixCommitted: String,
        composeKeystrokes: String,
        method: VietnameseInputMethod = .telex,
        client: ClientBehavior = .cursorElectron
    ) -> Outcome {
        var committed = prefixCommitted
        var rawBuffer = composeKeystrokes
        var markedUTF16 = preeditUTF16(rawBuffer, method: method)
        var selectAllCalls = 0
        let imeConsumed = false

        func flushPreeditForEditCommand() {
            guard !rawBuffer.isEmpty else {
                markedUTF16 = 0
                return
            }
            let composed = VietnameseConverter.convert(rawBuffer, method: method)
            committed += composed
            rawBuffer = ""
            markedUTF16 = 0
        }

        func invokeSelectAll() {
            selectAllCalls += 1
        }

        func clientHasFullDocumentSelected(selectionLength: Int) -> Bool {
            let docLen = (committed as NSString).length
            return docLen > 0 && selectionLength >= docLen
        }

        func completeSelectAllIfNeeded(hadMarkedBeforeFlush: Bool) {
            invokeSelectAll()
            var selectionLength = selectionLengthAfterCall(
                callIndex: selectAllCalls,
                documentLength: (committed as NSString).length,
                client: client,
                hadMarkedBeforeFlush: hadMarkedBeforeFlush
            )
            if !clientHasFullDocumentSelected(selectionLength: selectionLength) {
                invokeSelectAll()
                selectionLength = selectionLengthAfterCall(
                    callIndex: selectAllCalls,
                    documentLength: (committed as NSString).length,
                    client: client,
                    hadMarkedBeforeFlush: false
                )
            }
            lastSelectionLength = selectionLength
        }

        var lastSelectionLength = 0
        let hadMarkedBeforeFlush = markedUTF16 > 0

        flushPreeditForEditCommand()
        completeSelectAllIfNeeded(hadMarkedBeforeFlush: hadMarkedBeforeFlush)

        return Outcome(
            documentText: committed,
            markedUTF16Length: markedUTF16,
            selectionUTF16Length: lastSelectionLength,
            selectionStartsAtZero: true,
            selectAllInvokeCount: selectAllCalls,
            imeConsumedSelectAllKey: imeConsumed,
            rawBufferEmpty: rawBuffer.isEmpty
        )
    }

    /// Mô hình lỗi cũ: chỉ flush, một lần selectAll, IME nuốt phím — tương đương phải bấm ⌘A lần 2.
    public static func simulateBrokenSingleSelectAllOnly(
        prefixCommitted: String,
        composeKeystrokes: String,
        method: VietnameseInputMethod = .telex
    ) -> Outcome {
        var committed = prefixCommitted
        var rawBuffer = composeKeystrokes

        if !rawBuffer.isEmpty {
            committed += VietnameseConverter.convert(rawBuffer, method: method)
            rawBuffer = ""
        }

        let selectAllCalls = 1
        let selectionLength = brokenSelectionLengthAfterFirstSelectAll(
            documentLength: (committed as NSString).length,
            hadMarkedBeforeFlush: true
        )

        return Outcome(
            documentText: committed,
            markedUTF16Length: 0,
            selectionUTF16Length: selectionLength,
            selectionStartsAtZero: selectionLength > 0,
            selectAllInvokeCount: selectAllCalls,
            imeConsumedSelectAllKey: true,
            rawBufferEmpty: true
        )
    }

    private static func preeditUTF16(_ rawBuffer: String, method: VietnameseInputMethod) -> Int {
        guard !rawBuffer.isEmpty else { return 0 }
        let composed = VietnameseConverter.convert(rawBuffer, method: method)
        return (composed as NSString).length
    }

    private static func selectionLengthAfterCall(
        callIndex: Int,
        documentLength: Int,
        client: ClientBehavior,
        hadMarkedBeforeFlush: Bool
    ) -> Int {
        switch client {
        case .cursorElectron:
            if callIndex == 1, hadMarkedBeforeFlush {
                return 0
            }
            return documentLength
        }
    }

    private static func brokenSelectionLengthAfterFirstSelectAll(documentLength: Int, hadMarkedBeforeFlush: Bool) -> Int {
        if hadMarkedBeforeFlush, documentLength > 0 {
            return min(4, documentLength)
        }
        return documentLength
    }
}

public enum SelectAllWhileComposingRunner {
    public static func summary() -> String {
        let n = SelectAllWhileComposingFixtures.all.count
        return "⌘A khi đang gõ (Cursor chat): \(n) kịch bản — một lần phải chọn hết + flush preedit"
    }

    public static func run() -> [String] {
        var errors: [String] = []

        for scenario in SelectAllWhileComposingFixtures.all {
            let expectedDoc = scenario.expectedDocumentAfterOneSelectAll
            let outcome = CursorChatSelectAllSimulator.simulateOneCommandA(
                prefixCommitted: scenario.prefixCommitted,
                composeKeystrokes: scenario.composeKeystrokes,
                method: scenario.method
            )

            if outcome.documentText != expectedDoc {
                errors.append(
                    "[\(scenario.id)] document «\(outcome.documentText)» ≠ «\(expectedDoc)»"
                )
            }
            if !outcome.rawBufferEmpty {
                errors.append("[\(scenario.id)] rawBuffer phải rỗng sau flush")
            }
            if !outcome.hasNoMarkedText {
                errors.append("[\(scenario.id)] marked text phải đã gỡ")
            }
            if outcome.imeConsumedSelectAllKey {
                errors.append("[\(scenario.id)] IME không được nuốt ⌘A (return true)")
            }
            if !outcome.isFullDocumentSelected {
                errors.append(
                    "[\(scenario.id)] một lần ⌘A phải chọn hết document (selection \(outcome.selectionUTF16Length))"
                )
            }
            if outcome.selectAllInvokeCount < 1 {
                errors.append("[\(scenario.id)] phải gọi selectAll: ít nhất một lần")
            }
            if outcome.selectAllInvokeCount < 2, scenario.category == "select_all_cursor" {
                errors.append(
                    "[\(scenario.id)] Cursor/Electron: policy phải retry selectAll trong cùng một ⌘A (got \(outcome.selectAllInvokeCount) lần)"
                )
            }
        }

        let broken = CursorChatSelectAllSimulator.simulateBrokenSingleSelectAllOnly(
            prefixCommitted: "Hello ",
            composeKeystrokes: "vieetj"
        )
        if broken.isFullDocumentSelected {
            errors.append("[regression] mô hình lỗi cũ (một selectAll) không được coi là đạt")
        }

        return errors
    }
}
