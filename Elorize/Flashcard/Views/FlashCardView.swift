import SwiftUI
import SwiftData

struct FlashCardView: View {

	@ObservedObject private var viewModel: FlashCardViewModel
	
	init(viewModel: FlashCardViewModel) {
		self.viewModel = viewModel
	}
	
	var body: some View {
		VStack(spacing: 24) {
			card()
			.aspectRatio(7.0/5.0, contentMode: .fit)
			.frame(maxWidth: .infinity)
			.offset(x: viewModel.dragOffset.width, y: viewModel.dragOffset.height)
			.rotationEffect(.degrees(viewModel.dragRotation))
			.gesture(dragGesture)
			.animation(.spring(response: 0.25, dampingFraction: 0.8), value: viewModel.dragOffset)
			.animation(.spring(response: 0.25, dampingFraction: 0.8), value: viewModel.dragRotation)
			.onTapGesture { withAnimation(.spring()) { viewModel.flip() } }
			.padding(.horizontal)
			
			HStack(spacing: 16) {
				buttonWrong()
				buttonCorrect()
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
				viewModel.isInteracting = true
			}
			.onEnded { value in
				let threshold: CGFloat = 80
				let translation = value.translation.width

				if translation <= -threshold {
					// Swipe right-to-left -> previous card
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
						viewModel.actions.onPrevious()
					}
					resetCardPosition()
					viewModel.isInteracting = false
					viewModel.isFlipped = false
				} else if translation >= threshold {
					// Swipe left-to-right -> next card
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
						viewModel.actions.onNext()
					}
					resetCardPosition()
					viewModel.isInteracting = false
					viewModel.isFlipped = false
				} else {
					// Snap back
					resetCardPosition()
					viewModel.isInteracting = false
				}
			}
	}
}

// MARK: Private functions

private extension FlashCardView {

	private func resetCardPosition() {
		viewModel.dragOffset = .zero
		viewModel.dragRotation = 0
	}
	
	private func previewFont(name: String, size: CGFloat) -> Font {
		if name == "System" {
			return .system(size: size)
		} else {
			return .custom(name, size: size)
		}
	}
}

// MARK: ViewBuilder

private extension FlashCardView {

	@ViewBuilder
	func card() -> some View {
		ZStack {
      let bgColor: Color = {
        switch viewModel.highlightState {
        case .success: return Color.app(.success)
        case .error: return Color.app(.error)
        case .none: return Color.app(.card_background)
        }
      }()
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(bgColor)
        .shadow(radius: 4)
        .animation(.easeInOut(duration: 0.2), value: viewModel.highlightState)
			
			VStack(spacing: 12) {
				cardTextArea()
				cardTags()
			}
			.padding()
			
			VStack {
				Spacer()
				if viewModel.showsTextControls && !viewModel.isInteracting {
					VStack(alignment: .leading, spacing: 10) {
						fontFamilyRow()
						fontSizeRow()
						alignmentRow()
					}
					.overlayBoxStyle()
					.transition(.move(edge: .top).combined(with: .opacity))
				}
			}
			.frame(maxWidth: 360, alignment: .bottom)
			.padding([.bottom, .horizontal], 12)
			
			VStack {
				HStack {
					Spacer()
					textControlsToggleButton()
				}
				Spacer()
			}
			.padding([.top, .trailing], 12)
		}
	}

	@ViewBuilder
	func buttonWrong() -> some View {
		Button {
			viewModel.flashErrorHighlight {
				viewModel.actions.onWrong()
        viewModel.storeReview(isCorrect: false)
				viewModel.isFlipped = false
			}
		} label: {
			Label("Repeat", systemImage: "xmark")
				.frame(maxWidth: .infinity)
		}
		.buttonStyle(
			ComposedPressTintStyle(
				kind: .borderedProminent,
				normalTint: Color.app(.button_default),
				pressedTint: Color.app(.button_pressed)
			)
		)
	}

