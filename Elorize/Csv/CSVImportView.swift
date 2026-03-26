import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CSVImportView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = CSVImportViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundColorView()
                contentView
            }
            .foregroundStyle(Color.app(.accent_subtle))
            .navigationTitle("Import CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .fileImporter(
                isPresented: $viewModel.showingFilePicker,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert("Import Error", isPresented: errorBinding) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
    
    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 20) {
            if viewModel.isImporting {
                loadingView
            } else if viewModel.importComplete {
                successView
            } else if viewModel.showingPreview {
                previewView
            } else {
                initialView
            }
        }
        .padding()
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(LocalizedStringKey("Close")) {
                dismiss()
            }
        }
    }
}

// MARK: - Initial View
private extension CSVImportView {
    
    @ViewBuilder
    var initialView: some View {
        VStack(spacing: 24) {
            headerIcon
            titleText
            descriptionText
            exampleSection
            chooseFileButton
        }
    }
    
    var headerIcon: some View {
        Image(systemName: "doc.text.fill")
            .font(.system(size: 64))
            .foregroundStyle(Color.app(.accent_default))
    }
    
    var titleText: some View {
        Text(LocalizedStringKey("Import Flashcards from CSV"))
            .font(.title2)
            .fontWeight(.semibold)
            .multilineTextAlignment(.center)
    }
    
    var descriptionText: some View {
        Text(LocalizedStringKey("Select a CSV file with the following format:\nSubject, Question, Answer"))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }
    
    var exampleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey("Example:"))
                .font(.caption)
                .fontWeight(.medium)
            
            exampleCodeBlock
        }
        .padding(.horizontal)
    }
    
    var exampleCodeBlock: some View {
        Text(csvExampleText)
            .font(.caption)
            .fontDesign(.monospaced)
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
    }
    
    private var csvExampleText: String {
        """
        Subject,Question,Answer
        Swift Basics,What is Swift?,A programming language
        Swift Basics,What is SwiftUI?,A UI framework
        """
    }
    
    var chooseFileButton: some View {
        Button(action: {
            viewModel.showingFilePicker = true
        }) {
            Label(LocalizedStringKey("Choose CSV File"), systemImage: "folder")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.app(.accent_default))
                .foregroundStyle(.white)
                .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview View
private extension CSVImportView {
    
    @ViewBuilder
    var previewView: some View {
        VStack(spacing: 16) {
            previewTitle
            statsSection
            subjectsScrollView
            Spacer()
            actionButtons
        }
    }
    
    var previewTitle: some View {
        Text(LocalizedStringKey("Import Preview"))
            .font(.title2)
            .fontWeight(.semibold)
    }
    
    var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            flashcardsStatRow
            subjectsStatRow
        }
        .font(.headline)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    var flashcardsStatRow: some View {
        HStack {
            Image(systemName: "list.bullet.rectangle")
                .foregroundStyle(Color.app(.accent_default))
            Text("\(viewModel.importedRows.count)")
                .fontWeight(.semibold)
            Text(LocalizedStringKey("flashcards"))
        }
    }
    
    var subjectsStatRow: some View {
        HStack {
            Image(systemName: "folder")
                .foregroundStyle(Color.app(.accent_default))
            Text("\(viewModel.subjectPreview.count)")
                .fontWeight(.semibold)
            Text(LocalizedStringKey("subjects"))
        }
    }
    
    var subjectsScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("Subjects to be created:"))
                    .font(.headline)
                    .padding(.bottom, 4)
                
                ForEach(sortedSubjects, id: \.key) { subject, count in
                    subjectRow(name: subject, count: count)
                }
            }
            .padding()
        }
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var sortedSubjects: [(key: String, value: Int)] {
        viewModel.subjectPreview.sorted(by: { $0.key < $1.key })
    }
    
    func subjectRow(name: String, count: Int) -> some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundStyle(Color.app(.accent_default))
            Text(name)
            Spacer()
            Text("\(count) cards")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    var actionButtons: some View {
        HStack(spacing: 12) {
            cancelButton
            importButton
        }
    }
    
    var cancelButton: some View {
        Button(action: {
            viewModel.reset()
        }) {
            Text(LocalizedStringKey("Cancel"))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.secondary.opacity(0.2))
                .foregroundStyle(Color.app(.accent_subtle))
                .cornerRadius(12)
        }
    }
    
    var importButton: some View {
        Button(action: {
            viewModel.performImport(context: context) {
                // Import complete
            }
        }) {
            Text(LocalizedStringKey("Import"))
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.app(.accent_default))
                .foregroundStyle(.white)
                .cornerRadius(12)
        }
    }
}

// MARK: - Loading View
private extension CSVImportView {
    
    @ViewBuilder
    var loadingView: some View {
        VStack(spacing: 24) {
            progressView
            percentageText
        }
        .padding()
    }
    
    var progressView: some View {
        ProgressView(value: viewModel.importProgress) {
            Text(LocalizedStringKey("Importing flashcards..."))
                .font(.headline)
        }
        .progressViewStyle(.linear)
        .tint(Color.app(.accent_default))
    }
    
    var percentageText: some View {
        Text("\(Int(viewModel.importProgress * 100))%")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(Color.app(.accent_default))
    }
}

// MARK: - Success View
private extension CSVImportView {
    
    @ViewBuilder
    var successView: some View {
        VStack(spacing: 24) {
            successIcon
            successTitle
            successMessage
            doneButton
        }
    }
    
    var successIcon: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 64))
            .foregroundStyle(Color.app(.success))
    }
    
    var successTitle: some View {
        Text(LocalizedStringKey("Import Successful"))
            .font(.title2)
            .fontWeight(.semibold)
    }
    
    var successMessage: some View {
        Text("Imported \(viewModel.importedCount) flashcards")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
    
    var doneButton: some View {
        Button(action: {
            dismiss()
        }) {
            Text(LocalizedStringKey("Done"))
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.app(.accent_default))
                .foregroundStyle(.white)
                .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: - Helpers
private extension CSVImportView {
    
    func handleFileImport(_ result: Swift.Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            viewModel.importCSV(from: url, context: context)
            
        case .failure(let error):
            viewModel.errorMessage = error.localizedDescription
        }
    }
}

