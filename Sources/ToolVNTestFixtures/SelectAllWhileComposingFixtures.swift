import Foundation
import ToolVNCore

/// Kịch bản ⌘A khi đang gõ dở (Cursor IDE chat / Electron) — phải **một lần** chọn hết, không cần bấm lại.
public enum SelectAllWhileComposingFixtures {
    public struct Scenario: Sendable {
        public let category: String
        public let id: String
        /// Nội dung đã chốt trong ô chat (trước từ đang gõ).
        public let prefixCommitted: String
        /// Chuỗi telex/VNI đang gõ (preedit).
        public let composeKeystrokes: String
        public let method: VietnameseInputMethod
        public let note: String

        public init(
            category: String,
            id: String,
            prefixCommitted: String = "",
            composeKeystrokes: String,
            method: VietnameseInputMethod = .telex,
            note: String = ""
        ) {
            self.category = category
            self.id = id
            self.prefixCommitted = prefixCommitted
            self.composeKeystrokes = composeKeystrokes
            self.method = method
            self.note = note
        }

        public var expectedDocumentAfterOneSelectAll: String {
            prefixCommitted + VietnameseConverter.convert(composeKeystrokes, method: method)
        }
    }

    public static let all: [Scenario] = [
        Scenario(
            category: "select_all_cursor",
            id: "cursor_compose_only",
            composeKeystrokes: "vieetj",
            note: "Chỉ preedit trong ô chat"
        ),
        Scenario(
            category: "select_all_cursor",
            id: "cursor_prefix_compose",
            prefixCommitted: "Hello ",
            composeKeystrokes: "vieetj",
            note: "Prefix tiếng Anh + telex"
        ),
        Scenario(
            category: "select_all_cursor",
            id: "cursor_viet_prefix",
            prefixCommitted: "xin chào ",
            composeKeystrokes: "banj",
            note: "Đã có tiếng Việt + đang gõ bạn"
        ),
        Scenario(
            category: "select_all_cursor",
            id: "cursor_kieemr_tra",
            prefixCommitted: "",
            composeKeystrokes: "Kieemr tra",
            note: "Gõ dở Kiểm tra (Docs/Cursor hay gặp)"
        ),
        Scenario(
            category: "select_all_cursor",
            id: "cursor_mid_sentence",
            prefixCommitted: "Tooi laf ",
            composeKeystrokes: "nguowif",
            note: "Tiếp từ sau khoảng trắng"
        ),
        Scenario(
            category: "select_all_cursor",
            id: "cursor_long_prefix",
            prefixCommitted: "Explain this code:\n\n",
            composeKeystrokes: "dduwowcj",
            note: "Prompt dài + đang gõ được"
        ),
        Scenario(
            category: "select_all_vni",
            id: "cursor_vni_compose",
            prefixCommitted: "",
            composeKeystrokes: "tie6n1",
            method: .vni,
            note: "VNI trong chat"
        ),
        Scenario(
            category: "select_all_cursor",
            id: "cursor_telex_tone_mid",
            prefixCommitted: "trowif ",
            composeKeystrokes: "ddepj",
            note: "Sau từ đã có dấu"
        ),
    ]
}
