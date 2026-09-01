import Cocoa
import InputMethodKit

private let connectionName = "com.toolvn.inputmethod.telex_Connection"
private let bundleIdentifier = "com.toolvn.inputmethod.telex"

autoreleasepool {
    guard IMKServer(name: connectionName, bundleIdentifier: bundleIdentifier) != nil else {
        fputs("ToolVN: không khởi tạo được IMKServer\n", stderr)
        exit(1)
    }
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    app.run()
}
