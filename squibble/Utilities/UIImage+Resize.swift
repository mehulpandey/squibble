//
//  UIImage+Resize.swift
//  squibble
//
//  Utility for resizing images before upload to reduce storage egress
//

import UIKit

extension UIImage {
    /// Returns a resized copy where the longest side is at most `maxDimension` points.
    /// Returns self if already smaller. Uses the image's native scale.
    func resizedToMaxDimension(_ maxDimension: CGFloat) -> UIImage? {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }

        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
