//
//  ImageCropperTests.swift
//  ImageCropperTests
//
//  Created by Roman Cebula on 06/04/2026.
//

import Testing
import CoreGraphics
@testable import ImageCropper

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

@Suite("Image Cropper Tests")
struct ImageCropperTests {
    
    let cropper = Cropper()
    
    // MARK: - Helper Methods
    
    /// Tworzy testowe zdjęcie o określonym rozmiarze i kolorze
    private func createTestImage(width: CGFloat, height: CGFloat, color: CGColor = CGColor(red: 1, green: 0, blue: 0, alpha: 1)) -> PlatformImage {
        let size = CGSize(width: width, height: height)
        
        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            context.cgContext.setFillColor(color)
            context.cgContext.fill(CGRect(origin: .zero, size: size))
        }
        #elseif canImport(AppKit)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor(cgColor: color)?.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        return image
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
    
    #if canImport(UIKit)
    private func createOrientedTestImage(
        width: CGFloat,
        height: CGFloat,
        orientation: UIImage.Orientation
    ) -> UIImage {
        let baseImage = createTestImage(width: width, height: height)
        guard let cgImage = baseImage.cgImage else {
            return baseImage
        }
        
        return UIImage(cgImage: cgImage, scale: baseImage.scale, orientation: orientation)
    }
    #endif
    
    // MARK: - Basic Cropping Tests
    
    @Test("Podstawowe przycinanie zdjęcia")
    func basicCropping() throws {
        let image = createTestImage(width: 100, height: 100)
        let cropRect = CGRect(x: 10, y: 10, width: 50, height: 50)
        
        let result = try cropper.crop(image: image, to: cropRect)
        
        // Sprawdź czy oryginalne zdjęcie zostało zachowane
        #expect(result.originalImage === image)
        
        // Sprawdź rozmiar przyciętego zdjęcia
        let croppedSize = getImageSize(result.croppedImage)
        #expect(croppedSize.width == 50)
        #expect(croppedSize.height == 50)
        
        // Sprawdź zapisany crop rect
        #expect(result.cropRect == cropRect)
    }
    
    @Test("Przycinanie z różnymi rozmiarami")
    func croppingDifferentSizes() throws {
        let testCases: [(imageSize: CGSize, cropRect: CGRect)] = [
            (CGSize(width: 200, height: 200), CGRect(x: 0, y: 0, width: 100, height: 100)),
            (CGSize(width: 500, height: 300), CGRect(x: 50, y: 50, width: 200, height: 150)),
            (CGSize(width: 1000, height: 800), CGRect(x: 100, y: 100, width: 800, height: 600))
        ]
        
        for testCase in testCases {
            let image = createTestImage(width: testCase.imageSize.width, height: testCase.imageSize.height)
            let result = try cropper.crop(image: image, to: testCase.cropRect)
            
            let croppedSize = getImageSize(result.croppedImage)
            #expect(croppedSize.width == testCase.cropRect.width)
            #expect(croppedSize.height == testCase.cropRect.height)
        }
    }
    
    #if canImport(UIKit)
    @Test("Przycinanie zdjęcia z orientacją EXIF")
    func croppingImageWithOrientation() throws {
        let image = createOrientedTestImage(width: 300, height: 200, orientation: .right)
        let pixelSize = getImageSize(image)
        let rect = CGRect(x: 20, y: 30, width: pixelSize.width * 0.4, height: pixelSize.height * 0.3)
        
        let result = try cropper.crop(image: image, to: rect)
        let croppedSize = getImageSize(result.croppedImage)
        
        #expect(croppedSize.width == rect.width)
        #expect(croppedSize.height == rect.height)
        #expect(result.croppedImage.imageOrientation == .up)
    }
    #endif
    
    // MARK: - Square Cropping Tests
    
    @Test("Przycinanie do kwadratu - kwadratowe zdjęcie")
    func cropToSquareFromSquareImage() throws {
        let image = createTestImage(width: 100, height: 100)
        let originalSize = getImageSize(image)
        let result = try cropper.cropToSquare(image: image)
        
        let croppedSize = getImageSize(result.croppedImage)
        #expect(croppedSize.width == originalSize.width)
        #expect(croppedSize.height == originalSize.height)
        #expect(croppedSize.width == croppedSize.height)
    }
    