	@ViewBuilder
	func buttonCorrect() -> some View {
		Button {
			viewModel.flashSuccessHighlight {
				viewModel.actions.onCorrect()
        viewModel.storeReview(isCorrect: true)
				viewModel.isFlipped = false
			}
		} label: {
			Label("Got it", systemImage: "checkmark")
				.frame(maxWidth: .infinity)
		}
		.buttonStyle(
			ComposedPressTintStyle(
				kind: .borderedProminent,
				normalTint: Color.app(.button_default),
				pressedTint: Color.app(.button_pressed)
			)
		)
	}

	@ViewBuilder
	func cardTextArea() -> some View {
		ScrollView {
			Text((viewModel.isFlipped ? viewModel.card?.back : viewModel.card?.front) ?? "")
				.font(viewModel.selectedFont())
				.multilineTextAlignment(viewModel.textAlignment)
				.lineLimit(10)
				.minimumScaleFactor(0.5)
				.frame(maxWidth: .infinity, alignment: {
					viewModel.alignment
				}())
				.padding()
		}
	}

	@ViewBuilder
	func cardTags() -> some View {
		if !(viewModel.card?.tags.isEmpty ?? true) {
			ScrollView(.horizontal, showsIndicators: false) {
				HStack(spacing: 8) {
					ForEach(viewModel.card?.tags ?? [], id: \.self) { tag in
						Text(tag)
							.padding(.horizontal, 8)
							.padding(.vertical, 4)
							.background(Capsule().fill(Color.accentColor.opacity(0.15)))
					}
				}
				.padding(.horizontal)
			}
		}
	}

	@ViewBuilder
	func fontFamilyRow() -> some View {
		HStack(spacing: 8) {
			Image(systemName: "textformat")
				.foregroundStyle(.secondary)
			Text(viewModel.fontName == "System" ? "System" : viewModel.fontName)
				.font(.callout)
				.lineLimit(1)
			Spacer(minLength: 8)
			Menu {
				Picker("Font", selection: $viewModel.fontName) {
					ForEach(viewModel.availableFonts, id: \.self) { name in
						Text(name == "System" ? "System" : name)
							.font(previewFont(name: name, size: 14))
							.tag(name)
					}
				}
			} label: {
				Label("Change Font", systemImage: "chevron.down")
					.labelStyle(.iconOnly)
					.padding(6)
					.background(.thinMaterial, in: Capsule())
			}
			.accessibilityLabel("Change font family")
		}
	}
	
	@ViewBuilder
	func fontSizeRow() -> some View {
		HStack(spacing: 8) {
			Image(systemName: "textformat.size")
				.foregroundStyle(.secondary)
			Slider(value: $viewModel.fontSize, in: 18...60, step: 1) {
				Text("Font Size")
			} minimumValueLabel: {
				Text("A").font(.system(size: 12))
			} maximumValueLabel: {
				Text("A").font(.system(size: 18))
			}
			.accessibilityLabel("Font size")
			Text("\(Int(viewModel.fontSize))")
				.monospacedDigit()
				.foregroundStyle(.secondary)
				.frame(width: 32, alignment: .trailing)
		}
	}

	@ViewBuilder
	func alignmentRow() -> some View {
			HStack(spacing: 8) {
					Image(systemName: "text.alignleft")
							.foregroundStyle(.secondary)
					Picker("Alignment", selection: $viewModel.textAlignment) {
							Text("Left").tag(TextAlignment.leading)
							Text("Center").tag(TextAlignment.center)
							Text("Right").tag(TextAlignment.trailing)
					}
					.pickerStyle(.segmented)
					.accessibilityLabel("Text alignment")
			}
	}
	
	@ViewBuilder
	func textControlsToggleButton() -> some View {
		Button {
			withAnimation(.spring()) {
				viewModel.showsTextControls.toggle()
			}
		} label: {
			Image(systemName: "character.text.justify")
				.foregroundStyle(Color.app(.text_highlight))
				.frame(width: 44, height: 44)
				.background(Color.app(.background_primary), in: Circle())
		}
		.accessibilityLabel("Toggle text controls")
	}
}

