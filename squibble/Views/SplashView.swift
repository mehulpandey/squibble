//
//  SplashView.swift
//  squibble
//
//  Loading screen shown during auth state check
//

import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            // Dark ambient background
            AmbientBackground()

            VStack(spacing: 20) {
                // App logo
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseAnimation ? 1.03 : 1.0)
                    .shadow(color: AppTheme.primaryGlow, radius: 20, x: 0, y: 8)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Text("Squibble")
                    .font(.custom("Avenir-Black", size: 32))
                    .foregroundColor(AppTheme.textPrimary)
                    .opacity(logoOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(0.5)) {
                pulseAnimation = true
            }
        }
    }
}

#Preview {
    SplashView()
}
