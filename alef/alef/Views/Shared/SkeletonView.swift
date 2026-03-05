//
//  SkeletonView.swift
//  alef
//
//  Shimmer loading placeholder — shows a pulsing rectangle
//  while data is loading.
//
//  Usage:
//    SkeletonView(width: 200, height: 20)       // fixed size
//    SkeletonView(height: 80, cornerRadius: 16)  // full-width card
//

import SwiftUI

struct SkeletonView: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var cornerRadius: CGFloat = 8

    @State private var shimmer = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.alefSurfaceSecondary.opacity(0.15))
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.alefSurfaceSecondary.opacity(0.08),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmer ? 300 : -300)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmer = true
                }
            }
    }
}

// MARK: - Skeleton Presets

extension SkeletonView {
    /// A skeleton card that mimics a habit card shape.
    static var habitCard: some View {
        HStack(spacing: 12) {
            SkeletonView(width: 44, height: 44, cornerRadius: 12)
            VStack(alignment: .leading, spacing: 6) {
                SkeletonView(width: 120, height: 14)
                SkeletonView(width: 80, height: 10)
            }
            Spacer()
            SkeletonView(width: 32, height: 32, cornerRadius: 16)
        }
        .padding(14)
        .background(Color.alefSurface)
        .cornerRadius(16)
    }
}
