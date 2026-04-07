//
//  ImageCropperView.swift
//  ImageCropper
//
//  Created by Roman Cebula on 06/04/2026.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
#endif

/// Interaktywny widok do przycinania zdjęć z możliwością zmiany rozmiaru obszaru
public struct ImageCropperView: View {
    
    // MARK: - Properties
    
    let onCrop: (CroppedImageResult) -> Void
    let onCancel: () -> Void
    
    @State private var viewModel: ImageCropperViewModel
    
    private let handleVisibleSize: CGFloat = 20
    
    // MARK: - Initialization
    
    public init(
        image: PlatformImage,
        onCrop: @escaping (CroppedImageResult) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.onCrop = onCrop
        self.onCancel = onCancel
        self._viewModel = State(initialValue: ImageCropperViewModel(image: image))
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                toolbar
                // Główny obszar z obrazem
                GeometryReader { geometry in
                    ZStack {
                        // Obraz
                        Image(platformImage: viewModel.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .onAppear {
                                viewModel.calculateImageSize(containerSize: geometry.size)
                            }
                            .onChange(of: geometry.size) { oldValue, newValue in
                                viewModel.calculateImageSize(containerSize: newValue)
                            }
                        
                        // Overlay z obszarem przycinania
                        if viewModel.imageSize != .zero {
                            cropOverlay
                        }
                    }
                    .padding(viewModel.edgePadding)
                }
                
                // Dolny panel z akcjami
                bottomPanel
            }
        }
    }
    
    // MARK: - Subviews
    
    private var toolbar: some View {
        HStack {
            Button("Anuluj") {
                onCancel()
            }
            .foregroundColor(.white)
            
            Spacer()
            
            Text("Przytnij zdjęcie")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Gotowe") {
                do {
                    let result = try viewModel.performCrop()
                    onCrop(result)
                } catch {
                    print("Błąd przycinania: \(error)")
                }
            }
            .foregroundColor(.white)
            .fontWeight(.semibold)
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
    
    private var bottomPanel: some View {
        HStack(spacing: 20) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    viewModel.resetToSquare()
                }
            } label: {
                VStack {
                    Image(systemName: "square")
                        .font(.title2)
                    Text("Kwadrat")
                        .font(.caption)
                }
            }
            .foregroundColor(.white)
            
            Button {
                withAnimation(.spring(response: 0.3)) {
                    viewModel.reset16x9()
                }
            } label: {
                VStack {
                    Image(systemName: "rectangle")
                        .font(.title2)
                    Text("16:9")
                        .font(.caption)
                }
            }
            .foregroundColor(.white)
            
            Button {
                withAnimation(.spring(response: 0.3)) {
                    viewModel.resetToFull()
                }
            } label: {
                VStack {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.title2)
                    Text("Pełny")
                        .font(.caption)
                }
            }
            .foregroundColor(.white)
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
    
    private var cropOverlay: some View {
        GeometryReader { geometry in
            ZStack {
                // Ciemne tło poza obszarem przycinania
                DimmedOverlay(cropRect: viewModel.cropRect)
                
                // Ramka obszaru przycinania
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: viewModel.cropRect.width, height: viewModel.cropRect.height)
                    .position(x: viewModel.cropRect.midX, y: viewModel.cropRect.midY)
                
                // Siatka (rule of thirds)
                GridOverlay(cropRect: viewModel.cropRect)
                
                // Uchwyty do zmiany rozmiaru
                ForEach(CropHandle.allCases, id: \.self) { handle in
                    handleView(for: handle)
                }
            }
        }
    }
    
    private func handleView(for handle: CropHandle) -> some View {
        let position = handle.position(in: viewModel.cropRect)
        
        return Circle()
            .fill(Color.white)
            .frame(width: handleVisibleSize, height: handleVisibleSize)
            .overlay(
                Circle()
                    .stroke(Color.black.opacity(0.5), lineWidth: 2)
            )
            .position(position)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !viewModel.isDragging {
                            viewModel.startDragging()
                            viewModel.activeHandle = handle
                        }
                        viewModel.updateCropRect(for: handle, translation: value.translation)
                    }
                    .onEnded { _ in
                        viewModel.endDragging()
                    }
            )
    }
}

// MARK: - Image Extension

extension Image {
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #elseif canImport(AppKit)
        self.init(nsImage: platformImage)
        #endif
    }
}

// MARK: - Preview

#Preview("Z obrazem testowym") {
    // Spróbuj załadować z Assets, lub użyj wygenerowanego gradientu
    let image = UIImage(named: "image") ?? {
        let size = CGSize(width: 1080, height: 1920)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Gradient czerwono-niebieski
            let colors = [
                CGColor(red: 1, green: 0, blue: 0, alpha: 1),
                CGColor(red: 0, green: 0, blue: 1, alpha: 1)
            ]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(
                colorsSpace: colorSpace,
                colors: colors as CFArray,
                locations: [0, 1]
            )!
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
        }
    }()
    
    ImageCropperView(
        image: image,
        onCrop: { result in
            print("Przycięto: \(result.cropRect)")
        },
        onCancel: {
            print("Anulowano")
        }
    )
}

#Preview("Portrait Gradient") {
    let size = CGSize(width: 1080, height: 1920)
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { context in
        let colors = [
            CGColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1),
            CGColor(red: 0.8, green: 0.2, blue: 0.8, alpha: 1)
        ]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors as CFArray,
            locations: [0, 1]
        )!
        
        context.cgContext.drawLinearGradient(
            gradient,
            start: .zero,
            end: CGPoint(x: 0, y: size.height),
            options: []
        )
    }
    
    ImageCropperView(
        image: image,
        onCrop: { result in
            print("Przycięto: \(result.cropRect)")
        },
        onCancel: {
            print("Anulowano")
        }
    )
}

#Preview("Landscape Gradient") {
    let size = CGSize(width: 1920, height: 1080)
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { context in
        let colors = [
            CGColor(red: 1, green: 0.5, blue: 0, alpha: 1),
            CGColor(red: 0, green: 0.5, blue: 1, alpha: 1)
        ]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors as CFArray,
            locations: [0, 1]
        )!
        
        context.cgContext.drawLinearGradient(
            gradient,
            start: .zero,
            end: CGPoint(x: size.width, y: 0),
            options: []
        )
    }
    
    ImageCropperView(
        image: image,
        onCrop: { result in
            print("Przycięto: \(result.cropRect)")
        },
        onCancel: {
            print("Anulowano")
        }
    )
}

