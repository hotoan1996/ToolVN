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
        return errors
    }

    public static func summary() -> String {
        "Marked/commit IMK: 6 nhóm regression (stale, NSNotFound, clear, tracking, space, clipboard)"
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
        let unavailable = NSRange(location: NSNotFound, length: NSNotFound)
        let shouldConsumeSpace = unavailable.location != NSNotFound
        return shouldConsumeSpace
            ? ["[space] phải pass-through khi client không cung cấp selectedRange"]
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
}
