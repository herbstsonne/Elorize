import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var opacity: Double = 0.0
    @State private var scale: CGFloat = 0.9

    var body: some View {
        Group {
            if isActive {
                HomeView()
                    .transition(.opacity)
            } else {
                splashContent
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation(.easeOut(duration: 0.35)) {
                                isActive = true
                            }
                        }
                    }
            }
        }
    }

    private var splashContent: some View {
        ZStack {
            // Deep, inky background with a subtle vignette
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.10, blue: 0.18), Color(red: 0.02, green: 0.03, blue: 0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Soft vignette glow
            RadialGradient(
                colors: [Color.white.opacity(0.08), .clear],
                center: .center,
                startRadius: 10,
                endRadius: 380
            )
            .blendMode(.softLight)
            .ignoresSafeArea()

            // Subtle decorative framing (arched hint)
            GeometryReader { proxy in
                let maxWidth = min(proxy.size.width - 48, 520)
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        .frame(width: maxWidth, height: 260)
                        .overlay(
                            RoundedRectangle(cornerRadius: 40, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.03), Color.white.opacity(0.0)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .blur(radius: 6)
                        )
                        .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)
                        .padding(.bottom, 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .allowsHitTesting(false)

            // Title and tagline
            VStack(spacing: 14) {
                // Elegant, Parisian-inspired title
                Text("Elorize")
                    .font(.system(size: 64, weight: .semibold, design: .serif))
                    .kerning(1.5)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.92, green: 0.82, blue: 0.56), Color(red: 0.76, green: 0.64, blue: 0.34)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 6)
                    .overlay {
                        // Subtle top highlight
                        Text("Elorize")
                            .font(.system(size: 192, weight: .semibold, design: .serif))
                            .kerning(1.5)
                            .foregroundColor(.white.opacity(0.15))
                            .blur(radius: 0.8)
                            .offset(y: -1.5)
                            .mask(
                                LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .bottom)
                            )
                    }

                // Understated Parisian tagline
                Text("elevate memorization")
                    .font(.system(size: 22, weight: .regular, design: .serif))
                    .textCase(.lowercase)
                    .kerning(2)
                    .foregroundStyle(Color.white.opacity(0.72))
            }
            .padding(.horizontal, 24)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    opacity = 1.0
                    scale = 1.0
                }
            }

            // Decorative fleur-de-lis hint at the bottom (using a leaf as a stand-in)
            VStack {
                Spacer()
                Image(systemName: "leaf.fill")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.22))
                    .padding(.bottom, 28)
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    SplashView()
}
