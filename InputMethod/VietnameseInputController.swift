import Cocoa
import InputMethodKit

@objc(VietnameseInputController)
final class VietnameseInputController: IMKInputController {
    #if TOOLVN_VNI
    private static let compiledInputMethod = VietnameseInputMethod.vni
    #else
    private static let compiledInputMethod = VietnameseInputMethod.telex
    #endif

    private var preferencesDomain: String {
        Bundle.main.bundleIdentifier ?? "com.toolvn.inputmethod.telex"
    }

    private var rawBuffer = ""
    /// Vùng UTF-16 preedit chỉ khi client cung cấp markedRange hợp lệ.
    private var compositionUTF16Range: NSRange?

    private var toolVNDefaults: UserDefaults {
        UserDefaults(suiteName: preferencesDomain) ?? .standard
    }

    /// Mỗi bundle được biên dịch cố định cho một kiểu gõ.
    private var inputMethod: VietnameseInputMethod {
        Self.compiledInputMethod
    }

    private func inputMethodFromCurrentIMKMode() -> VietnameseInputMethod? {
        let modeID = currentIMKModeIdentifier().lowercased()
        if modeID.contains("vni") { return .vni }
        if modeID.contains("telex") { return .telex }
        return nil
    }

    private func currentIMKModeIdentifier() -> String {
        let sel = NSSelectorFromString("mode")
        guard (self as NSObject).responds(to: sel) else { return "" }
        return ((self as NSObject).perform(sel)?.takeUnretainedValue() as? String) ?? ""
    }

    override func setValue(_ value: Any?, forKey key: String) {
        if key == "mode", let modeID = value as? String, !modeID.isEmpty {
            syncInputMethodPreferenceFromMode()
            cancelPendingComposition()
        }
        super.setValue(value, forKey: key)
    }

    private func syncInputMethodPreferenceFromMode() {
        guard let method = inputMethodFromCurrentIMKMode() else { return }
        toolVNDefaults.set(method.rawValue, forKey: "ToolVN.inputMethod")
    }

    private var isEnabled: Bool {
        if toolVNDefaults.object(forKey: "ToolVN.enabled") == nil {
            return true
        }
        return toolVNDefaults.bool(forKey: "ToolVN.enabled")
    }

    private static let navigationSelectors: Set<String> = [
        "moveLeft:", "moveRight:", "moveUp:", "moveDown:",
        "moveWordLeft:", "moveWordRight:", "moveWordForward:", "moveWordBackward:",
        "moveToBeginningOfLine:", "moveToEndOfLine:",
        "moveToBeginningOfParagraph:", "moveToEndOfParagraph:",
        "moveToLeftEndOfLine:", "moveToRightEndOfLine:",
        "scrollPageUp:", "scrollPageDown:",
        "moveToBeginningOfDocument:", "moveToEndOfDocument:",
    ]

    /// ⌘A/⌘C/⌘X thường tới qua `doCommand` (không qua `handle`) — phải flush marked ở đây.
    private static let editCommandSelectors: Set<String> = [
        "selectAll:", "copy:", "cut:", "paste:", "undo:", "redo:",
        "deleteBackward:", "deleteForward:",
    ]

    override func recognizedEvents(_ sender: Any!) -> Int {
        let keyDown = Int(NSEvent.EventTypeMask.keyDown.rawValue)
        let mouseDown = Int(
            NSEvent.EventTypeMask.leftMouseDown.rawValue
                | NSEvent.EventTypeMask.rightMouseDown.rawValue
                | NSEvent.EventTypeMask.otherMouseDown.rawValue
        )
        return keyDown | mouseDown
    }

    override func activateServer(_ sender: Any!) {
        syncInputMethodPreferenceFromMode()
        if !rawBuffer.isEmpty {
            commitPendingComposition(client: inputClient(from: sender))
        } else {
            compositionUTF16Range = nil
        }
    }

