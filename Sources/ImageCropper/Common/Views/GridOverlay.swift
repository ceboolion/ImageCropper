//
//  GridOverlay.swift
//  ImageCropper
//
//  Created by Roman Cebula on 06/04/2026.
//

import SwiftUI

struct GridOverlay: View {
    let cropRect: CGRect
    
    var body: some View {
        ZStack {
            // Pionowe linie
            ForEach(1..<3) { i in
                let x = cropRect.minX + cropRect.width * CGFloat(i) / 3
                Path { path in
                    path.move(to: CGPoint(x: x, y: cropRect.minY))
                    path.addLine(to: CGPoint(x: x, y: cropRect.maxY))
                }
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
            }
            
            // Poziome linie
            ForEach(1..<3) { i in
                let y = cropRect.minY + cropRect.height * CGFloat(i) / 3
                Path { path in
                    path.move(to: CGPoint(x: cropRect.minX, y: y))
                    path.addLine(to: CGPoint(x: cropRect.maxX, y: y))
                }
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
            }
        }
    }
}