    @Test("Przycinanie do kwadratu - szerokie zdjęcie")
    func cropToSquareFromWideImage() throws {
        let image = createTestImage(width: 200, height: 100)
        let originalSize = getImageSize(image)
        let result = try cropper.cropToSquare(image: image)
        
        let croppedSize = getImageSize(result.croppedImage)
        let expectedSide = min(originalSize.width, originalSize.height)
        #expect(croppedSize.width == expectedSide)
        #expect(croppedSize.height == expectedSide)
        
        // Sprawdź czy przycięto ze środka
        let expectedX = (originalSize.width - expectedSide) / 2
        #expect(result.cropRect.origin.x == expectedX)
        #expect(result.cropRect.origin.y == 0)
    }
    
    @Test("Przycinanie do kwadratu - wysokie zdjęcie")
    func cropToSquareFromTallImage() throws {
        let image = createTestImage(width: 100, height: 200)
        let originalSize = getImageSize(image)
        let result = try cropper.cropToSquare(image: image)
        
        let croppedSize = getImageSize(result.croppedImage)
        let expectedSide = min(originalSize.width, originalSize.height)
        #expect(croppedSize.width == expectedSide)
        #expect(croppedSize.height == expectedSide)
        
        // Sprawdź czy przycięto ze środka
        let expectedY = (originalSize.height - expectedSide) / 2
        #expect(result.cropRect.origin.x == 0)
        #expect(result.cropRect.origin.y == expectedY)
    }
    
    // MARK: - Aspect Ratio Tests
    
    @Test("Przycinanie do aspect ratio 16:9")
    func cropToAspectRatio16_9() throws {
        let image = createTestImage(width: 1000, height: 1000)
        let result = try cropper.crop(image: image, toAspectRatio: 16.0/9.0)
        
        let croppedSize = getImageSize(result.croppedImage)
        let aspectRatio = croppedSize.width / croppedSize.height
        
        // Tolerancja dla zaokrągleń floating point
        #expect(abs(aspectRatio - 16.0/9.0) < 0.01)
    }
    
    @Test("Przycinanie do aspect ratio 4:3")
    func cropToAspectRatio4_3() throws {
        let image = createTestImage(width: 800, height: 600)
        let result = try cropper.crop(image: image, toAspectRatio: 4.0/3.0)
        
        let croppedSize = getImageSize(result.croppedImage)
        let aspectRatio = croppedSize.width / croppedSize.height
        
        #expect(abs(aspectRatio - 4.0/3.0) < 0.01)
    }
    
    @Test("Przycinanie do aspect ratio 1:1 (kwadrat)")
    func cropToAspectRatio1_1() throws {
        let image = createTestImage(width: 300, height: 200)
        let result = try cropper.crop(image: image, toAspectRatio: 1.0)
        
        let croppedSize = getImageSize(result.croppedImage)
        #expect(croppedSize.width == croppedSize.height)
    }
    
    // MARK: - Normalized Coordinates Tests
    
    @Test("Przycinanie ze współrzędnymi znormalizowanymi")
    func croppingWithNormalizedCoordinates() throws {
        let image = createTestImage(width: 100, height: 100)
        let originalSize = getImageSize(image)
        let normalizedRect = CGRect(x: 0.1, y: 0.1, width: 0.5, height: 0.5)
        
        let result = try cropper.crop(image: image, toNormalized: normalizedRect)
        
        let croppedSize = getImageSize(result.croppedImage)
        #expect(croppedSize.width == originalSize.width * normalizedRect.width)
        #expect(croppedSize.height == originalSize.height * normalizedRect.height)
        
        #expect(result.cropRect.origin.x == originalSize.width * normalizedRect.origin.x)
        #expect(result.cropRect.origin.y == originalSize.height * normalizedRect.origin.y)
    }
    
