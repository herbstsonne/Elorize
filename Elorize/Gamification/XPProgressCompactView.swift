import SwiftUI

struct XPProgressCompactView: View {
  @EnvironmentObject var viewModel: HomeViewModel
  @State private var showingDetails = false

  var body: some View {
    HStack(spacing: 10) {
      Button {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
        showingDetails = true
      } label: {
        Text("Lv. \(viewModel.xpState.level)")
          .font(.footnote)
          .foregroundStyle(Color.app(.accent_subtle))
        ProgressView(value: viewModel.xpState.levelProgress)
          .progressViewStyle(.linear)
          .frame(width: 120, height: 16)
          .contentShape(Rectangle())
          .tint(Color.app(.accent_subtle))
        Text("XP")
          .font(.footnote)
          .foregroundStyle(Color.app(.accent_subtle))
      }
      .buttonStyle(.plain)
      .padding(.vertical, 6)
      .frame(minWidth: 200)
      .accessibilityLabel("Open XP details")
    }
    .accessibilityLabel("Level \(viewModel.xpState.level), progress \(Int(viewModel.xpState.levelProgress * 100)) percent")
    .padding(.horizontal, 6)
    .padding(.vertical, 2)
    .accessibilityHint("Opens XP and level details.")
    .padding(.trailing, 4)
    .sheet(isPresented: $showingDetails) {
      XPDetailsView()
        .environmentObject(viewModel)
    }
  }
}

#Preview {
  XPProgressCompactView()
    .environmentObject(HomeViewModel())
}
private struct XPDetailsView: View {
  @EnvironmentObject var viewModel: HomeViewModel
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form {
        Section("Level & Progress") {
          HStack {
            Text("Current level")
            Spacer()
            Text("\(viewModel.xpState.level)")
          }
          HStack {
            Text("Total XP")
            Spacer()
            Text("\(viewModel.xpState.xp)")
          }
          HStack {
            Text("XP in this level")
            Spacer()
            Text("\(viewModel.xpState.xpIntoCurrentLevel) / \(viewModel.xpState.xpForNextLevel)")
          }
          ProgressView(value: viewModel.xpState.levelProgress)
            .progressViewStyle(.linear)
            .tint(Color.app(.accent_default))
        }
        Section("How do I earn XP?") {
          VStack(alignment: .leading, spacing: 8) {
            Text("• Correct answer: +5 XP")
            Text("• Wrong answer: +1 XP (for the attempt)")
            Text("• Level up: Every 100 XP, your level increases and XP resets within the new level")
          }
        }

        Section("Tips for the next level") {
          VStack(alignment: .leading, spacing: 8) {
            let remaining = max(0, viewModel.xpState.xpForNextLevel - viewModel.xpState.xpIntoCurrentLevel)
            Text("• XP needed: \(remaining)")
            Text("• Example: \(remaining / 5) correct answers or a mix of correct/incorrect")
            Text("• Study regularly: Consistent sessions help you level up faster")
          }
        }
      }
      .navigationTitle("Your Progress")
      .navigationBarTitleDisplayMode(.inline)
      .scrollContentBackground(.hidden)
      .background(BackgroundColorView().ignoresSafeArea())
      .foregroundStyle(Color.app(.accent_subtle))
      .tint(Color.app(.accent_subtle))
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbarBackground(Color.clear, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") { dismiss() }
        }
      }
    }
  }
}

