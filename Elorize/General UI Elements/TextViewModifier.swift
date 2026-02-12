import SwiftUI

struct TextViewModifier: ViewModifier {
	
	var textSize: CGFloat

	func body(content: Content) -> some View {
		content
			.font(.system(size: textSize, weight: .semibold, design: .serif))
			.kerning(1.5)
			.foregroundStyle(
				LinearGradient(
					colors: [Color.app(.gold_primary), Color.app(.accent_default)],
					startPoint: .topLeading,
					endPoint: .bottomTrailing
				)
			)
			.shadow(
				color: Color.black.opacity(0.35),
				radius: 10,
				x: 0,
				y: 6
			)
	}
}

extension View {
	func textViewStyle(_ textSize: CGFloat) -> some View {
		self.modifier(TextViewModifier(textSize: textSize))
	}
}
