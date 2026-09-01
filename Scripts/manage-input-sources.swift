import Carbon
import Foundation

private let bundlePrefix = "com.toolvn.inputmethod."
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

if !checkOnly {
    let inputMethods = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Input Methods", isDirectory: true)
    let bundles = [
        (
            inputMethods.appendingPathComponent(
                "ToolVN-Telex.app", isDirectory: true
            ),
            inputSourceIDs[0]
        ),
        (
            inputMethods.appendingPathComponent(
                "ToolVN-VNI.app", isDirectory: true
            ),
            inputSourceIDs[1]
        ),
    ]

    for (url, inputSourceID) in bundles {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw NSError(
                domain: "ToolVN",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Thiếu bundle: \(url.path)"]
            )
        }
        let alreadyRegistered = sources(allInstalled: true).contains {
            property($0, kTISPropertyInputSourceID) == inputSourceID
        }
        if !alreadyRegistered {
            try check(
                TISRegisterInputSource(url as CFURL),
                operation: "Không đăng ký được \(url.lastPathComponent)"
            )
        }
    }
    if !enableRequested {
        print("TIS: đã đăng ký bundle khi cần.")
        exit(0)
    }

    var enabledParents = Set<String>()
    for source in sources(allInstalled: true)
    where isToolVN(source) && property(source, kTISPropertyInputModeID) == nil {
        let id = property(source, kTISPropertyInputSourceID) ?? ""
        if enabledParents.insert(id).inserted {
            try check(TISEnableInputSource(source), operation: "Không bật được \(id)")
        }
    }

    for inputSourceID in inputSourceIDs {
        guard let source = sources(allInstalled: true).first(where: {
            property($0, kTISPropertyInputSourceID) == inputSourceID
        }) else {
            throw NSError(
                domain: "ToolVN",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Không tìm thấy input method \(inputSourceID)"
                ]
            )
        }
        try check(
            TISEnableInputSource(source),
            operation: "Không bật được \(inputSourceID)"
        )
    }
}

let enabledInputSources = sources(allInstalled: true).compactMap {
    source -> String? in
    guard isToolVN(source),
        boolProperty(source, kTISPropertyInputSourceIsEnabled)
    else {
        return nil
    }
    // Parent input method phải được enable để mode hoạt động, nhưng không phải
    // mục có thể chọn trên menu. Chỉ đếm các mode hiển thị.
    return property(source, kTISPropertyInputModeID)
}

guard Set(enabledInputSources) == Set(inputSourceIDs),
    enabledInputSources.count == inputSourceIDs.count
else {
    throw NSError(
        domain: "ToolVN",
        code: 3,
        userInfo: [
            NSLocalizedDescriptionKey:
                "TIS vẫn có \(enabledInputSources.count) ToolVN đang bật: \(enabledInputSources)"
        ]
    )
}

print("TIS: đúng 2 input method ToolVN đang bật (Telex + VNI), không trùng.")