    override func deactivateServer(_ sender: Any!) {
        commitPendingComposition(client: inputClient(from: sender))
    }

    override func commitComposition(_ sender: Any!) {
        commitPendingComposition(client: inputClient(from: sender))
    }

    override func doCommand(by aSelector: Selector!, command infoDictionary: [AnyHashable: Any]!) {
        let name = NSStringFromSelector(aSelector)
        let suppliedClient =
            infoDictionary?[AnyHashable(kIMKCommandClientName)] as? IMKTextInput
        if isEnabled, let client = suppliedClient ?? client() {
            if Self.navigationSelectors.contains(name) {
                commitPendingComposition(client: client)
            } else if name == "selectAll:" {
                flushOwnPreeditForShortcut(client: client, clearStaleMarked: true)
                super.doCommand(by: aSelector, command: infoDictionary)
                completeSelectAllIfNeeded(client: client)
                return
            } else if Self.editCommandSelectors.contains(name) {
                // ⌘C/⌘V/⌘X: chỉ commit composition của mình; không clear marked
                // khi buffer rỗng (Docs báo markedRange ≈ selection → xóa vùng chọn).
                flushOwnPreeditForShortcut(client: client, clearStaleMarked: false)
            }
        }
        super.doCommand(by: aSelector, command: infoDictionary)
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard isEnabled, let client = inputClient(from: sender) else { return false }

        switch event.type {
        case .leftMouseDown, .rightMouseDown, .otherMouseDown:
            commitPendingComposition(client: client)
            return false

        case .keyDown:
            break

        default:
            return false
        }

        if shouldPassThroughToApplication(event) {
            let selectAll = isSelectAllKeyEvent(event)
            // Chỉ chốt/gỡ preedit của ToolVN. Không đụng marked/selection của Docs
            // khi không đang compose — nếu không ⌘C/⌘V bị hỏng.
            flushOwnPreeditForShortcut(client: client, clearStaleMarked: selectAll)
            if selectAll {
                completeSelectAllIfNeeded(client: client)
            }
            // Luôn false — Safari/Docs cần nhận ⌘A/⌘C/⌘V.
            return false
        }

        if isTabKey(event) {
            prepareForTabPassThrough(client: client)
            return false
        }

        if isSpaceKey(event) {
            return handleSpaceBar(client: client, event: event)
        }

        switch event.keyCode {
        case 51:
            return handleBackspace(client: client, event: event)

        case 117:
            return handleForwardDelete(client: client, event: event)

        case 36, 76:
            commitPendingComposition(client: client)
            return false

        case 48:
            prepareForTabPassThrough(client: client)
            return false

        case 53:
            cancelPendingComposition(client: client)
            return false

        case 123, 124, 125, 126, 115, 119, 116, 121:
            commitPendingComposition(client: client)
            return false

        default:
            guard let chars = event.characters, let first = chars.first else { return false }

            if isWordBreak(first) {
                commitPendingComposition(client: client)
                return false
            }

            guard first.isASCII, first.isLetter || isTelexModifier(first) else {
                commitPendingComposition(client: client)
                return false
            }

            if rawBuffer.isEmpty {
                clearStalePreeditSurface(client: client)
                compositionUTF16Range = nil
            } else {
                freezeCompositionIfCaretLeftPreedit(client: client)
            }
            IMEComposeSession.appendTelexKey(&rawBuffer, first)
            syncPreeditToClient(client: client)
            return true
        }
    }

    private func isSpaceKey(_ event: NSEvent) -> Bool {
        if event.keyCode == 49 { return true }
        guard let chars = event.characters, !chars.isEmpty else { return false }
        return chars.unicodeScalars.allSatisfy { CharacterSet.whitespaces.contains($0) }
    }

