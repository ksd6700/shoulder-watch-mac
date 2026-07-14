import AppKit

enum StatusBarIcon {
    static func make() -> NSImage {
        let size = NSSize(width: 22, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        let color = NSColor.white
        color.setStroke()
        color.setFill()

        let shield = NSBezierPath()
        shield.move(to: NSPoint(x: 11, y: 17))
        shield.curve(
            to: NSPoint(x: 4.2, y: 11.2),
            controlPoint1: NSPoint(x: 9.0, y: 15.0),
            controlPoint2: NSPoint(x: 6.8, y: 12.3)
        )
        shield.line(to: NSPoint(x: 4.2, y: 7.4))
        shield.curve(
            to: NSPoint(x: 11, y: 1.2),
            controlPoint1: NSPoint(x: 4.6, y: 4.6),
            controlPoint2: NSPoint(x: 7.2, y: 2.4)
        )
        shield.curve(
            to: NSPoint(x: 17.8, y: 7.4),
            controlPoint1: NSPoint(x: 14.8, y: 2.4),
            controlPoint2: NSPoint(x: 17.4, y: 4.6)
        )
        shield.line(to: NSPoint(x: 17.8, y: 11.2))
        shield.curve(
            to: NSPoint(x: 11, y: 17),
            controlPoint1: NSPoint(x: 15.2, y: 12.3),
            controlPoint2: NSPoint(x: 13.0, y: 15.0)
        )
        shield.close()
        shield.lineWidth = 1.45
        shield.stroke()

        let eye = NSBezierPath()
        eye.move(to: NSPoint(x: 3.0, y: 8.6))
        eye.curve(
            to: NSPoint(x: 11.0, y: 12.4),
            controlPoint1: NSPoint(x: 5.2, y: 11.0),
            controlPoint2: NSPoint(x: 7.9, y: 12.4)
        )
        eye.curve(
            to: NSPoint(x: 19.0, y: 8.6),
            controlPoint1: NSPoint(x: 14.1, y: 12.4),
            controlPoint2: NSPoint(x: 16.8, y: 11.0)
        )
        eye.curve(
            to: NSPoint(x: 11.0, y: 4.8),
            controlPoint1: NSPoint(x: 16.8, y: 6.2),
            controlPoint2: NSPoint(x: 14.1, y: 4.8)
        )
        eye.curve(
            to: NSPoint(x: 3.0, y: 8.6),
            controlPoint1: NSPoint(x: 7.9, y: 4.8),
            controlPoint2: NSPoint(x: 5.2, y: 6.2)
        )
        eye.close()
        eye.lineWidth = 1.35
        eye.stroke()

        NSBezierPath(ovalIn: NSRect(x: 8.55, y: 6.15, width: 4.9, height: 4.9)).fill()

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
