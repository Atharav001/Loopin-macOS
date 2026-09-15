import Cocoa
import CoreGraphics

func createIconImage(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }
    
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    
    // 1. macOS Squircle Path (Apple standard corner radius ~ 0.224 * size)
    let cornerRadius = size * 0.224
    let squirclePath = CGPath(roundedRect: rect.insetBy(dx: size * 0.04, dy: size * 0.04),
                               cornerWidth: cornerRadius,
                               cornerHeight: cornerRadius,
                               transform: nil)
    
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()
    
    // Background gradient: Deep midnight slate (#0A0E1A to #161F30)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        CGColor(red: 10/255, green: 14/255, blue: 26/255, alpha: 1.0),
        CGColor(red: 22/255, green: 31/255, blue: 48/255, alpha: 1.0)
    ] as CFArray
    let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(bgGradient,
                           start: CGPoint(x: size * 0.5, y: size),
                           end: CGPoint(x: size * 0.5, y: 0),
                           options: [])
    
    // Subtle radial glow from center-top
    let glowColors = [
        CGColor(red: 2/255, green: 136/255, blue: 235/255, alpha: 0.35),
        CGColor(red: 2/255, green: 136/255, blue: 235/255, alpha: 0.0)
    ] as CFArray
    let radialGlow = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0])!
    ctx.drawRadialGradient(radialGlow,
                           startCenter: CGPoint(x: size * 0.5, y: size * 0.65),
                           startRadius: 0,
                           endCenter: CGPoint(x: size * 0.5, y: size * 0.65),
                           endRadius: size * 0.45,
                           options: [])
    
    ctx.restoreGState()
    
    // Border stroke on squircle
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.setLineWidth(size * 0.018)
    ctx.setStrokeColor(CGColor(red: 56/255, green: 189/255, blue: 248/255, alpha: 0.4))
    ctx.strokePath()
    ctx.restoreGState()
    
    let center = CGPoint(x: size * 0.5, y: size * 0.48)
    let outerRadius = size * 0.30
    let innerRadius = size * 0.22
    
    // 2. Stopwatch Top Crown Button
    let crownWidth = size * 0.08
    let crownHeight = size * 0.04
    let crownRect = CGRect(x: center.x - crownWidth * 0.5,
                           y: center.y + outerRadius + size * 0.025,
                           width: crownWidth,
                           height: crownHeight)
    let crownPath = CGPath(roundedRect: crownRect, cornerWidth: crownHeight * 0.3, cornerHeight: crownHeight * 0.3, transform: nil)
    ctx.saveGState()
    ctx.addPath(crownPath)
    ctx.setFillColor(CGColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 0.9)) // Warm amber accent
    ctx.fillPath()
    ctx.restoreGState()
    
    // 3. Radial Tick Marks (12 ticks around clock face)
    ctx.saveGState()
    ctx.setStrokeColor(CGColor(red: 148/255, green: 163/255, blue: 184/255, alpha: 0.45))
    ctx.setLineWidth(size * 0.012)
    ctx.setLineCap(.round)
    for i in 0..<12 {
        let angle = CGFloat(i) * (.pi * 2.0 / 12.0)
        let r1 = outerRadius + size * 0.018
        let r2 = outerRadius + (i % 3 == 0 ? size * 0.045 : size * 0.030)
        let p1 = CGPoint(x: center.x + cos(angle) * r1, y: center.y + sin(angle) * r1)
        let p2 = CGPoint(x: center.x + cos(angle) * r2, y: center.y + sin(angle) * r2)
        ctx.strokeLineSegments(between: [p1, p2])
    }
    ctx.restoreGState()
    
    // 4. Timer Arc Loop (Clockify Cyan + TickTick Royal Blue + Tocklog Amber)
    let arcLineWidth = size * 0.05
    ctx.saveGState()
    ctx.setLineWidth(arcLineWidth)
    ctx.setLineCap(.round)
    
    // Background muted track
    ctx.addArc(center: center, radius: (outerRadius + innerRadius) * 0.5, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    ctx.setStrokeColor(CGColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.08))
    ctx.strokePath()
    
    // Active progress arc: 300 degrees
    let startA: CGFloat = -.pi * 0.5
    let endA: CGFloat = .pi * 1.15
    ctx.addArc(center: center, radius: (outerRadius + innerRadius) * 0.5, startAngle: startA, endAngle: endA, clockwise: false)
    ctx.setStrokeColor(CGColor(red: 2/255, green: 136/255, blue: 235/255, alpha: 1.0)) // Primary Cyan Blue
    ctx.strokePath()
    
    // Secondary overlapping energetic amber arc
    ctx.addArc(center: center, radius: (outerRadius + innerRadius) * 0.5, startAngle: .pi * 0.8, endAngle: .pi * 1.15, clockwise: false)
    ctx.setStrokeColor(CGColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 1.0)) // Warm Amber Tocklog
    ctx.strokePath()
    ctx.restoreGState()
    
    // 5. Central Modern Timer / Play-Check Emblem
    let centerRadius = size * 0.11
    ctx.saveGState()
    ctx.addArc(center: center, radius: centerRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    let emblemColors = [
        CGColor(red: 2/255, green: 136/255, blue: 235/255, alpha: 1.0),
        CGColor(red: 59/255, green: 104/255, blue: 255/255, alpha: 1.0)
    ] as CFArray
    let emblemGrad = CGGradient(colorsSpace: colorSpace, colors: emblemColors, locations: [0.0, 1.0])!
    ctx.clip()
    ctx.drawLinearGradient(emblemGrad,
                           start: CGPoint(x: center.x - centerRadius, y: center.y - centerRadius),
                           end: CGPoint(x: center.x + centerRadius, y: center.y + centerRadius),
                           options: [])
    ctx.restoreGState()
    
    // Subtle white inner play/check loop icon
    ctx.saveGState()
    ctx.setStrokeColor(CGColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.95))
    ctx.setLineWidth(size * 0.024)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    
    let pCheck1 = CGPoint(x: center.x - size * 0.045, y: center.y)
    let pCheck2 = CGPoint(x: center.x - size * 0.01, y: center.y - size * 0.035)
    let pCheck3 = CGPoint(x: center.x + size * 0.05, y: center.y + size * 0.035)
    ctx.strokeLineSegments(between: [pCheck1, pCheck2, pCheck2, pCheck3])
    ctx.restoreGState()
    
    image.unlockFocus()
    return image
}

func savePNG(image: NSImage, path: String) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        print("Failed to encode PNG for \(path)")
        return
    }
    try? png.write(to: URL(fileURLWithPath: path))
}

let fm = FileManager.default
let assetsDir = "assets"
let iconsetDir = "\(assetsDir)/AppIcon.iconset"

try? fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

// Save 512x512 logo.png
let logo = createIconImage(size: 512)
savePNG(image: logo, path: "\(assetsDir)/logo.png")
print("✓ Generated \(assetsDir)/logo.png")

// Standard Apple iconset dimensions
let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, s) in sizes {
    let img = createIconImage(size: s)
    savePNG(image: img, path: "\(iconsetDir)/\(name)")
}
print("✓ Generated all iconset images in \(iconsetDir)")
