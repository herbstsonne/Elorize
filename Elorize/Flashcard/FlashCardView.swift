import SwiftUI

struct FlashCardView: View {
	let card: FlashCard
	var onWrong: () -> Void
	var onCorrect: () -> Void
	var onNext: () -> Void
	
	@State private var isShowingBack = false
	@State private var dragOffset: CGSize = .zero
	@State private var dragRotation: Double = 0
	
	var body: some View {
		VStack(spacing: 24) {
			ZStack {
				RoundedRectangle(cornerRadius: 16, style: .continuous)
					.fill(.background)
					.shadow(radius: 4)
				
				VStack(spacing: 12) {
					Text(isShowingBack ? card.back : card.front)
						.font(.largeTitle).bold()
						.multilineTextAlignment(.center)
						.padding()
					
					if let note = card.note, !note.isEmpty, !isShowingBack {
						Text(note)
							.font(.subheadline)
							.foregroundStyle(.secondary)
					}
					
					if !card.tags.isEmpty {
						ScrollView(.horizontal, showsIndicators: false) {
							HStack(spacing: 8) {
								ForEach(card.tags, id: \.self) { tag in
									Text(tag)
										.font(.caption)
										.padding(.horizontal, 8)
										.padding(.vertical, 4)
										.background(Capsule().fill(Color.accentColor.opacity(0.15)))
								}
							}
							.padding(.horizontal)
						}
					}
				}
				.padding()
			}
			.frame(maxWidth: .infinity)
			.frame(height: 260)
			.offset(x: dragOffset.width, y: dragOffset.height)
			.rotationEffect(.degrees(dragRotation))
			.gesture(dragGesture)
			.animation(.spring(response: 0.25, dampingFraction: 0.8), value: dragOffset)
			.animation(.spring(response: 0.25, dampingFraction: 0.8), value: dragRotation)
			.onTapGesture { withAnimation(.spring()) { isShowingBack.toggle() } }
			.padding(.horizontal)
			
			HStack(spacing: 16) {
				Button {
					onWrong()
					isShowingBack = false
				} label: {
					Label("Again", systemImage: "xmark")
						.frame(maxWidth: .infinity)
				}
				.buttonStyle(.bordered)
				.tint(.red)
				
				Button {
					onCorrect()
					isShowingBack = false
				} label: {
					Label("Easy", systemImage: "checkmark")
						.frame(maxWidth: .infinity)
				}
				.buttonStyle(.borderedProminent)
			}
			.padding(.horizontal)
		}
		.padding(.vertical)
	}
	
	// MARK: - Gestures
	private var dragGesture: some Gesture {
		DragGesture(minimumDistance: 10)
			.onChanged { value in
				dragOffset = value.translation
				// Slight rotation based on horizontal drag
				dragRotation = Double(value.translation.width / 20)
			}
			.onEnded { value in
				let threshold: CGFloat = 80
				if value.translation.width > threshold || value.translation.width < -threshold {
					// Swipe left or right -> next card (no grading)
					onNext()
					resetCardPosition()
					isShowingBack = false
				} else {
					// Snap back
					resetCardPosition()
				}
			}
	}
	
	private func resetCardPosition() {
		dragOffset = .zero
		dragRotation = 0
	}
}

