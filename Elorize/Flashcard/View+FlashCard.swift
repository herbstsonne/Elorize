import SwiftUI

extension View {
	func overlayBoxStyle() -> some View {
		self
			.padding(10)
			.background(
				RoundedRectangle(cornerRadius: 12, style: .continuous)
					.fill(Color.app(.background_primary))
			)
			.overlay(
				RoundedRectangle(cornerRadius: 12, style: .continuous)
					.strokeBorder(Color.secondary.opacity(0.15))
			)
	}
}
