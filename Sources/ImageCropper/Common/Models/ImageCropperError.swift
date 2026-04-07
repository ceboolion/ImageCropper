//
//  ImageCropperError.swift
//  ImageCropper
//
//  Created by Roman Cebula on 06/04/2026.
//

import Foundation

public enum ImageCropperError: Error, LocalizedError {
    case invalidImage
    case invalidCropRect
    case croppingFailed
    case cgImageCreationFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Dostarczone zdjęcie jest nieprawidłowe"
        case .invalidCropRect:
            return "Obszar przycinania jest nieprawidłowy"
        case .croppingFailed:
            return "Nie udało się przyciąć zdjęcia"
        case .cgImageCreationFailed:
            return "Nie udało się utworzyć CGImage"
        }
    }
}
