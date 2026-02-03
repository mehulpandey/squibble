//
//  CachedAsyncImage.swift
//  squibble
//
//  Drop-in replacement for AsyncImage that uses ImageCache (memory + disk)
//

import SwiftUI

struct CachedAsyncImage: View {
    let urlString: String
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var failed = false

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else if failed {
                Rectangle()
                    .fill(AppTheme.canvasTop)
                    .overlay(
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(AppTheme.textTertiary)
                    )
            } else {
                Rectangle()
                    .fill(AppTheme.canvasTop)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.textTertiary))
                    )
            }
        }
        .task(id: urlString) {
            await loadImage()
        }
    }

    private func loadImage() async {
        isLoading = true
        failed = false
        if let loaded = await ImageCache.shared.image(for: urlString) {
            image = loaded
        } else {
            failed = true
        }
        isLoading = false
    }
}
