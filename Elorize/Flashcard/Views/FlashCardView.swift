import SwiftUI

struct FlashCardView: View {
	
	@ObservedObject private var viewModel: FlashCardViewModel
	
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
					cardTextArea()
					
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
				
				VStack {
					Spacer()
					if viewModel.showsTextControls && !viewModel.isInteracting {
						VStack(alignment: .leading, spacing: 10) {
							fontFamilyRow()
							fontSizeRow()
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
				viewModel.isInteracting = true
			}
			.onEnded { value in
				let threshold: CGFloat = 80
				if value.translation.width > threshold || value.translation.width < -threshold {
					// Swipe left or right -> next card (no grading)
					viewModel.onNext()
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
	
	private func resetCardPosition() {
		viewModel.dragOffset = .zero
		viewModel.dragRotation = 0
	}
	
	// MARK: - Font helpers
	private func selectedFont() -> Font {
		if viewModel.fontName == "System" {
			return .system(size: viewModel.fontSize)
		} else {
			return .custom(viewModel.fontName, size: viewModel.fontSize)
		}
	}
	
	private func previewFont(name: String, size: CGFloat) -> Font {
		if name == "System" {
			return .system(size: size)
		} else {
			return .custom(name, size: size)
		}
	}
}

private extension FlashCardView {

	@ViewBuilder
	private func cardTextArea() -> some View {
		ScrollView {
			Text((viewModel.isFlipped ? viewModel.card?.back : viewModel.card?.front) ?? "")
				.font(selectedFont())
				.bold()
				.multilineTextAlignment(.center)
				.lineLimit(10)
				.minimumScaleFactor(0.5)
				.padding()
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
	private func fontSizeRow() -> some View {
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
	private func textControlsToggleButton() -> some View {
		Button {
			withAnimation(.spring()) {
				viewModel.showsTextControls.toggle()
			}
		} label: {
			Image(systemName: "textformat.size.smaller")
				.padding(8)
				.background(.ultraThinMaterial, in: Circle())
		}
		.accessibilityLabel("Toggle text controls")
	}
}

