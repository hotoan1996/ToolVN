import Foundation

/// Mô phỏng các hợp đồng IMK quan trọng mà engine/session thuần không kiểm tra.
public enum MarkedTextCommitRegression {
    private struct MockClient {
        var document: NSString
        var markedRange: NSRange
        var selectedRange: NSRange
        var keepMarkedRangeStaleAfterInsert: Bool
        var insertCallCount = 0
        var emptyMarkedSelectionRanges: [NSRange] = []

        mutating func insertText(_ text: String, replacementRange: NSRange) {
            insertCallCount += 1
            let range: NSRange
            if replacementRange.location != NSNotFound {
                range = replacementRange
            } else if markedRange.location != NSNotFound {
                range = markedRange
            } else if selectedRange.location != NSNotFound {
                range = selectedRange
            } else {
                // IMK vẫn phải nhận insertText(NSNotFound); mock đặt ở cuối.
                range = NSRange(location: document.length, length: 0)
            }
            document = document.replacingCharacters(in: range, with: text) as NSString
            selectedRange = NSRange(
                location: range.location + (text as NSString).length,
                length: 0
            )
            if !keepMarkedRangeStaleAfterInsert {
                markedRange = NSRange(location: NSNotFound, length: NSNotFound)
            }
        }

        mutating func clearMarked(selectionRange: NSRange) {
            emptyMarkedSelectionRanges.append(selectionRange)
            markedRange = NSRange(location: NSNotFound, length: NSNotFound)
        }
    }

    public static func run() -> [String] {
        var errors: [String] = []
        errors.append(contentsOf: staleMarkedCommitErrors())
        errors.append(contentsOf: unavailableRangeErrors())
        errors.append(contentsOf: emptyMarkedSelectionErrors())
        errors.append(contentsOf: fallbackTrackingErrors())
        errors.append(contentsOf: spacePassThroughErrors())
        errors.append(contentsOf: clipboardSelectionPreserveErrors())
        errors.append(contentsOf: zaloEmojiResumeErrors())
        errors.append(contentsOf: unsafeReplaceRangeErrors())
        return errors
    }

    public static func summary() -> String {
        "Marked/commit IMK: 8 nhóm regression (stale, NSNotFound, clear, tracking, space, clipboard, zalo_emoji, safe_range)"
    }

    private static func staleMarkedCommitErrors() -> [String] {
        let prefix = "Hello "
        let word = "việt"
        let prefixLength = (prefix as NSString).length
        var client = MockClient(
            document: (prefix + word) as NSString,
            markedRange: NSRange(
                location: prefixLength,
                length: (word as NSString).length
            ),
            selectedRange: NSRange(
                location: prefixLength + (word as NSString).length,
                length: 0
            ),
            keepMarkedRangeStaleAfterInsert: true
        )

        // Policy đúng: insertText là commit; không chèn lần hai chỉ vì query
        // markedRange ngay sau đó vẫn trả giá trị cũ.
        client.insertText(word, replacementRange: client.markedRange)

        var errors: [String] = []
        if client.document as String != prefix + word {
            errors.append("[stale_marked] commit không được nhân đôi chữ")
        }
        if client.insertCallCount != 1 {
            errors.append("[stale_marked] mỗi commit chỉ được gọi insertText một lần")
        }
        return errors
    }

    private static func unavailableRangeErrors() -> [String] {
        var client = MockClient(
            document: "abc",
            markedRange: NSRange(location: NSNotFound, length: NSNotFound),
            selectedRange: NSRange(location: NSNotFound, length: NSNotFound),
            keepMarkedRangeStaleAfterInsert: false
        )

        // selectedRange/markedRange không khả dụng vẫn phải gửi insertText với
        // replacementRange NSNotFound, không được xóa raw buffer rồi bỏ chữ.
        client.insertText(
            "việt",
            replacementRange: NSRange(location: NSNotFound, length: NSNotFound)
        )
        if client.document as String != "abcviệt" || client.insertCallCount != 1 {
            return ["[range_not_found] commit phải giữ được chữ khi range không khả dụng"]
        }
        return []
    }

    private static func emptyMarkedSelectionErrors() -> [String] {
        var client = MockClient(
            document: "abc",
            markedRange: NSRange(location: 3, length: 2),
            selectedRange: NSRange(location: 5, length: 0),
            keepMarkedRangeStaleAfterInsert: false
        )
        client.clearMarked(selectionRange: NSRange(location: 0, length: 0))
        let valid = client.emptyMarkedSelectionRanges.allSatisfy {
            $0.location == 0 && $0.length == 0
        }
        return valid
            ? []
            : ["[clear_marked] chuỗi marked rỗng chỉ chấp nhận selectionRange (0,0)"]
    }

    private static func fallbackTrackingErrors() -> [String] {
        let markedUnavailable = NSRange(location: NSNotFound, length: NSNotFound)
        let tracked: NSRange? =
            markedUnavailable.location == NSNotFound ? nil : markedUnavailable
        return tracked == nil
            ? []
            : ["[tracking] không được suy diễn preedit document range từ caret"]
    }

