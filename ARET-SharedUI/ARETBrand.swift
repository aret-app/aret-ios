import SwiftUI

extension Color {
    static let aretOrange = Color(
        red: 1.0,
        green: 0.34,
        blue: 0.09
    )

    static let aretBackground = Color(
        red: 0.025,
        green: 0.03,
        blue: 0.035
    )

    static let aretSurface = Color(
        red: 0.07,
        green: 0.08,
        blue: 0.09
    )

    static let aretLine = Color.white.opacity(0.12)
}

struct ARETMark: View {
    var size: CGFloat = 36
    var monochrome = false

    var body: some View {
        ZStack {
            mountain
                .stroke(
                    Color.white,
                    style: StrokeStyle(
                        lineWidth: max(2.2, size * 0.075),
                        lineCap: .round,
                        lineJoin: .round
                    )
                )

            route
                .stroke(
                    monochrome ? Color.white : .aretOrange,
                    style: StrokeStyle(
                        lineWidth: max(2, size * 0.065),
                        lineCap: .round,
                        lineJoin: .round
                    )
                )

            routeEndpoints
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var mountain: Path {
        Path { path in
            path.move(to: CGPoint(x: size * 0.08, y: size * 0.86))
            path.addLine(to: CGPoint(x: size * 0.50, y: size * 0.10))
            path.addLine(to: CGPoint(x: size * 0.92, y: size * 0.86))

            path.move(to: CGPoint(x: size * 0.24, y: size * 0.86))
            path.addLine(to: CGPoint(x: size * 0.50, y: size * 0.50))
            path.addLine(to: CGPoint(x: size * 0.62, y: size * 0.67))
            path.addLine(to: CGPoint(x: size * 0.72, y: size * 0.55))
            path.addLine(to: CGPoint(x: size * 0.86, y: size * 0.79))
        }
    }

    private var route: Path {
        Path { path in
            path.move(
                to: CGPoint(
                    x: size * 0.24,
                    y: size * 0.78
                )
            )

            path.addCurve(
                to: CGPoint(
                    x: size * 0.58,
                    y: size * 0.31
                ),
                control1: CGPoint(
                    x: size * 0.31,
                    y: size * 0.59
                ),
                control2: CGPoint(
                    x: size * 0.50,
                    y: size * 0.58
                )
            )
        }
    }

    private var routeEndpoints: some View {
        ZStack {
            endpoint(
                x: size * 0.24,
                y: size * 0.78
            )

            endpoint(
                x: size * 0.58,
                y: size * 0.31
            )
        }
    }

    private func endpoint(
        x: CGFloat,
        y: CGFloat
    ) -> some View {
        Circle()
            .fill(
                monochrome ? .white : .aretOrange
            )
            .overlay {
                Circle()
                    .fill(.white)
                    .padding(size * 0.055)
            }
            .frame(
                width: max(7, size * 0.17),
                height: max(7, size * 0.17)
            )
            .position(x: x, y: y)
    }
}

struct ARETWordmark: View {
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 7 : 10) {
            ARETMark(
                size: compact ? 28 : 34
            )

            Text("ARET")
                .font(
                    .system(
                        size: compact ? 15 : 19,
                        weight: .semibold,
                        design: .rounded
                    )
                )
                .tracking(compact ? 4 : 6)
                .foregroundStyle(.white)
        }
    }
}

struct ARETGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 24
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
                .stroke(
                    Color.white.opacity(0.10),
                    lineWidth: 0.8
                )
            }
            .shadow(
                color: .black.opacity(0.28),
                radius: 18,
                y: 8
            )
    }
}

extension View {
    func aretGlassCard(
        cornerRadius: CGFloat = 24,
        padding: CGFloat = 16
    ) -> some View {
        modifier(
            ARETGlassCardModifier(
                cornerRadius: cornerRadius,
                padding: padding
            )
        )
    }

    func aretScreenBackground() -> some View {
        background(
            LinearGradient(
                colors: [
                    .aretBackground,
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}
