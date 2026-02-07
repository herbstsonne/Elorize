import SwiftUI

struct FlashCardView: View {

	private var viewModel: FlashCardViewModel

	init(viewModel: FlashCardViewModel) {
		self.viewModel = viewModel
	}

	var body: some View {
		VStack(spacing: 24) {
			ZStack {
				RoundedRectangle(cornerRadius: 16, style: .continuous)
					.fill(Color.app(.card_background))
					.shadow(radius: 4)
				
				VStack(spacing: 12) {
					
					ScrollView {
						Text((viewModel.isFlipped ? viewModel.card?.back : viewModel.card?.front) ?? "")
							.font(.largeTitle).bold()
							.multilineTextAlignment(.center)
							.lineLimit(10)
							.minimumScaleFactor(0.5)
							.padding()
					}
					
					if let note = viewModel.card?.note, !note.isEmpty, !viewModel.isFlipped {
						Text(note)
							.font(.subheadline)
							.foregroundStyle(.secondary)
					}
					
					if !(viewModel.card?.tags.isEmpty ?? true) {
						ScrollView(.horizontal, showsIndicators: false) {
							HStack(spacing: 8) {
								ForEach(viewModel.card?.tags ?? [], id: \.self) { tag in
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
			.offset(x: viewModel.dragOffset.width, y: viewModel.dragOffset.height)
			.rotationEffect(.degrees(viewModel.dragRotation))
			.gesture(dragGesture)
			.animation(.spring(response: 0.25, dampingFraction: 0.8), value: viewModel.dragOffset)
			.animation(.spring(response: 0.25, dampingFraction: 0.8), value: viewModel.dragRotation)
			.onTapGesture { withAnimation(.spring()) { viewModel.flip() } }
			.padding(.horizontal)
			
			HStack(spacing: 16) {
				Button {
					viewModel.onWrong()
					viewModel.isFlipped = false
				} label: {
					Label("Wrong", systemImage: "xmark")
						.frame(maxWidth: .infinity)
				}
				.buttonStyle(.bordered)
				.tint(Color.app(.error))
				
				Button {
					viewModel.onCorrect()
					viewModel.isFlipped = false
				} label: {
					Label("Correct", systemImage: "checkmark")
						.frame(maxWidth: .infinity)
				}
				.buttonStyle(.borderedProminent)
				.tint(Color.app(.success))
			}
			.padding(.horizontal)
		}
		.padding(.vertical)
	}
	
	// MARK: - Gestures
	private var dragGesture: some Gesture {
		DragGesture(minimumDistance: 10)
			.onChanged { value in
				viewModel.dragOffset = value.translation
				// Slight rotation based on horizontal drag
				viewModel.dragRotation = Double(value.translation.width / 20)
			}
			.onEnded { value in
				let threshold: CGFloat = 80
				if value.translation.width > threshold || value.translation.width < -threshold {
					// Swipe left or right -> next card (no grading)
					viewModel.onNext()
					resetCardPosition()
					viewModel.isFlipped = false
				} else {
					// Snap back
					resetCardPosition()
				}
			}
	}
	
	private func resetCardPosition() {
		viewModel.dragOffset = .zero
		viewModel.dragRotation = 0
	}
}

