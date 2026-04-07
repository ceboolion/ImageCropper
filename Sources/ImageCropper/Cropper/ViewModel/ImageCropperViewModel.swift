//
//  ImageCropperViewModel.swift
//  ImageCropper
//
//  Created by Roman Cebula on 06/04/2026.
//

import SwiftUI
import CoreGraphics

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if !DEBUG
@Observable
final class ImageCropperViewModel {
    
    // MARK: - Properties
    
    var cropRect: CGRect = .zero
    var imageSize: CGSize = .zero
    var containerSize: CGSize = .zero
    var isDragging = false
    var activeHandle: CropHandle? = nil
    
    private var initialCropRect: CGRect = .zero
    let image: PlatformImage
    private let cropper = Cropper()
    
    // Constants
    let edgePadding: CGFloat = 12
    let minCropSize: CGFloat = 50
    
    // MARK: - Initialization
    
    init(image: PlatformImage) {
        self.image = image
    }
    
    // MARK: - Image Size Calculation
    
    func calculateImageSize(containerSize: CGSize) {
        let oldContainerSize = self.containerSize
        let isFirstCalculation = oldContainerSize == .zero
        
        // Odejmij padding z rozmiaru kontenera
        let effectiveSize = CGSize(
            width: containerSize.width - (edgePadding * 2),
            height: containerSize.height - (edgePadding * 2)
        )
        
        // Zapamiętaj efektywny rozmiar kontenera (bez paddingu)
        self.containerSize = effectiveSize
        
        let imageAspect = image.size.width / image.size.height
        let containerAspect = effectiveSize.width / effectiveSize.height
        
        let displaySize: CGSize
        if imageAspect > containerAspect {
            // Obraz jest szerszy - dopasuj do szerokości
            displaySize = CGSize(
                width: effectiveSize.width,
                height: effectiveSize.width / imageAspect
            )
        } else {
            // Obraz jest wyższy - dopasuj do wysokości
            displaySize = CGSize(
                width: effectiveSize.height * imageAspect,
                height: effectiveSize.height
            )
        }
        
        let oldImageSize = imageSize
        imageSize = displaySize
        
        // Ustaw początkowy cropRect lub przelicz przy zmianie orientacji
        if isFirstCalculation {
            // Początkowo pokazuj cały obraz (nie kontener!)
            let imageFrame = CGRect(
                x: (effectiveSize.width - displaySize.width) / 2,
                y: (effectiveSize.height - displaySize.height) / 2,
                width: displaySize.width,
                height: displaySize.height
            )
            cropRect = imageFrame
        } else if oldContainerSize != effectiveSize && oldImageSize != .zero {
            // Przelicz cropRect przy zmianie orientacji - względem kontenera
            recalculateCropRect(
                from: oldContainerSize,
                to: effectiveSize
            )
        }
    }
    
    private func recalculateCropRect(from oldSize: CGSize, to newSize: CGSize) {
        let relativeX = cropRect.minX / oldSize.width
        let relativeY = cropRect.minY / oldSize.height
        let relativeWidth = cropRect.width / oldSize.width
        let relativeHeight = cropRect.height / oldSize.height
        
        cropRect = CGRect(
            x: relativeX * newSize.width,
            y: relativeY * newSize.height,
            width: relativeWidth * newSize.width,
            height: relativeHeight * newSize.height
        )
    }
    
    // MARK: - Crop Rect Updates
    
    func startDragging() {
        initialCropRect = cropRect
        isDragging = true
    }
    
    func endDragging() {
        isDragging = false
        activeHandle = nil
    }
    
    func updateCropRect(for handle: CropHandle, translation: CGSize) {
        // Oblicz pozycję obrazu w kontenerze - to są nasze granice
        let imageFrame = CGRect(
            x: (containerSize.width - imageSize.width) / 2,
            y: (containerSize.height - imageSize.height) / 2,
            width: imageSize.width,
            height: imageSize.height
        )
        
        let bounds = imageFrame
        let baseRect = initialCropRect
        var newRect = baseRect
        
        switch handle {
        case .topLeft:
            newRect.origin.x = min(baseRect.maxX - minCropSize, max(bounds.minX, baseRect.minX + translation.width))
            newRect.origin.y = min(baseRect.maxY - minCropSize, max(bounds.minY, baseRect.minY + translation.height))
            newRect.size.width = baseRect.maxX - newRect.origin.x
            newRect.size.height = baseRect.maxY - newRect.origin.y
            
        case .topRight:
            newRect.origin.y = min(baseRect.maxY - minCropSize, max(bounds.minY, baseRect.minY + translation.height))
            newRect.size.width = min(bounds.maxX - baseRect.minX, max(minCropSize, baseRect.width + translation.width))
            newRect.size.height = baseRect.maxY - newRect.origin.y
            
        case .bottomLeft:
            newRect.origin.x = min(baseRect.maxX - minCropSize, max(bounds.minX, baseRect.minX + translation.width))
            newRect.size.width = baseRect.maxX - newRect.origin.x
            newRect.size.height = min(bounds.maxY - baseRect.minY, max(minCropSize, baseRect.height + translation.height))
            
        case .bottomRight:
            newRect.size.width = min(bounds.maxX - baseRect.minX, max(minCropSize, baseRect.width + translation.width))
            newRect.size.height = min(bounds.maxY - baseRect.minY, max(minCropSize, baseRect.height + translation.height))
            
        case .top:
            newRect.origin.y = min(baseRect.maxY - minCropSize, max(bounds.minY, baseRect.minY + translation.height))
            newRect.size.height = baseRect.maxY - newRect.origin.y
            
        case .bottom:
            newRect.size.height = min(bounds.maxY - baseRect.minY, max(minCropSize, baseRect.height + translation.height))
            
        case .left:
            newRect.origin.x = min(baseRect.maxX - minCropSize, max(bounds.minX, baseRect.minX + translation.width))
            newRect.size.width = baseRect.maxX - newRect.origin.x
            
        case .right:
            newRect.size.width = min(bounds.maxX - baseRect.minX, max(minCropSize, baseRect.width + translation.width))
        }
        
        cropRect = newRect
    }
    
