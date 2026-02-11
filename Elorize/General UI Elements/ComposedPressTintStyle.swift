import SwiftUI

private struct ComposedPressTintStyle: ButtonStyle {
	enum Kind { case bordered, borderedProminent }
	let kind: Kind
	let normalTint: Color
	let pressedTint: Color
	
	func makeBody(configuration: Configuration) -> some View {
		let currentTint = configuration.isPressed ? pressedTint : normalTint
		let tintedLabel = configuration.label
			.frame(maxWidth: .infinity)
			.tint(currentTint)
		
		AnyView(
			tintedLabel
				.padding(.vertical, 8)
				.padding(.horizontal, 10)
				.background(
					Capsule()
						.fill(currentTint)
				)
		)
	}
}