    /// Delete/Backspace: telex đang gõ → xóa phím telex; bôi chọn / không compose → Safari xóa (pass-through).
    private func handleBackspace(client: IMKTextInput, event: NSEvent) -> Bool {
        if event.isARepeat { return true }

        if shouldPassDeleteToDocument(client: client) {
            flushPreeditForEditCommand(client: client)
            return false
        }

        if !rawBuffer.isEmpty {
            rawBuffer.removeLast()
            syncPreeditToClient(client: client)
            return true
        }

        compositionUTF16Range = nil
        return false
    }

    private func handleForwardDelete(client: IMKTextInput, event: NSEvent) -> Bool {
        if event.isARepeat { return true }
        if shouldPassDeleteToDocument(client: client) {
            flushPreeditForEditCommand(client: client)
            return false
        }
        if !rawBuffer.isEmpty {
            return handleBackspace(client: client, event: event)
        }
        compositionUTF16Range = nil
        return false
    }

    /// Bôi đen vùng, hoặc không còn telex (kể cả marked sót) → app xóa; IME không nuốt phím.
    private func shouldPassDeleteToDocument(client: IMKTextInput) -> Bool {
        let sel = client.selectedRange()
        if sel.location != NSNotFound, sel.length > 0 {
            return true
        }
        if rawBuffer.isEmpty {
            if client.markedRange().location != NSNotFound {
                return true
            }
            if let range = trackedCompositionRange(), range.length > 0 {
                return true
            }
        }
        return false
    }

    /// Một phím space → chốt từ + một khoảng trắng (một lần chèn, tránh Docs cần bấm space hai lần).
    private func handleSpaceBar(client: IMKTextInput, event: NSEvent) -> Bool {
        if event.isARepeat { return true }

        if !rawBuffer.isEmpty {
            let composed = composedText()
            let preferred = trackedCompositionRange()
            rawBuffer = ""
            compositionUTF16Range = nil
            if !composed.isEmpty {
                let withSpace = composed + " "
                if let end = insertReplacingPreedit(client: client, text: withSpace, preferredRange: preferred) {
                    setClientSelectedRange(client, NSRange(location: end, length: 0))
                }
            }
            return true
        }

        let caret = client.selectedRange()
        if caret.location != NSNotFound {
            _ = client.insertText(" ", replacementRange: caret)
            setClientSelectedRange(client, NSRange(location: caret.location + 1, length: 0))
            return true
        }
        return false
    }

    private func shouldPassThroughToApplication(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags.contains(.command) { return true }
        if flags.contains(.control) { return true }
        if flags.contains(.option) { return true }
        return false
    }

    private func isTabKey(_ event: NSEvent) -> Bool {
        event.keyCode == 48
    }

    /// Electron/Figma có thể đổi renderer/client trong cùng controller.
    /// Luôn ưu tiên client đi kèm callback thay vì client được giữ lúc init.
    private func inputClient(from sender: Any?) -> IMKTextInput? {
        (sender as? IMKTextInput) ?? client()
    }

    private func isSelectAllKeyEvent(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags.contains(.command), !flags.contains(.shift) else { return false }
        if let ch = event.charactersIgnoringModifiers?.lowercased(), ch == "a" { return true }
        return event.keyCode == 0
    }

    /// Zalo/Electron: selectAll sau flush; retry 1 frame nếu marked vừa gỡ. Không nuốt phím (handle vẫn return false).
    private func completeSelectAllIfNeeded(client: IMKTextInput) {
        invokeClientEditCommand(client, "selectAll:")
        guard !clientHasFullDocumentSelected(client) else { return }
        DispatchQueue.main.async { [weak client] in
            guard let client else { return }
            self.invokeClientEditCommand(client, "selectAll:")
        }
    }

    private func clientHasFullDocumentSelected(_ client: IMKTextInput) -> Bool {
        let sel = client.selectedRange()
        guard sel.location != NSNotFound, sel.length > 0 else { return false }
        guard let object = client as? NSObject else { return false }
        let lengthSelector = NSSelectorFromString("length")
        guard object.responds(to: lengthSelector) else { return false }
        let length = (object.perform(lengthSelector)?.takeUnretainedValue() as? NSNumber)?.intValue
        guard let length, length > 0 else { return false }
        return sel.location == 0 && sel.length >= length
    }

