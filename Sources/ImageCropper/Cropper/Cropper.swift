//
//  ImageCropper.swift
//  ImageCropper
//
//  Created by Roman Cebula on 06/04/2026.
//

import CoreGraphics

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Main Cropper

/// Główna klasa odpowiedzialna za przycinanie zdjęć
public final class Cropper {
    
    public init() {}
    
    /// Przycina zdjęcie do podanego obszaru
    /// - Parameters:
    ///   - image: Zdjęcie do przycięcia
    ///   - rect: Obszar przycinania (w pikselach)
    /// - Returns: Wynik zawierający oryginalne i przycięte zdjęcie
    public func crop(image: PlatformImage, to rect: CGRect) throws -> CroppedImageResult {
        // Walidacja
        guard isValidImage(image) else {
            throw ImageCropperError.invalidImage
        }
        
        let imageSize = getImageSize(image)
        guard isValidCropRect(rect, for: imageSize) else {
            throw ImageCropperError.invalidCropRect
        }
        
        // Przycinanie
        let croppedImage = try performCrop(image: image, rect: rect)
        
        return CroppedImageResult(
            originalImage: image,
            croppedImage: croppedImage,
            cropRect: rect
        )
    }
    
    /// Przycina zdjęcie do podanego obszaru z normalizowanymi współrzędnymi (0.0 - 1.0)
    /// - Parameters:
    ///   - image: Zdjęcie do przycięcia
    ///   - normalizedRect: Obszar przycinania w współrzędnych znormalizowanych
    /// - Returns: Wynik zawierający oryginalne i przycięte zdjęcie
    public func crop(image: PlatformImage, toNormalized normalizedRect: CGRect) throws -> CroppedImageResult {
        let imageSize = getImageSize(image)
        
        let rect = CGRect(
            x: normalizedRect.origin.x * imageSize.width,
            y: normalizedRect.origin.y * imageSize.height,
            width: normalizedRect.size.width * imageSize.width,
            height: normalizedRect.size.height * imageSize.height
        )
        
        return try crop(image: image, to: rect)
    }
    
    /// Przycina zdjęcie do kwadratu (największy możliwy kwadrat ze środka zdjęcia)
    /// - Parameter image: Zdjęcie do przycięcia
    /// - Returns: Wynik zawierający oryginalne i przycięte zdjęcie
    public func cropToSquare(image: PlatformImage) throws -> CroppedImageResult {
        let imageSize = getImageSize(image)
        let sideLength = min(imageSize.width, imageSize.height)
        
        let x = (imageSize.width - sideLength) / 2
        let y = (imageSize.height - sideLength) / 2
        
        let rect = CGRect(x: x, y: y, width: sideLength, height: sideLength)
        return try crop(image: image, to: rect)
    }
    
    /// Przycina zdjęcie do określonego aspect ratio (proporcji)
    /// - Parameters:
    ///   - image: Zdjęcie do przycięcia
    ///   - aspectRatio: Proporcja szerokość/wysokość (np. 16/9 dla widescreen)
    /// - Returns: Wynik zawierający oryginalne i przycięte zdjęcie
    public func crop(image: PlatformImage, toAspectRatio aspectRatio: CGFloat) throws -> CroppedImageResult {
        let imageSize = getImageSize(image)
        let imageAspectRatio = imageSize.width / imageSize.height
        
        let rect: CGRect
        if imageAspectRatio > aspectRatio {
            // Obraz jest szerszy niż docelowa proporcja - przycinamy boki
            let newWidth = imageSize.height * aspectRatio
            let x = (imageSize.width - newWidth) / 2
            rect = CGRect(x: x, y: 0, width: newWidth, height: imageSize.height)
        } else {
            // Obraz jest wyższy niż docelowa proporcja - przycinamy górę i dół
            let newHeight = imageSize.width / aspectRatio
            let y = (imageSize.height - newHeight) / 2
            rect = CGRect(x: 0, y: y, width: imageSize.width, height: newHeight)
        }
        
        return try crop(image: image, to: rect)
    }
    
    // MARK: - Private Methods
    
    private func isValidImage(_ image: PlatformImage) -> Bool {
        #if canImport(UIKit)
        return image.cgImage != nil
        #elseif canImport(AppKit)
        return image.cgImage(forProposedRect: nil, context: nil, hints: nil) != nil
        #endif
    }
    
    private func getImageSize(_ image: PlatformImage) -> CGSize {
        #if canImport(UIKit)
        return CGSize(
            width: image.size.width * image.scale,
            height: image.size.height * image.scale
        )
        #elseif canImport(AppKit)
        return image.size
        #endif
    }
    
    private func isValidCropRect(_ rect: CGRect, for imageSize: CGSize) -> Bool {
        return rect.origin.x >= 0 &&
               rect.origin.y >= 0 &&
               rect.width > 0 &&
               rect.height > 0 &&
               rect.maxX <= imageSize.width &&
               rect.maxY <= imageSize.height
    }
    
    private func performCrop(image: PlatformImage, rect: CGRect) throws -> PlatformImage {
        #if canImport(UIKit)
        return try performCropUIKit(image: image, rect: rect)
        #elseif canImport(AppKit)
        return try performCropAppKit(image: image, rect: rect)
        #endif
    }
    
    #if canImport(UIKit)
    private func performCropUIKit(image: UIImage, rect: CGRect) throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw ImageCropperError.cgImageCreationFailed
        }
        
        // Konwersja na piksele
        let scale = image.scale
        let scaledRect = CGRect(
            x: rect.origin.x,
            y: rect.origin.y,
            width: rect.width,
            height: rect.height
        )
        
        guard let croppedCGImage = cgImage.cropping(to: scaledRect) else {
            throw ImageCropperError.croppingFailed
        }
        
        return UIImage(cgImage: croppedCGImage, scale: scale, orientation: image.imageOrientation)
    }
    #endif
    
    #if canImport(AppKit)
    private func performCropAppKit(image: NSImage, rect: CGRect) throws -> NSImage {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ImageCropperError.cgImageCreationFailed
        }
        
        guard let croppedCGImage = cgImage.cropping(to: rect) else {
            throw ImageCropperError.croppingFailed
        }
        
        let croppedImage = NSImage(cgImage: croppedCGImage, size: rect.size)
        return croppedImage
    }
    #endif
}

// MARK: - Convenience Extensions

public extension Cropper {
    /// Przycina zdjęcie ze środka do określonego rozmiaru
    /// - Parameters:
    ///   - image: Zdjęcie do przycięcia
    ///   - size: Docelowy rozmiar
    /// - Returns: Wynik zawierający oryginalne i przycięte zdjęcie
    func cropCenter(image: PlatformImage, to size: CGSize) throws -> CroppedImageResult {
        let imageSize = getImageSize(image)
        
        guard size.width <= imageSize.width && size.height <= imageSize.height else {
            throw ImageCropperError.invalidCropRect
        }
        
        let x = (imageSize.width - size.width) / 2
        let y = (imageSize.height - size.height) / 2
        
        let rect = CGRect(origin: CGPoint(x: x, y: y), size: size)
        return try crop(image: image, to: rect)
    }
}