    private static func spacePassThroughErrors() -> [String] {
        // Policy: rawBuffer rỗng → handleSpaceBar phải return false (Zalo `:))`→icon).
        let consumeSpaceWhenIdle = false
        return consumeSpaceWhenIdle
            ? ["[space] khi không compose phải pass-through (Zalo emoticon)"]
            : []
    }

    /// Google Docs: khi không compose, `markedRange` có thể trùng selection.
    /// Policy ⌘C/⌘V: không `setMarkedText("")` — nếu không sẽ xóa vùng chọn.
    private static func clipboardSelectionPreserveErrors() -> [String] {
        let text = "xin chào ToolVN"
        let start = 4
        let length = 4 // "chào"
        var client = MockClient(
            document: text as NSString,
            // Docs hay báo markedRange = vùng đang chọn dù IME không compose.
            markedRange: NSRange(location: start, length: length),
            selectedRange: NSRange(location: start, length: length),
            keepMarkedRangeStaleAfterInsert: false
        )

        let rawBufferEmpty = true
        let compositionTracked: NSRange? = nil
        let clearStaleMarkedForCopyPaste = false

        // Policy đúng (⌘C/⌘V): không đụng marked khi rawBuffer rỗng và không track composition.
        let shouldStripMarked =
            !rawBufferEmpty
            || (clearStaleMarkedForCopyPaste && compositionTracked != nil)

        if shouldStripMarked {
            client.clearMarked(selectionRange: NSRange(location: 0, length: 0))
            // Sai: thay marked/selection bằng rỗng.
            client.insertText("", replacementRange: NSRange(location: start, length: length))
        }

        var errors: [String] = []
        if client.document as String != text {
            errors.append("[clipboard] ⌘C/⌘V không được xóa selection khi không compose")
        }
        if client.selectedRange.length != length {
            errors.append("[clipboard] phải giữ nguyên vùng chọn cho ⌘C")
        }
        if shouldStripMarked {
            errors.append("[clipboard] policy copy/paste không được strip marked khi buffer rỗng")
        }
        return errors
    }

    /// Zalo sau chọn icon: markedRange “ma” + setMarkedText không dính.
    /// Policy: không clear marked không thuộc ToolVN; fallback insert khi marked fail.
    private static func zaloEmojiResumeErrors() -> [String] {
        let before = "xin chào "
        let emoji = "😀"
        let doc = before + emoji
        let emojiStart = (before as NSString).length
        let emojiLen = (emoji as NSString).length

        var client = MockClient(
            document: doc as NSString,
            // Client báo marked “ma” trùng emoji vừa chèn.
            markedRange: NSRange(location: emojiStart, length: emojiLen),
            selectedRange: NSRange(location: emojiStart + emojiLen, length: 0),
            keepMarkedRangeStaleAfterInsert: false
        )

        let compositionOwned: NSRange? = nil
        let shouldClearForeignMarked = compositionOwned != nil
        if shouldClearForeignMarked {
            client.insertText("", replacementRange: client.markedRange)
        }

        // setMarkedText không dính → fallback insert tại caret.
        let typed = "a"
        client.insertText(typed, replacementRange: client.selectedRange)

        var errors: [String] = []
        if (client.document as String) != doc + typed {
            errors.append("[zalo_emoji] sau icon phải gõ tiếp được (fallback insert), không xóa emoji")
        }
        if shouldClearForeignMarked {
            errors.append("[zalo_emoji] không được clear markedRange nước ngoài khi chưa compose")
        }
        return errors
    }

    /// Range lệch / quá dài (cả dòng) không được dùng làm replacement — tránh tự xóa dòng trước.
    private static func unsafeReplaceRangeErrors() -> [String] {
        let maxCompositionUTF16 = 20
        let previousLine = "dòng trước bị xóa nhầm\n"
        let caret = (previousLine as NSString).length
        let staleWholeDoc = NSRange(location: 0, length: caret)
        let nearCaret = NSRange(location: caret, length: 0)

        func accept(_ range: NSRange, caretLocation: Int) -> Bool {
            guard range.location != NSNotFound else { return true }
            guard range.length <= maxCompositionUTF16 else { return false }
            let start = range.location
            let end = range.location + max(range.length, 0)
            return caretLocation >= start && caretLocation <= end + 1
        }

        var errors: [String] = []
        if accept(staleWholeDoc, caretLocation: caret) {
            errors.append("[safe_range] không được thay cả dòng trước khi caret ở cuối")
        }
        if !accept(nearCaret, caretLocation: caret) {
            errors.append("[safe_range] caret length 0 tại vị trí gõ phải được chấp nhận")
        }
        let word = NSRange(location: caret - 3, length: 3)
        if caret >= 3, !accept(word, caretLocation: caret) {
            errors.append("[safe_range] preedit ngắn sát caret phải được chấp nhận")
        }
        return errors
    }
}
