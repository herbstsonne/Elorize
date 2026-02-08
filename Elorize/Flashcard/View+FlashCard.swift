import SwiftUI

extension View {
	func overlayBoxStyle() -> some View {
		self
			.padding(10)
			.background(
				RoundedRectangle(cornerRadius: 12, style: .continuous)
					.fill(.ultraThinMaterial)
			)
			.overlay(
				RoundedRectangle(cornerRadius: 12, style: .continuous)
					.strokeBorder(Color.secondary.opacity(0.15))
			)
	}
}
