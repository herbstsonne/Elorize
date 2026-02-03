import SwiftUI

extension View {
	@ViewBuilder
	func accentText() -> some View {
		self
			.foregroundStyle(Color.app(.accent_default))
			.textViewStyle(16)
	}
	
	@ViewBuilder
	func centeredCardFrame() -> some View {
		self
			.frame(maxWidth: 560)
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
	}
}