    @Test("Przycinanie całego zdjęcia ze współrzędnymi znormalizowanymi")
    func croppingFullImageWithNormalizedCoordinates() throws {
        let image = createTestImage(width: 200, height: 150)
        let normalizedRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        
        let result = try cropper.crop(image: image, toNormalized: normalizedRect)
        
        let originalSize = getImageSize(image)
        let croppedSize = getImageSize(result.croppedImage)
        #expect(croppedSize.width == originalSize.width)
        #expect(croppedSize.height == originalSize.height)
    }
    
    // MARK: - Center Cropping Tests
    
    @Test("Przycinanie ze środka do określonego rozmiaru")
    func cropCenterToSize() throws {
        let image = createTestImage(width: 200, height: 200)
        let originalSize = getImageSize(image)
        let targetSize = CGSize(width: 100, height: 100)
        
        let result = try cropper.cropCenter(image: image, to: targetSize)
        
        let croppedSize = getImageSize(result.croppedImage)
        #expect(croppedSize == targetSize)
        
        // Sprawdź czy przycięto ze środka
        let expectedX = (originalSize.width - targetSize.width) / 2
        let expectedY = (originalSize.height - targetSize.height) / 2
        #expect(result.cropRect.origin.x == expectedX)
        #expect(result.cropRect.origin.y == expectedY)
    }
    
    @Test("Przycinanie ze środka - prostokątne zdjęcie")
    func cropCenterRectangularImage() throws {
        let image = createTestImage(width: 300, height: 200)
        let originalSize = getImageSize(image)
        let targetSize = CGSize(width: 100, height: 80)
        
        let result = try cropper.cropCenter(image: image, to: targetSize)
        
        let croppedSize = getImageSize(result.croppedImage)
        #expect(croppedSize == targetSize)
        
        let expectedX = (originalSize.width - targetSize.width) / 2
        let expectedY = (originalSize.height - targetSize.height) / 2
        #expect(result.cropRect.origin.x == expectedX)
        #expect(result.cropRect.origin.y == expectedY)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Błąd przy nieprawidłowym obszarze przycinania - wykracza poza granice")
    func errorWhenCropRectOutOfBounds() throws {
        let image = createTestImage(width: 100, height: 100)
        let originalSize = getImageSize(image)
        let invalidRect = CGRect(
            x: originalSize.width * 0.6,
            y: originalSize.height * 0.6,
            width: originalSize.width * 0.5,
            height: originalSize.height * 0.5
        )
        
        #expect(throws: ImageCropperError.self) {
            try cropper.crop(image: image, to: invalidRect)
        }
    }
    
