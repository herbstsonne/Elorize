import SwiftUI

struct OnboardingView: View {
  @Binding var isPresented: Bool
  let onGetStarted: () -> Void

  @StateObject private var viewModel = OnboardingViewModel()

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        TabView(selection: $viewModel.viewIndex) {
          ForEach(viewModel.views.indices, id: \.self) { idx in
            VStack(spacing: 16) {
              Image(systemName: viewModel.views[idx].systemImage)
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(.tint)
              Text(viewModel.views[idx].title)
                .font(.title2).bold()
              Text(viewModel.views[idx].message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            }
            .tag(idx)
          }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .interactive))
        .padding(.top, 16)

        HStack {
          Button("Skip") {
            viewModel.skip()
            onGetStarted()
            isPresented = false
          }
          .buttonStyle(.borderless)
          .foregroundStyle(.secondary)

          Spacer()

          if !viewModel.isLastView {
            Button("Next") {
              withAnimation { viewModel.advance() }
            }
            .buttonStyle(.borderedProminent)
          } else {
            Button("Get Started") {
              onGetStarted()
              isPresented = false
            }
            .buttonStyle(.borderedProminent)
          }
        }
        .padding(.horizontal)
        .padding(.bottom)
      }
      .navigationTitle("Getting Started")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Close") {
            isPresented = false
          }
        }
      }
    }
  }
}

