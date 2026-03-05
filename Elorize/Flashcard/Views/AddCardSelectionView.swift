import SwiftUI

/// View for manually entering flashcards (photo scanning feature removed)
struct AddCardSelectionView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // Directly show manual entry view
        AddFlashCardView()
            .environmentObject(viewModel)
    }
}

#Preview {
    AddCardSelectionView()
        .environmentObject(HomeViewModel())
}