    private func invokeClientEditCommand(_ client: IMKTextInput, _ command: String) {
        guard let object = client as? NSObject else { return }
        let selector = NSSelectorFromString(command)
        guard object.responds(to: selector) else { return }
        _ = object.perform(selector)
    }

    /// Tab (Cursor gợi ý, focus form): chỉ chốt telex nếu đang gõ; không nuốt phím.
    private func prepareForTabPassThrough(client: IMKTextInput) {
        if !rawBuffer.isEmpty {
            commitPendingComposition(client: client)
            return
        }
        if client.markedRange().location != NSNotFound {
            ensureMarkedTextFullyCleared(client: client)
            compositionUTF16Range = nil
        }
    }

    /// Chốt preedit (marked → chữ thật) rồi gỡ hẳn marked — ⌘A/⌘C/⌘X một lần (setMarkedText không chặn Select All).
    private func flushPreeditForEditCommand(client: IMKTextInput) {
        flushOwnPreeditForShortcut(client: client, clearStaleMarked: true)
    }

    /// Shortcut hệ thống: chỉ đụng document khi ToolVN đang/đã để composition.
    /// Google Docs thường báo `markedRange` trùng vùng chọn; `setMarkedText("")`
    /// lúc đó sẽ xóa selection và làm ⌘C/⌘V không hoạt động.
    private func flushOwnPreeditForShortcut(client: IMKTextInput, clearStaleMarked: Bool) {
        if !rawBuffer.isEmpty {
            let composed = composedText()
            let preferred = activeCompositionRange(client: client) ?? trackedCompositionRange()
            rawBuffer = ""
            compositionUTF16Range = nil
            if !composed.isEmpty {
                _ = insertReplacingPreedit(client: client, text: composed, preferredRange: preferred)
            }
            // insertText là thao tác commit theo hợp đồng IMK. Không đọc lại
            // markedRange ngay lập tức vì Electron/WebKit có thể trả range cũ.
            return
        }

        if clearStaleMarked, compositionUTF16Range != nil {
            ensureMarkedTextFullyCleared(client: client)
        }
        compositionUTF16Range = nil
    }

    /// Gỡ marked trước Select All — Safari/WebKit thường “ăn” ⌘A lần đầu nếu còn composition.
    private func ensureMarkedTextFullyCleared(client: IMKTextInput) {
        stripRemainingMarkedText(client: client)
        if client.markedRange().location != NSNotFound {
            clearMarkedPreeditIfAny(client: client)
        }
    }

    private func stripRemainingMarkedText(client: IMKTextInput) {
        var marked = client.markedRange()
        guard marked.location != NSNotFound else { return }
        client.setMarkedText(
            NSAttributedString(string: "",
                attributes: [.underlineStyle: 0, .underlineColor: NSColor.clear]),
            selectionRange: NSRange(location: 0, length: 0),
            replacementRange: marked
        )
        marked = client.markedRange()
        guard marked.location != NSNotFound else { return }
        client.setMarkedText(
            NSAttributedString(string: ""),
            selectionRange: NSRange(location: 0, length: 0),
            replacementRange: NSRange(location: NSNotFound, length: NSNotFound)
        )
    }

    private func isTelexModifier(_ char: Character) -> Bool {
        switch inputMethod {
        case .telex:
            return "sfrxjzw".contains(char.lowercased())
        case .vni:
            return char.isNumber
        }
    }

    private func isWordBreak(_ char: Character) -> Bool {
        if char.isWhitespace { return true }
        return ",.;:!?()[]{}\"'\\/".contains(char)
    }

    private func composedText() -> String {
        VietnameseConverter.convert(rawBuffer, method: inputMethod)
    }

