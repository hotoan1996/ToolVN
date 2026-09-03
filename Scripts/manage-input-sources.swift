import Carbon
import Foundation

private let bundlePrefix = "com.toolvn.inputmethod."
private let telexBundleID = "com.toolvn.inputmethod.telex"
private let vniBundleID = "com.toolvn.inputmethod.vni"
private let inputSourceIDs = [
    "com.toolvn.inputmethod.telex.v10",
    "com.toolvn.inputmethod.vni.v10",
]
private let checkOnly = CommandLine.arguments.contains("--check")
private let enableRequested = CommandLine.arguments.contains("--enable")

private func property(_ source: TISInputSource, _ key: CFString) -> String? {
    guard let raw = TISGetInputSourceProperty(source, key) else { return nil }
    return Unmanaged<CFTypeRef>.fromOpaque(raw).takeUnretainedValue() as? String
}

private func boolProperty(_ source: TISInputSource, _ key: CFString) -> Bool {
    guard let raw = TISGetInputSourceProperty(source, key) else { return false }
    let value = Unmanaged<CFTypeRef>.fromOpaque(raw).takeUnretainedValue()
    return (value as? Bool) ?? false
}

private func sources(allInstalled: Bool) -> [TISInputSource] {
    TISCreateInputSourceList(nil, allInstalled).takeRetainedValue()
        as? [TISInputSource] ?? []
}

private func isToolVN(_ source: TISInputSource) -> Bool {
    (property(source, kTISPropertyBundleID) ?? "").hasPrefix(bundlePrefix)
}

private func check(_ status: OSStatus, operation: String) throws {
    guard status == noErr else {
        throw NSError(
            domain: NSOSStatusErrorDomain,
            code: Int(status),
            userInfo: [NSLocalizedDescriptionKey: operation]
        )
    }
}

private func disableSource(_ source: TISInputSource, reason: String) throws {
    guard boolProperty(source, kTISPropertyInputSourceIsEnabled) else { return }
    let label = property(source, kTISPropertyInputSourceID) ?? reason
    try check(TISDisableInputSource(source), operation: "Không tắt được \(label)")
}

private func disableAllToolVN() throws {
    for source in sources(allInstalled: true) where isToolVN(source) {
        try disableSource(source, reason: "ToolVN")
    }
}

/// TIS có thể giữ nhiều object cùng mode (build + ~/Library). Chỉ giữ một bản đang bật / mode.
private func disableDuplicateEnabledModes() throws {
    var enabledByMode: [String: [TISInputSource]] = [:]
    for source in sources(allInstalled: true) where isToolVN(source) {
        guard boolProperty(source, kTISPropertyInputSourceIsEnabled),
            let modeID = property(source, kTISPropertyInputModeID)
        else { continue }
        enabledByMode[modeID, default: []].append(source)
    }
    for (_, group) in enabledByMode where group.count > 1 {
        for source in group.dropFirst() {
            try disableSource(source, reason: "trùng mode")
        }
    }
}

private func disableDuplicateEnabledParents() throws {
    var enabledByBundle: [String: [TISInputSource]] = [:]
    for source in sources(allInstalled: true) where isToolVN(source) {
        guard boolProperty(source, kTISPropertyInputSourceIsEnabled),
            property(source, kTISPropertyInputModeID) == nil,
            let bundleID = property(source, kTISPropertyBundleID)
        else { continue }
        enabledByBundle[bundleID, default: []].append(source)
    }
    for (_, group) in enabledByBundle where group.count > 1 {
        for source in group.dropFirst() {
            try disableSource(source, reason: "trùng parent")
        }
    }
}

private func firstSource(modeID: String?) -> TISInputSource? {
    sources(allInstalled: true).first { source in
        guard isToolVN(source) else { return false }
        if let modeID {
            return property(source, kTISPropertyInputModeID) == modeID
        }
        return property(source, kTISPropertyInputModeID) == nil
    }
}

private func enabledSelectableModeIDs() -> [String] {
    sources(allInstalled: true).compactMap { source -> String? in
        guard isToolVN(source),
            boolProperty(source, kTISPropertyInputSourceIsEnabled)
        else { return nil }
        return property(source, kTISPropertyInputModeID)
    }
}

private func verifyExactlyTwoEnabled() throws {
    let enabled = enabledSelectableModeIDs()
    guard Set(enabled) == Set(inputSourceIDs),
        enabled.count == inputSourceIDs.count
    else {
        throw NSError(
            domain: "ToolVN",
            code: 3,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "TIS vẫn có \(enabled.count) ToolVN đang bật: \(enabled). "
                    + "Chạy: make setup-vi hoặc ./Scripts/reload-im.sh"
            ]
        )
    }
}

private func run() throws {
    let inputMethods = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Input Methods", isDirectory: true)
    let telexApp = inputMethods.appendingPathComponent("ToolVN-Telex.app", isDirectory: true)
    let vniApp = inputMethods.appendingPathComponent("ToolVN-VNI.app", isDirectory: true)

    if checkOnly {
        try disableDuplicateEnabledModes()
        try disableDuplicateEnabledParents()
        try verifyExactlyTwoEnabled()
        print("TIS: đúng 2 input method ToolVN đang bật (Telex + VNI), không trùng.")
        return
    }

    let bundles: [(URL, String, String)] = [
        (telexApp, telexBundleID, inputSourceIDs[0]),
        (vniApp, vniBundleID, inputSourceIDs[1]),
    ]

    for (url, _, _) in bundles {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw NSError(
                domain: "ToolVN",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Thiếu bundle: \(url.path)"]
            )
        }
    }

    for (url, _, modeID) in bundles {
        let registered = sources(allInstalled: true).contains {
            property($0, kTISPropertyInputModeID) == modeID
        }
        if !registered {
            try check(
                TISRegisterInputSource(url as CFURL),
                operation: "Không đăng ký được \(url.lastPathComponent)"
            )
        }
    }

    if !enableRequested {
        print("TIS: đã đăng ký bundle khi cần.")
        return
    }

    try disableAllToolVN()

    for (_, bundleID, _) in bundles {
        if let parent = sources(allInstalled: true).first(where: {
            isToolVN($0)
                && property($0, kTISPropertyBundleID) == bundleID
                && property($0, kTISPropertyInputModeID) == nil
        }) {
            try check(
                TISEnableInputSource(parent),
                operation: "Không bật parent \(bundleID)"
            )
        }
    }

    for (_, _, modeID) in bundles {
        guard let mode = firstSource(modeID: modeID) else {
            throw NSError(
                domain: "ToolVN",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey: "Không tìm thấy input method \(modeID)"
                ]
            )
        }
        try check(
            TISEnableInputSource(mode),
            operation: "Không bật được \(modeID)"
        )
    }

    try disableDuplicateEnabledModes()
    try disableDuplicateEnabledParents()
    try verifyExactlyTwoEnabled()
    print("TIS: đúng 2 input method ToolVN đang bật (Telex + VNI), không trùng.")
}

do {
    try run()
} catch {
    let message = (error as NSError).localizedDescription
    fputs("manage-input-sources: \(message)\n", stderr)
    exit(1)
}
