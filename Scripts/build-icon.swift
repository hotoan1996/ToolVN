import AppKit
import Foundation

/// Icon menu Input: cả Telex và VNI cùng hiển thị nhãn VI.
struct IconSpec {
    let baseName: String
    let label: String
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
}

func renderIcon(pixelSize: Int, spec: IconSpec) -> NSBitmapImageRep {
    let size = pixelSize
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let s = CGFloat(size)
    let inset = s * 0.08
    let bg = NSBezierPath(
        roundedRect: NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2),
        xRadius: s * 0.2,
        yRadius: s * 0.2
    )
    NSColor(calibratedRed: spec.red, green: spec.green, blue: spec.blue, alpha: 1).setFill()
    bg.fill()

    let labelLen = CGFloat(spec.label.count)
    let fontSize = s * (labelLen > 2 ? 0.26 : 0.32)
    let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
    ]
    let text = NSAttributedString(string: spec.label, attributes: attrs)
    let textSize = text.size()
    let origin = NSPoint(
        x: (s - textSize.width) / 2,
        y: (s - textSize.height) / 2 - s * 0.02
    )
    text.draw(at: origin)

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func writePNG(_ rep: NSBitmapImageRep, to url: URL) throws {
    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "ToolVN", code: 1, userInfo: [NSLocalizedDescriptionKey: "PNG encode failed"])
    }
    try data.write(to: url)
}

let entries: [(String, Int, String, String)] = [
    ("icon_16x16.png", 16, "1x", "16x16"),
    ("icon_16x16@2x.png", 32, "2x", "16x16"),
    ("icon_32x32.png", 32, "1x", "32x32"),
    ("icon_32x32@2x.png", 64, "2x", "32x32"),
    ("icon_128x128.png", 128, "1x", "128x128"),
    ("icon_128x128@2x.png", 256, "2x", "128x128"),
    ("icon_256x256.png", 256, "1x", "256x256"),
    ("icon_256x256@2x.png", 512, "2x", "256x256"),
    ("icon_512x512.png", 512, "1x", "512x512"),
    ("icon_512x512@2x.png", 1024, "2x", "512x512"),
]

func writeContentsJSON(at iconset: URL) throws {
    let images = entries.map { filename, _, scale, size in
        """
            { "filename" : "\(filename)", "idiom" : "mac", "scale" : "\(scale)", "size" : "\(size)" }
        """
    }.joined(separator: ",\n")
    let json = """
    {
      "images" : [
    \(images)
      ],
      "info" : { "author" : "xcode", "version" : 1 }
    }
    """
    try json.data(using: .utf8)!.write(to: iconset.appendingPathComponent("Contents.json"))
}

let root = CommandLine.arguments.count > 1
    ? URL(fileURLWithPath: CommandLine.arguments[1])
    : URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

let specs: [IconSpec] = [
    IconSpec(baseName: "ToolVN-Telex", label: "VI", red: 0.78, green: 0.12, blue: 0.16),
    IconSpec(baseName: "ToolVN-VNI", label: "VI", red: 0.78, green: 0.12, blue: 0.16),
]

let resources = root.appendingPathComponent("InputMethod/Resources", isDirectory: true)
try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)

for spec in specs {
    let iconset = resources.appendingPathComponent("\(spec.baseName).iconset", isDirectory: true)
    try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
    try writeContentsJSON(at: iconset)
    for (name, px, _, _) in entries {
        let rep = renderIcon(pixelSize: px, spec: spec)
        try writePNG(rep, to: iconset.appendingPathComponent(name))
    }
    print("Wrote iconset → \(iconset.path)")
}
