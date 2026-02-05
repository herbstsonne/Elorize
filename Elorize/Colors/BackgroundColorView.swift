import SwiftUI

struct BackgroundColorView: View {
	
	var body: some View {
		ZStack {
			// Deep, inky background with a subtle vignette
			LinearGradient(
				colors: [Color.app(.background_primary), Color.app(.background_secondary)],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
			.ignoresSafeArea()
			
			// Soft vignette glow
			RadialGradient(
				colors: [Color.app(.accent_default).opacity(0.1), .clear],
				center: .center,
				startRadius: 10,
				endRadius: 380
			)
			.blendMode(.softLight)
			.ignoresSafeArea()
		}
	}
}
