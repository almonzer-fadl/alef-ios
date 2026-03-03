//
//  ConfettiView.swift
//  alef
//
//  A burst of confetti particles that fires once and fades out.
//
//  Used when the user completes all habits for the day, finishes
//  a focus timer, or hits any celebratory milestone.
//
//  Uses SwiftUI Canvas + TimelineView for smooth 60fps rendering
//  without UIKit dependencies. Each particle has random position,
//  velocity, rotation, colour, and shape.
//

import SwiftUI

struct ConfettiView: View {
    @Binding var isActive: Bool
    let particleCount: Int

    init(isActive: Binding<Bool>, particleCount: Int = 80) {
        self._isActive = isActive
        self.particleCount = particleCount
    }

    @State private var particles: [ConfettiParticle] = []
    @State private var startTime: Date?

    private let duration: TimeInterval = 2.5
    private let colors: [Color] = [
        .alefHabits, .alefJournal, .alefHealth, .alefSleep,
        .alefDiet, .alefFitness, .alefMovies, .alefBooks,
        .alefSuccess, .alefCalendar
    ]

    var body: some View {
        GeometryReader { geo in
            if isActive {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let elapsed = timeline.date.timeIntervalSince(startTime ?? timeline.date)
                        let progress = min(elapsed / duration, 1.0)

                        for particle in particles {
                            let x = particle.startX + particle.velocityX * elapsed
                            let y = particle.startY + particle.velocityY * elapsed + 300 * elapsed * elapsed // gravity
                            let opacity = max(1.0 - progress * 1.2, 0)
                            let rotation = Angle.degrees(particle.rotation + particle.spin * elapsed)
                            let scale = max(1.0 - progress * 0.5, 0.3)

                            guard opacity > 0 else { continue }

                            var transform = CGAffineTransform.identity
                            transform = transform.translatedBy(x: x, y: y)
                            transform = transform.rotated(by: rotation.radians)
                            transform = transform.scaledBy(x: scale, y: scale)

                            context.opacity = opacity

                            let rect = CGRect(x: -particle.width / 2, y: -particle.height / 2,
                                              width: particle.width, height: particle.height)
                            let path = Path(roundedRect: rect, cornerRadius: particle.isCircle ? particle.width / 2 : 2)

                            context.fill(
                                path.applying(transform),
                                with: .color(particle.color)
                            )
                        }
                    }
                }
                .onAppear {
                    startTime = Date()
                    particles = (0..<particleCount).map { _ in
                        ConfettiParticle(
                            startX: geo.size.width / 2 + CGFloat.random(in: -40...40),
                            startY: -20,
                            velocityX: CGFloat.random(in: -200...200),
                            velocityY: CGFloat.random(in: -400 ... -100),
                            rotation: Double.random(in: 0...360),
                            spin: Double.random(in: -400...400),
                            width: CGFloat.random(in: 6...12),
                            height: CGFloat.random(in: 4...10),
                            isCircle: Bool.random(),
                            color: colors.randomElement() ?? .alefHabits
                        )
                    }

                    // Auto-dismiss after duration
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        isActive = false
                    }
                }
                .allowsHitTesting(false)
                .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Particle Model

private struct ConfettiParticle {
    let startX: CGFloat
    let startY: CGFloat
    let velocityX: CGFloat
    let velocityY: CGFloat
    let rotation: Double
    let spin: Double
    let width: CGFloat
    let height: CGFloat
    let isCircle: Bool
    let color: Color
}