    // MARK: - Preset Crop Sizes
    
    func resetToSquare() {
        // Oblicz pozycję obrazu w kontenerze
        let imageFrame = CGRect(
            x: (containerSize.width - imageSize.width) / 2,
            y: (containerSize.height - imageSize.height) / 2,
            width: imageSize.width,
            height: imageSize.height
        )
        
        // Stwórz kwadrat wpisany w obraz
        let size = min(imageSize.width, imageSize.height)
        let x = imageFrame.minX + (imageSize.width - size) / 2
        let y = imageFrame.minY + (imageSize.height - size) / 2
        
        cropRect = CGRect(x: x, y: y, width: size, height: size)
    }
    
    func reset16x9() {
        // Oblicz pozycję obrazu w kontenerze
        let imageFrame = CGRect(
            x: (containerSize.width - imageSize.width) / 2,
            y: (containerSize.height - imageSize.height) / 2,
            width: imageSize.width,
            height: imageSize.height
        )
        
        let aspectRatio: CGFloat = 16.0 / 9.0
        let imageAspectRatio = imageSize.width / imageSize.height
        
        let size: CGSize
        
        if imageAspectRatio > aspectRatio {
            // Obraz jest szerszy - dopasuj wysokość
            let height = imageSize.height
            let width = height * aspectRatio
            size = CGSize(width: width, height: height)
        } else {
            // Obraz jest wyższy - dopasuj szerokość
            let width = imageSize.width
            let height = width / aspectRatio
            size = CGSize(width: width, height: height)
        }
        
        let x = imageFrame.minX + (imageSize.width - size.width) / 2
        let y = imageFrame.minY + (imageSize.height - size.height) / 2
        
        cropRect = CGRect(x: x, y: y, width: size.width, height: size.height)
    }
    
    func resetToFull() {
        // Oblicz pozycję obrazu w kontenerze i ustaw cropRect na cały obraz
        let imageFrame = CGRect(
            x: (containerSize.width - imageSize.width) / 2,
            y: (containerSize.height - imageSize.height) / 2,
            width: imageSize.width,
            height: imageSize.height
        )
        
        cropRect = imageFrame
    }
    
    // MARK: - Crop Execution
    
    func performCrop() throws -> CroppedImageResult {
        // Pobierz rzeczywisty rozmiar obrazu w pikselach
        #if canImport(UIKit)
        let actualImageSize = CGSize(
            width: image.size.width * image.scale,
            height: image.size.height * image.scale
        )
        #elseif canImport(AppKit)
        let actualImageSize = image.size
        #endif
        
        // Oblicz pozycję obrazu w kontenerze
        let imageFrame = CGRect(
            x: (containerSize.width - imageSize.width) / 2,
            y: (containerSize.height - imageSize.height) / 2,
            width: imageSize.width,
            height: imageSize.height
        )
        
        // Znajdź przecięcie cropRect z obrazem
        let intersection = cropRect.intersection(imageFrame)
        
        guard !intersection.isEmpty else {
            throw ImageCropperError.invalidCropRect
        }
        
        // Przelicz współrzędne przecięcia na współrzędne obrazu w pikselach
        let scaleX = actualImageSize.width / imageSize.width
        let scaleY = actualImageSize.height / imageSize.height
        
        let imageCropRect = CGRect(
            x: (intersection.minX - imageFrame.minX) * scaleX,
            y: (intersection.minY - imageFrame.minY) * scaleY,
            width: intersection.width * scaleX,
            height: intersection.height * scaleY
        )
        
        return try cropper.crop(image: image, to: imageCropRect)
    }
}
#endif
