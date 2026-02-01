import SwiftUI

struct TextViewModifier: ViewModifier {
	
	var textSize: CGFloat

	func body(content: Content) -> some View {
		content
			.font(.system(size: textSize, weight: .semibold, design: .serif))
			.kerning(1.5)
			.foregroundStyle(
				LinearGradient(
					colors: [
						Color(red: 0.92, green: 0.82, blue: 0.56),
						Color(red: 0.76, green: 0.64, blue: 0.34)
					],
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
