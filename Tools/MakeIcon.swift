import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct IconEntry {
    let filename: String
    let pixels: Int
}

let entries = [
    IconEntry(filename: "icon_16x16.png", pixels: 16),
    IconEntry(filename: "icon_16x16@2x.png", pixels: 32),
    IconEntry(filename: "icon_32x32.png", pixels: 32),
    IconEntry(filename: "icon_32x32@2x.png", pixels: 64),
    IconEntry(filename: "icon_128x128.png", pixels: 128),
    IconEntry(filename: "icon_128x128@2x.png", pixels: 256),
    IconEntry(filename: "icon_256x256.png", pixels: 256),
    IconEntry(filename: "icon_256x256@2x.png", pixels: 512),
    IconEntry(filename: "icon_512x512.png", pixels: 512),
    IconEntry(filename: "icon_512x512@2x.png", pixels: 1024)
]

guard CommandLine.arguments.count == 4 else {
    fputs("Usage: swift Tools/MakeIcon.swift <source.png> <output.iconset> <output.icns>\n", stderr)
    exit(64)
}

let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let iconsetURL = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
let icnsURL = URL(fileURLWithPath: CommandLine.arguments[3])

guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
      let sourceCG = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    fputs("Could not read source image: \(sourceURL.path)\n", stderr)
    exit(66)
}

try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let side = min(sourceCG.width, sourceCG.height)
let cropRect = CGRect(
    x: (sourceCG.width - side) / 2,
    y: (sourceCG.height - side) / 2,
    width: side,
    height: side
)

guard let croppedCG = sourceCG.cropping(to: cropRect) else {
    fputs("Could not crop source image\n", stderr)
    exit(65)
}

for entry in entries {
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let context = CGContext(
        data: nil,
        width: entry.pixels,
        height: entry.pixels,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else {
        fputs("Could not render \(entry.filename)\n", stderr)
        exit(65)
    }

    context.interpolationQuality = .high
    context.draw(croppedCG, in: CGRect(x: 0, y: 0, width: entry.pixels, height: entry.pixels))

    guard let resized = context.makeImage() else {
        fputs("Could not create \(entry.filename)\n", stderr)
        exit(65)
    }

    let destinationURL = iconsetURL.appendingPathComponent(entry.filename)
    guard let destination = CGImageDestinationCreateWithURL(
        destinationURL as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        fputs("Could not open \(destinationURL.path)\n", stderr)
        exit(65)
    }

    CGImageDestinationAddImage(destination, resized, nil)
    guard CGImageDestinationFinalize(destination) else {
        fputs("Could not write \(destinationURL.path)\n", stderr)
        exit(65)
    }

    try stripAncillaryPNGChunks(at: destinationURL)
}

try writeICNS(iconsetURL: iconsetURL, outputURL: icnsURL)

private func stripAncillaryPNGChunks(at url: URL) throws {
    let signature = Data([137, 80, 78, 71, 13, 10, 26, 10])
    let data = try Data(contentsOf: url)
    guard data.starts(with: signature) else { return }

    var output = signature
    var offset = signature.count
    let criticalChunks: Set<String> = ["IHDR", "PLTE", "IDAT", "IEND"]

    while offset + 12 <= data.count {
        let length =
            (Int(data[offset]) << 24) |
            (Int(data[offset + 1]) << 16) |
            (Int(data[offset + 2]) << 8) |
            Int(data[offset + 3])
        let chunkEnd = offset + 12 + length
        guard chunkEnd <= data.count else { break }

        let typeStart = offset + 4
        let typeEnd = typeStart + 4
        let type = String(data: data[typeStart..<typeEnd], encoding: .ascii) ?? ""
        if criticalChunks.contains(type) {
            output.append(contentsOf: data[offset..<chunkEnd])
        }

        offset = chunkEnd
    }

    try output.write(to: url, options: .atomic)
}

private func writeICNS(iconsetURL: URL, outputURL: URL) throws {
    let icnsEntries = [
        ("icp4", "icon_16x16.png"),
        ("icp5", "icon_32x32.png"),
        ("icp6", "icon_32x32@2x.png"),
        ("ic07", "icon_128x128.png"),
        ("ic08", "icon_128x128@2x.png"),
        ("ic09", "icon_256x256@2x.png"),
        ("ic10", "icon_512x512@2x.png")
    ]

    let payloads = try icnsEntries.map { type, filename in
        (type, try Data(contentsOf: iconsetURL.appendingPathComponent(filename)))
    }

    let totalLength = 8 + payloads.reduce(0) { $0 + 8 + $1.1.count }
    var data = Data()
    data.append(contentsOf: "icns".utf8)
    data.appendUInt32BE(UInt32(totalLength))

    for (type, payload) in payloads {
        data.append(contentsOf: type.utf8)
        data.appendUInt32BE(UInt32(payload.count + 8))
        data.append(payload)
    }

    try data.write(to: outputURL, options: .atomic)
}

private extension Data {
    mutating func appendUInt32BE(_ value: UInt32) {
        append(UInt8((value >> 24) & 0xff))
        append(UInt8((value >> 16) & 0xff))
        append(UInt8((value >> 8) & 0xff))
        append(UInt8(value & 0xff))
    }
}