    private func utf16Length(_ text: String) -> Int {
        (text as NSString).length
    }

    /// Preedit qua `setMarkedText` — Docs/Safari thường không thay thế đúng khi `insertText` từng phím (KKiKiKiê…).
    private func syncPreeditToClient(client: IMKTextInput) {
        guard !rawBuffer.isEmpty else {
            removeCompositionFromClient(client: client)
            return
        }

        let composed = composedText()
        guard !composed.isEmpty else {
            removeCompositionFromClient(client: client)
            return
        }

        let preeditUTF16 = utf16Length(composed)
        let caretInPreedit = NSRange(location: preeditUTF16, length: 0)
        let replacementRange = markedReplacementRange(client: client)

        client.setMarkedText(
            NSAttributedString(string: composed),
            selectionRange: caretInPreedit,
            replacementRange: replacementRange
        )

        refreshCompositionRangeFromClient(client: client, preeditUTF16Length: preeditUTF16)
    }

    private func markedReplacementRange(client: IMKTextInput) -> NSRange {
        let marked = client.markedRange()
        if marked.location != NSNotFound {
            return marked
        }
        if let tracked = trackedCompositionRange(), tracked.length > 0 {
            return tracked
        }
        let sel = client.selectedRange()
        if sel.location != NSNotFound, sel.length > 0 {
            return sel
        }
        return NSRange(location: NSNotFound, length: NSNotFound)
    }

    private func refreshCompositionRangeFromClient(client: IMKTextInput, preeditUTF16Length: Int) {
        let marked = client.markedRange()
        if marked.location != NSNotFound {
            compositionUTF16Range = NSRange(location: marked.location, length: preeditUTF16Length)
            return
        }
        // Không suy diễn preedit nằm trong document từ caret: một số Electron/
        // WebKit hiển thị marked text nhưng không trả markedRange.
        compositionUTF16Range = nil
    }

    /// Con trỏ ra khỏi preedit đang gõ → chốt chữ tại vùng cũ (gõ tiếp ở vị trí mới).
    private func freezeCompositionIfCaretLeftPreedit(client: IMKTextInput) {
        guard !rawBuffer.isEmpty, let range = compositionUTF16Range, range.length > 0 else { return }
        let caret = client.selectedRange()
        guard caret.location != NSNotFound else { return }
        let end = range.location + range.length
        guard caret.location < range.location || caret.location > end else { return }

        let composed = composedText()
        guard !composed.isEmpty else {
            rawBuffer = ""
            compositionUTF16Range = nil
            return
        }
        commitPreeditSurface(client: client, composed: composed, preferredRange: range)
        rawBuffer = ""
        compositionUTF16Range = nil
    }

    private func commitPendingComposition(client suppliedClient: IMKTextInput? = nil) {
        guard let client = suppliedClient ?? client() else { return }
        guard !rawBuffer.isEmpty else {
            compositionUTF16Range = nil
            return
        }
        let composed = composedText()
        let preferred = trackedCompositionRange()
        rawBuffer = ""
        compositionUTF16Range = nil
        if !composed.isEmpty, let end = insertReplacingPreedit(client: client, text: composed, preferredRange: preferred) {
            setClientSelectedRange(client, NSRange(location: end, length: 0))
        }
    }

    /// Chèn `text` thay preedit (marked / vùng theo dõi). Trả về UTF-16 offset sau chuỗi chèn.
    @discardableResult
    private func insertReplacingPreedit(
        client: IMKTextInput,
        text: String,
        preferredRange: NSRange?
    ) -> Int? {
        let marked = client.markedRange()
        let replaceRange: NSRange
        if marked.location != NSNotFound {
            replaceRange = marked
        } else if let preferredRange, preferredRange.location != NSNotFound, preferredRange.length > 0 {
            replaceRange = preferredRange
        } else {
            let caret = client.selectedRange()
            replaceRange = caret.location == NSNotFound
                ? NSRange(location: NSNotFound, length: NSNotFound)
                : caret
        }

        let insertLocation =
            replaceRange.location == NSNotFound ? nil : replaceRange.location
        _ = client.insertText(text, replacementRange: replaceRange)

        guard let insertLocation else { return nil }
        return insertLocation + utf16Length(text)
    }

