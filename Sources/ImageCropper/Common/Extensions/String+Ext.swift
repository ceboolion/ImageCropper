//
//  String+Ext.swift
//  ImageCropper
//
//  Created by Roman Cebula on 13/04/2026.
//

import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, bundle: .module, comment: "")
    }
}
