//
//  DimmedOverlay.swift
//  ImageCropper
//
//  Created by Roman Cebula on 06/04/2026.
//

import SwiftUI

struct DimmedOverlay: View {
    let cropRect: CGRect
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.black.opacity(0.6))
                .mask(
                    Rectangle()
                        .overlay(
                            Rectangle()
                                .frame(width: cropRect.width, height: cropRect.height)
                                .position(x: cropRect.midX, y: cropRect.midY)
                                .blendMode(.destinationOut)
                        )
                )
        }
    }
}
