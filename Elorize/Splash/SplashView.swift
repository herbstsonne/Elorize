import SwiftUI

struct SplashView: View {

	@StateObject private var viewModel = SplashViewModel()

    var body: some View {
        Group {
					if viewModel.isActive {
                HomeTabView()
                    .transition(.opacity)
            } else {
                splashContent
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation(.easeOut(duration: 0.35)) {
															viewModel.isActive = true
                            }
                        }
                    }
            }
        }
    }

    private var splashContent: some View {
        ZStack {
					BackgroundColorView()
					GeometryReader { proxy in
						let maxWidth = min(proxy.size.width - 48, 520)
						VStack(spacing: 0) {
							RoundedRectangle(cornerRadius: 24, style: .continuous)
							    // Base fill matching flash card surface
							    .fill(Color.app(.card_background))
							    // Subtle border similar to flash card edge
							    .overlay(
							        RoundedRectangle(cornerRadius: 24, style: .continuous)
							            .stroke(Color.app(.background_primary).opacity(0.35), lineWidth: 1)
							    )
							    .frame(width: maxWidth, height: 260)
							    // Gentle highlight like the flash card sheen
							    .overlay(
							        RoundedRectangle(cornerRadius: 24, style: .continuous)
							            .fill(
							                LinearGradient(
							                    colors: [
							                        Color.app(.accent_subtle).opacity(0.06),
							                        Color.app(.accent_subtle).opacity(0.0)
							                    ],
							                    startPoint: .top,
							                    endPoint: .bottom
							                )
							            )
							            .blur(radius: 4)
							    )
							    // Softer elevation shadow to match card
							    .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)
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
                            colors: [Color.app(.gold_primary), Color.app(.accent_default)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 6)
                    .overlay {
                        // Subtle top highlight
                        Text("Elorize")
                            .font(.system(size: 192, weight: .semibold, design: .serif))
                            .kerning(1.5)
                            .foregroundColor(Color.app(.text_primary).opacity(0.15))
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
                    .foregroundStyle(Color.app(.accent_subtle))
            }
            .padding(.horizontal, 24)
						.opacity(viewModel.opacity)
						.scaleEffect(viewModel.scale)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
									viewModel.opacity = 1.0
									viewModel.scale = 1.0
                }
            }

            // Decorative fleur-de-lis hint at the bottom (using a leaf as a stand-in)
            VStack {
                Spacer()
                Image(systemName: "leaf.fill")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.app(.text_secondary).opacity(0.22))
                    .padding(.bottom, 28)
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    SplashView()
}