    @Test("Błąd przy ujemnych współrzędnych")
    func errorWhenNegativeCoordinates() throws {
        let image = createTestImage(width: 100, height: 100)
        let invalidRect = CGRect(x: -10, y: 10, width: 50, height: 50)
        
        #expect(throws: ImageCropperError.self) {
            try cropper.crop(image: image, to: invalidRect)
        }
    }
    
    @Test("Błąd przy zerowej szerokości lub wysokości")
    func errorWhenZeroWidthOrHeight() throws {
        let image = createTestImage(width: 100, height: 100)
        let invalidRect = CGRect(x: 10, y: 10, width: 0, height: 50)
        
        #expect(throws: ImageCropperError.self) {
            try cropper.crop(image: image, to: invalidRect)
        }
    }
    
    @Test("Błąd przy próbie przycięcia do zbyt dużego rozmiaru ze środka")
    func errorWhenCenterCropSizeTooLarge() throws {
        let image = createTestImage(width: 100, height: 100)
        let originalSize = getImageSize(image)
        let invalidSize = CGSize(width: originalSize.width * 1.5, height: originalSize.height * 1.5)
        
        #expect(throws: ImageCropperError.self) {
            try cropper.cropCenter(image: image, to: invalidSize)
        }
    }
    
    // MARK: - Edge Cases
    
    @Test("Przycinanie do minimalnego rozmiaru 1x1")
    func cropToMinimalSize() throws {
        let image = createTestImage(width: 100, height: 100)
        let rect = CGRect(x: 50, y: 50, width: 1, height: 1)
        
        let result = try cropper.crop(image: image, to: rect)
        
        let croppedSize = getImageSize(result.croppedImage)
        #expect(croppedSize.width == 1)
        #expect(croppedSize.height == 1)
    }
    
    @Test("Przycinanie całego zdjęcia (brak zmiany)")
    func cropEntireImage() throws {
        let image = createTestImage(width: 100, height: 100)
        let originalSize = getImageSize(image)
        let rect = CGRect(x: 0, y: 0, width: originalSize.width, height: originalSize.height)
        
        let result = try cropper.crop(image: image, to: rect)
        
        let croppedSize = getImageSize(result.croppedImage)
        #expect(croppedSize == originalSize)
    }
    
    @Test("Wielokrotne przycinanie tego samego zdjęcia")
    func multipleCropsOfSameImage() throws {
        let image = createTestImage(width: 200, height: 200)
        
        let result1 = try cropper.crop(image: image, to: CGRect(x: 0, y: 0, width: 100, height: 100))
        let result2 = try cropper.crop(image: image, to: CGRect(x: 100, y: 100, width: 100, height: 100))
        
        // Oba wyniki powinny mieć tę samą referencję do oryginalnego zdjęcia
        #expect(result1.originalImage === result2.originalImage)
        
        // Ale różne przycięte zdjęcia
        #expect(result1.croppedImage !== result2.croppedImage)
        
        // Z różnymi crop rect
        #expect(result1.cropRect != result2.cropRect)
    }
    
    // MARK: - Integration Tests
    
    @Test("Pełny workflow - przycinanie i weryfikacja wszystkich właściwości")
    func fullWorkflowTest() throws {
        // Utwórz zdjęcie
        let originalImage = createTestImage(width: 500, height: 400)
        let originalSize = getImageSize(originalImage)
        
        // Przytnij do kwadratu
        let squareResult = try cropper.cropToSquare(image: originalImage)
        #expect(squareResult.originalImage === originalImage)
        
        let squareSize = getImageSize(squareResult.croppedImage)
        #expect(squareSize.width == squareSize.height)
        #expect(squareSize.width == min(originalSize.width, originalSize.height))
        
        // Przytnij przycięte zdjęcie jeszcze raz
        let secondCropResult = try cropper.crop(
            image: squareResult.croppedImage,
            to: CGRect(x: 100, y: 100, width: 200, height: 200)
        )
        
        let finalSize = getImageSize(secondCropResult.croppedImage)
        #expect(finalSize.width == 200)
        #expect(finalSize.height == 200)
        
        // Oryginał z pierwszego przycinania stał się oryginałem drugiego
        #expect(secondCropResult.originalImage === squareResult.croppedImage)
    }
    
    @Test("Test wydajnościowy - wiele przycięć")
    func performanceTest() throws {
        let image = createTestImage(width: 1000, height: 1000)
        
        // Wykonaj 100 przycięć
        for i in 0..<100 {
            let offset = CGFloat(i % 50)
            let rect = CGRect(x: offset, y: offset, width: 500, height: 500)
            _ = try cropper.crop(image: image, to: rect)
        }
        
        // Jeśli dotarliśmy tutaj bez timeoutu, test zakończył się sukcesem
        #expect(true)
    }
}

// MARK: - Additional Test Suite for Error Descriptions

@Suite("Image Cropper Error Tests")
struct ImageCropperErrorTests {
    
    @Test("Sprawdzenie opisów błędów")
    func errorDescriptions() {
        let errors: [ImageCropperError] = [
            .invalidImage,
            .invalidCropRect,
            .croppingFailed,
            .cgImageCreationFailed
        ]
        
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
    
    @Test("Konkretne opisy błędów")
    func specificErrorDescriptions() {
        #expect(ImageCropperError.invalidImage.errorDescription == "err_invalid_image")
        #expect(ImageCropperError.invalidCropRect.errorDescription == "err_invalid_crop")
        #expect(ImageCropperError.croppingFailed.errorDescription == "err_crop_failed")
        #expect(ImageCropperError.cgImageCreationFailed.errorDescription == "err_cgimage_failed")
    }
}