    /// Chốt preedit (marked hoặc vùng UTF-16 đã theo dõi) — một lần, không gọi sync trước.
    private func commitPreeditSurface(client: IMKTextInput, composed: String, preferredRange: NSRange?) {
        _ = insertReplacingPreedit(client: client, text: composed, preferredRange: preferredRange)
    }

    private func cancelPendingComposition(client suppliedClient: IMKTextInput? = nil) {
        guard let client = suppliedClient ?? client() else {
            rawBuffer = ""
            compositionUTF16Range = nil
            return
        }
        removeCompositionFromClient(client: client)
    }

    private func activeCompositionRange(client: IMKTextInput) -> NSRange? {
        guard !rawBuffer.isEmpty else { return nil }
        let marked = client.markedRange()
        if marked.location != NSNotFound {
            return marked
        }
        if let compositionUTF16Range, compositionUTF16Range.location != NSNotFound {
            return compositionUTF16Range
        }
        return nil
    }

    private func trackedCompositionRange() -> NSRange? {
        guard let compositionUTF16Range, compositionUTF16Range.location != NSNotFound else { return nil }
        return compositionUTF16Range
    }

    /// Xóa preedit còn trên client khi buffer telex đã rỗng (tránh gõ tiếp → xoâ / ký tự chồng).
    private func clearStalePreeditSurface(client: IMKTextInput) {
        _ = clearPreeditSurface(client: client, caretAfterClear: false)
    }

    @discardableResult
    private func clearPreeditSurface(client: IMKTextInput, caretAfterClear: Bool) -> Bool {
        let marked = client.markedRange()
        if marked.location != NSNotFound {
            let caret = NSRange(location: marked.location, length: 0)
            client.setMarkedText(
                NSAttributedString(string: ""),
                selectionRange: NSRange(location: 0, length: 0),
                replacementRange: marked
            )
            compositionUTF16Range = nil
            if caretAfterClear, caret.location != NSNotFound {
                setClientSelectedRange(client, caret)
            }
            return true
        }
        guard !rawBuffer.isEmpty || trackedCompositionRange() != nil else { return false }
        client.setMarkedText(
            NSAttributedString(string: ""),
            selectionRange: NSRange(location: 0, length: 0),
            replacementRange: NSRange(location: NSNotFound, length: NSNotFound)
        )
        compositionUTF16Range = nil
        return true
    }

    private func removeCompositionFromClient(client: IMKTextInput) {
        if clearPreeditSurface(client: client, caretAfterClear: true) {
            rawBuffer = ""
            return
        }
        clearMarkedPreeditIfAny(client: client)
        rawBuffer = ""
        compositionUTF16Range = nil
    }

    private func clearMarkedPreeditIfAny(client: IMKTextInput) {
        let marked = client.markedRange()
        guard marked.location != NSNotFound else { return }
        client.setMarkedText(
            NSAttributedString(string: ""),
            selectionRange: NSRange(location: 0, length: 0),
            replacementRange: NSRange(location: NSNotFound, length: NSNotFound)
        )
    }

    /// `IMKTextInput` chỉ khai báo `selectedRange()`; client thực tế (NSTextView, …) có `setSelectedRange:`.
    private func setClientSelectedRange(_ client: IMKTextInput, _ range: NSRange) {
        guard let object = client as? NSObject else { return }
        let selector = NSSelectorFromString("setSelectedRange:")
        guard object.responds(to: selector) else { return }
        _ = object.perform(selector, with: NSValue(range: range))
    }
}
