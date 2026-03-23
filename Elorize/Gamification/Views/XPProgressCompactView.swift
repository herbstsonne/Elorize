import SwiftUI
internal import Combine

struct XPProgressCompactView: View {
  @EnvironmentObject var homeViewModel: HomeViewModel
  @StateObject private var viewModel = XPProgressCompactViewModel()

  var body: some View {
    HStack(spacing: 10) {
      Button {
        viewModel.openDetails()
      } label: {
        Text("Lv. \(homeViewModel.xpState.level)")
          .font(.footnote)
          .foregroundStyle(Color.app(.accent_subtle))
        ProgressView(value: homeViewModel.xpState.levelProgress)
          .progressViewStyle(.linear)
          .frame(width: 60, height: 16)
          .contentShape(Rectangle())
          .tint(Color.app(.accent_subtle))
        Text("XP")
          .font(.footnote)
          .foregroundStyle(Color.app(.accent_subtle))
      }
      .buttonStyle(.plain)
      .padding(.vertical, 6)
      .frame(minWidth: 140)
      .accessibilityLabel("Open XP details")
    }
    .accessibilityLabel(viewModel.accessibilityLabel)
    .padding(.horizontal, 6)
    .padding(.vertical, 2)
    .accessibilityHint(viewModel.accessibilityHint)
    .padding(.trailing, 4)
    .sheet(isPresented: $viewModel.showingDetails) {
      XPDetailsView(viewModel: viewModel)
    }
    .onAppear {
      viewModel.configure(with: homeViewModel)
    }
    .onChange(of: homeViewModel.xpState) { _, _ in
      // Trigger view update when XP state changes
      viewModel.objectWillChange.send()
    }
  }
}

#Preview {
  XPProgressCompactView()
    .environmentObject(HomeViewModel())
}
private struct XPDetailsView: View {
  @ObservedObject var viewModel: XPProgressCompactViewModel
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form {
        Section("Level & Progress") {
          HStack {
            Text("Current level")
            Spacer()
            Text("\(viewModel.level)")
          }
          HStack {
            Text("Total XP")
            Spacer()
            Text("\(viewModel.totalXP)")
          }
          HStack {
            Text("XP in this level")
            Spacer()
            Text("\(viewModel.xpIntoCurrentLevel) / \(viewModel.xpForNextLevel)")
          }
          ProgressView(value: viewModel.levelProgress)
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
            Text("• XP needed: \(viewModel.xpRemaining)")
            Text("• Example: \(viewModel.correctAnswersNeeded) correct answers or a mix of correct/incorrect")
            Text("• Study regularly: Consistent sessions help you level up faster")
          }
        }
      }
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

