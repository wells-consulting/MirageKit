//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(UIKit)

    import UIKit

    public typealias PlatformImage = UIImage

#elseif canImport(AppKit)

    import AppKit

    public typealias PlatformImage = NSImage

    public extension NSImage {

        convenience init?(systemName: String) {
            self.init(systemSymbolName: systemName, accessibilityDescription: nil)
        }

        func jpegData(compressionQuality: CGFloat) -> Data? {
            guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                return nil
            }
            let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
            return bitmapRep.representation(
                using: NSBitmapImageRep.FileType.jpeg,
                properties: [.compressionFactor: compressionQuality],
            )
        }
    }

#endif
