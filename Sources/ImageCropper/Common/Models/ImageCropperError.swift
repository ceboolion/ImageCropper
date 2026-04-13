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
            return "err_invalid_image".localized
        case .invalidCropRect:
            return "err_invalid_crop".localized
        case .croppingFailed:
            return "err_crop_failed".localized
        case .cgImageCreationFailed:
            return "err_cgimage_failed".localized
        }
    }
}
