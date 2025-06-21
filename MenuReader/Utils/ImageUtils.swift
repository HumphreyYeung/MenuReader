//
//  ImageUtils.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/10/25.
//

import UIKit

class ImageUtils {
    
    /// Generate thumbnail data from UIImage
    /// - Parameters:
    ///   - image: Original UIImage
    ///   - maxSize: Maximum size for thumbnail (default: 200x200)
    ///   - compressionQuality: JPEG compression quality (default: 0.7)
    /// - Returns: Compressed image data for storage
    static func generateThumbnailData(from image: UIImage, maxSize: CGSize = CGSize(width: 200, height: 200), compressionQuality: CGFloat = 0.7) -> Data? {
        // Calculate the new size maintaining aspect ratio
        let newSize = calculateThumbnailSize(originalSize: image.size, maxSize: maxSize)
        
        // Create the thumbnail
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        guard let thumbnail = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        
        // Convert to JPEG data
        return thumbnail.jpegData(compressionQuality: compressionQuality)
    }
    
    /// Calculate thumbnail size maintaining aspect ratio
    private static func calculateThumbnailSize(originalSize: CGSize, maxSize: CGSize) -> CGSize {
        let widthRatio = maxSize.width / originalSize.width
        let heightRatio = maxSize.height / originalSize.height
        let ratio = min(widthRatio, heightRatio)
        
        return CGSize(width: originalSize.width * ratio, height: originalSize.height * ratio)
    }
    
    /// Create UIImage from thumbnail data
    static func imageFromThumbnailData(_ data: Data) -> UIImage? {
        return UIImage(data: data)
    }
} 