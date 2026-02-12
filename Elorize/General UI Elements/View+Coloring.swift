import SwiftUI

extension View {
	@ViewBuilder
	func accentText() -> some View {
		self
			.foregroundStyle(Color.app(.accent_default))
			.textViewStyle(16)
	}
}
