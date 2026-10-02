import Foundation
import AppKit

let masterSize = 1024
let image = NSImage(size: NSSize(width: masterSize, height: masterSize))

image.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else {
    fatalError("Failed to obtain CGContext")
}

// 1. Dark Rounded Squircle Background with Subtle Glow
let rect = CGRect(x: 64, y: 64, width: 896, height: 896)
let outerPath = NSBezierPath(roundedRect: rect, xRadius: 200, yRadius: 200)

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -20), blur: 50, color: NSColor.black.withAlphaComponent(0.6).cgColor)
NSColor(red: 0.08, green: 0.09, blue: 0.13, alpha: 1.0).setFill()
outerPath.fill()
ctx.restoreGState()

// Inner Gradient Surface
let bgGradient = NSGradient(
    colors: [
        NSColor(red: 0.14, green: 0.16, blue: 0.24, alpha: 1.0),
        NSColor(red: 0.07, green: 0.08, blue: 0.12, alpha: 1.0)
    ]
)
bgGradient?.draw(in: outerPath, angle: -45)

// Outer Squircle Border Ring
let borderPath = NSBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 2), xRadius: 198, yRadius: 198)
NSColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 0.3).setStroke()
borderPath.lineWidth = 4
borderPath.stroke()

// 2. Clipboard Board Body
let boardRect = CGRect(x: 200, y: 150, width: 624, height: 724)
let boardPath = NSBezierPath(roundedRect: boardRect, xRadius: 36, yRadius: 36)

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 30, color: NSColor.black.withAlphaComponent(0.5).cgColor)
let boardGrad = NSGradient(
    colors: [
        NSColor(red: 0.18, green: 0.22, blue: 0.32, alpha: 1.0),
        NSColor(red: 0.12, green: 0.14, blue: 0.22, alpha: 1.0)
    ]
)
boardGrad?.draw(in: boardPath, angle: -60)
ctx.restoreGState()

// 3. Stacked Paper Sheets (Layered Glassmorphism)
let paper2Rect = CGRect(x: 244, y: 194, width: 536, height: 580)
let paper2Path = NSBezierPath(roundedRect: paper2Rect, xRadius: 22, yRadius: 22)
NSColor(red: 0.22, green: 0.28, blue: 0.42, alpha: 0.5).setFill()
paper2Path.fill()

let paper1Rect = CGRect(x: 256, y: 210, width: 512, height: 560)
let paper1Path = NSBezierPath(roundedRect: paper1Rect, xRadius: 20, yRadius: 20)

let paperGrad = NSGradient(
    colors: [
        NSColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 0.98),
        NSColor(red: 0.86, green: 0.90, blue: 0.98, alpha: 0.95)
    ]
)
paperGrad?.draw(in: paper1Path, angle: -75)

// Document Content Preview Lines
let lineColors: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
    (0.0, 0.48, 1.0, 0.8), // Vibrant Blue Accent
    (0.4, 0.45, 0.55, 0.7),
    (0.4, 0.45, 0.55, 0.6),
    (0.2, 0.75, 0.5, 0.8), // Mint Green Accent
    (0.4, 0.45, 0.55, 0.5)
]

let lineYOffsets: [CGFloat] = [580, 520, 460, 400, 340]
let lineWidths: [CGFloat] = [320, 410, 380, 260, 340]

for i in 0..<lineYOffsets.count {
    let lineRect = CGRect(x: 306, y: lineYOffsets[i], width: lineWidths[i], height: 16)
    let linePath = NSBezierPath(roundedRect: lineRect, xRadius: 8, yRadius: 8)
    let c = lineColors[i]
    NSColor(red: c.0, green: c.1, blue: c.2, alpha: c.3).setFill()
    linePath.fill()
}

