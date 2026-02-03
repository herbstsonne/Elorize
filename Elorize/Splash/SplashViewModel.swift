import SwiftUI
public import Combine

@MainActor
public final class SplashViewModel: ObservableObject {

	@Published var isActive = false
	@Published var opacity: Double = 0.0
	@Published var scale: CGFloat = 0.9

	public init() {}
}
