import SwiftUI
import SwiftData

struct FlowerTimerView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = FlowerTimerViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Compact timer view at the top
            HStack(spacing: 8) {
                if !viewModel.isTimerRunning {
                    flowerPickerButton
                }
                growingFlowerView
                timerDisplay
                controlButtons
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Color.app(.background_secondary).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .sheet(isPresented: $viewModel.showFlowerPicker) {
            flowerPickerSheet
        }
        .overlay {
            if viewModel.showCompletionCelebration {
                completionOverlay
            }
        }
    }
    
    // MARK: - View Components
    
    private var flowerPickerButton: some View {
        Button {
            viewModel.showFlowerPicker = true
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.selectedFlower.emoji)
                    .font(.system(size: 20))
                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
            .padding(6)
            .background(Color.app(.background_secondary))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
    
    private var growingFlowerView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.app(.background_secondary),
                            Color.app(.background_primary)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 60, height: 60)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: viewModel.progress)
                .stroke(
                    viewModel.selectedFlower.color.opacity(0.8),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1.0), value: viewModel.progress)
            
            // Flower growth stages
            VStack(spacing: 1) {
                Text(flowerEmoji)
                    .font(.system(size: flowerSize))
                    .scaleEffect(flowerScale)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: viewModel.growthStage)
                
                if viewModel.growthStage > 0 {
                    Text("🌱")
                        .font(.system(size: 8))
                        .opacity(viewModel.growthStage >= 1 ? 1.0 : 0.0)
                }
            }
        }
    }
    
    private var flowerEmoji: String {
        switch viewModel.growthStage {
        case 0: return "🌱"  // Seed
        case 1: return "🌱"  // Sprout
        case 2: return "🌿"  // Growing
        case 3: return viewModel.selectedFlower.emoji  // Budding
        case 4: return viewModel.selectedFlower.emoji  // Almost full
        case 5: return viewModel.selectedFlower.emoji  // Full bloom
        default: return "🌱"
        }
    }
    
    private var flowerSize: CGFloat {
        switch viewModel.growthStage {
        case 0: return 9
        case 1: return 12
        case 2: return 15
        case 3: return 18
        case 4: return 21
        case 5: return 24
        default: return 9
        }
    }
    
    private var flowerScale: CGFloat {
        viewModel.growthStage >= 5 ? 1.0 : 0.8
    }
    
    private var timerDisplay: some View {
        VStack(spacing: 2) {
            if viewModel.isTimerRunning || viewModel.isPaused {
                Text(viewModel.timeRemainingFormatted)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.app(.accent_default))
                
                Text("Keep learning to grow your flower!")
                    .font(.system(size: 6))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Ready to start")
                    .font(.system(size: 7))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var controlButtons: some View {
        HStack(spacing: 8) {
            if !viewModel.isTimerRunning {
                // Start button
                Button {
                    viewModel.startTimer()
                } label: {
                    Label("Start", systemImage: "play.fill")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                }
                .buttonStyle(
                    ComposedPressTintStyle(
                        kind: .borderedProminent,
                        normalTint: Color.app(.accent_default),
                        pressedTint: Color.app(.accent_pressed)
                    )
                )
            } else {
                // Pause/Resume button
                Button {
                    if viewModel.isPaused {
                        viewModel.resumeTimer()
                    } else {
                        viewModel.pauseTimer()
                    }
                } label: {
                    Label(viewModel.isPaused ? "Resume" : "Pause", 
                          systemImage: viewModel.isPaused ? "play.fill" : "pause.fill")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                }
                .buttonStyle(
                    ComposedPressTintStyle(
                        kind: .borderedProminent,
                        normalTint: Color.app(.button_default),
                        pressedTint: Color.app(.button_pressed)
                    )
                )
                
                // Stop button
                Button {
                    // Save the flower if timer completed
                    if viewModel.progress >= 1.0 {
                        saveFlower()
                    }
                    viewModel.stopTimer()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                }
                .buttonStyle(
                    ComposedPressTintStyle(
                        kind: .borderedProminent,
                        normalTint: Color.app(.button_default),
                        pressedTint: Color.app(.button_pressed)
                    )
                )
            }
        }
    }
    
    private var flowerPickerSheet: some View {
        NavigationStack {
            List(FlowerType.allCases) { flower in
                Button {
                    viewModel.changeFlower(flower)
                    viewModel.showFlowerPicker = false
                } label: {
                    HStack(spacing: 16) {
                        Text(flower.emoji)
                            .font(.system(size: 40))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(flower.rawValue)
                                .font(.headline)
                                .foregroundStyle(Color.app(.text_primary))
                            
                            Text("\(flower.duration) minutes")
                                .font(.caption)
                                .foregroundStyle(Color.app(.text_highlight))
                        }
                        
                        Spacer()
                        
                        if viewModel.selectedFlower == flower {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.app(.accent_default))
                        }
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.app(.background_secondary).opacity(0.5))
            }
            .scrollContentBackground(.hidden)
            .background(Color.app(.background_primary).opacity(0.85))
            .navigationTitle("Grow a flower")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        viewModel.showFlowerPicker = false
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(Color.app(.background_primary).opacity(0.85))
    }
    
    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text(viewModel.selectedFlower.emoji)
                    .font(.system(size: 100))
                    .scaleEffect(viewModel.showCompletionCelebration ? 1.2 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5), value: viewModel.showCompletionCelebration)
                
                VStack(spacing: 8) {
                    Text("Flower Grown!")
                        .font(.title.bold())
                        .foregroundStyle(Color.app(.text_primary))
                    
                    Text("Great job studying!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Button {
                    saveFlower()
                    viewModel.showCompletionCelebration = false
                    viewModel.stopTimer()
                } label: {
                    Text("Add to Garden")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: 200)
                        .padding()
                        .background(viewModel.selectedFlower.color)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(32)
            .background(Color.app(.background_primary))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(radius: 20)
            .padding(32)
        }
    }
    
    // MARK: - Actions
    
    private func saveFlower() {
        let flower = FlowerEntity(
            flowerType: viewModel.selectedFlower,
            studyDurationMinutes: viewModel.selectedFlower.duration
        )
        context.insert(flower)
        try? context.save()
    }
}

#Preview {
    FlowerTimerView()
        .modelContainer(for: FlowerEntity.self, inMemory: true)
}
