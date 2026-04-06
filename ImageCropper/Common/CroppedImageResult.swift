//
//  CroppedImageResult.swift
//  ImageCropper
//
//  Created by Roman Cebula on 06/04/2026.
//

import UIKit
import CoreGraphics

/// Wynik operacji przycinania zdjęcia
public struct CroppedImageResult {
    /// Oryginalne zdjęcie
    public let originalImage: PlatformImage
    
    /// Przycięte zdjęcie
    public let croppedImage: PlatformImage
    
    /// Obszar który został użyty do przycięcia (w pikselach oryginalnego zdjęcia)
    public let cropRect: CGRect
    
    public init(originalImage: PlatformImage, croppedImage: PlatformImage, cropRect: CGRect) {
        self.originalImage = originalImage
        self.croppedImage = croppedImage
        self.cropRect = cropRect
    }
}