// 4. Modern Holographic Checkmark / Star Badge
let badgeRect = CGRect(x: 620, y: 250, width: 110, height: 110)
let badgePath = NSBezierPath(ovalIn: badgeRect)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 4), blur: 16, color: NSColor(red: 0.0, green: 0.6, blue: 1.0, alpha: 0.6).cgColor)
let badgeGrad = NSGradient(
    colors: [
        NSColor(red: 0.0, green: 0.75, blue: 1.0, alpha: 1.0),
        NSColor(red: 0.1, green: 0.35, blue: 0.95, alpha: 1.0)
    ]
)
badgeGrad?.draw(in: badgePath, angle: 45)
ctx.restoreGState()

// Checkmark glyph in badge
let checkPath = NSBezierPath()
checkPath.move(to: NSPoint(x: 648, y: 305))
checkPath.line(to: NSPoint(x: 668, y: 285))
checkPath.line(to: NSPoint(x: 702, y: 325))
checkPath.lineWidth = 10
checkPath.lineCapStyle = .round
checkPath.lineJoinStyle = .round
NSColor.white.setStroke()
checkPath.stroke()

// 5. Metallic Top Clip
let clipRect = CGRect(x: 412, y: 780, width: 200, height: 80)
let clipPath = NSBezierPath(roundedRect: clipRect, xRadius: 18, yRadius: 18)

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -4), blur: 14, color: NSColor.black.withAlphaComponent(0.4).cgColor)
let clipGrad = NSGradient(
    colors: [
        NSColor(red: 0.85, green: 0.88, blue: 0.94, alpha: 1.0),
        NSColor(red: 0.65, green: 0.70, blue: 0.78, alpha: 1.0)
    ]
)
clipGrad?.draw(in: clipPath, angle: -90)
ctx.restoreGState()

// Clip Hole
let holeRect = CGRect(x: 487, y: 815, width: 50, height: 26)
let holePath = NSBezierPath(roundedRect: holeRect, xRadius: 13, yRadius: 13)
NSColor(red: 0.12, green: 0.14, blue: 0.20, alpha: 1.0).setFill()
holePath.fill()

image.unlockFocus()

// Save Master 1024x1024 PNG
guard let tiffData = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiffData),
      let pngData = rep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to convert image to PNG")
}

let fm = FileManager.default
let currentDir = URL(fileURLWithPath: fm.currentDirectoryPath)
let resourcesDir = currentDir.appendingPathComponent("Resources")
try? fm.createDirectory(at: resourcesDir, withIntermediateDirectories: true)

let logoURL = resourcesDir.appendingPathComponent("app_logo.png")
try pngData.write(to: logoURL)
print("✅ Saved master logo: \(logoURL.path)")

// Create Iconset
let iconsetDir = resourcesDir.appendingPathComponent("AppIcon.iconset")
try? fm.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

let sizes: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png")
]

for (size, filename) in sizes {
    let destImage = NSImage(size: NSSize(width: size, height: size))
    destImage.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size),
               from: NSRect(x: 0, y: 0, width: masterSize, height: masterSize),
               operation: .copy,
               fraction: 1.0)
    destImage.unlockFocus()
    
    if let dTiff = destImage.tiffRepresentation,
       let dRep = NSBitmapImageRep(data: dTiff),
       let dPng = dRep.representation(using: .png, properties: [:]) {
        let fileURL = iconsetDir.appendingPathComponent(filename)
        try dPng.write(to: fileURL)
    }
}

print("✅ Generated all icon sizes in \(iconsetDir.path)")

// Run iconutil
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
let icnsURL = resourcesDir.appendingPathComponent("AppIcon.icns")
process.arguments = ["-c", "icns", iconsetDir.path, "-o", icnsURL.path]
try process.run()
process.waitUntilExit()

if process.terminationStatus == 0 {
    print("🎉 Successfully generated AppIcon.icns at: \(icnsURL.path)")
    try? fm.removeItem(at: iconsetDir)
} else {
    print("❌ iconutil failed with status: \(process.terminationStatus)")
}
