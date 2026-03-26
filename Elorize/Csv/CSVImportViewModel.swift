internal import Combine
import SwiftUI
import Foundation
import SwiftData
import UniformTypeIdentifiers

@MainActor
final class CSVImportViewModel: ObservableObject {
    @Published var isImporting = false
    @Published var showingFilePicker = false
    @Published var importedRows: [CSVImporter.CSVRow] = []
    @Published var errorMessage: String?
    @Published var showingPreview = false
    @Published var importProgress: Double = 0
    @Published var importComplete = false
    @Published var importedCount = 0
    
    /// Group rows by subject to show subjects that will be created
    var subjectPreview: [String: Int] {
        let grouped = Dictionary(grouping: importedRows) { $0.subject }
        return grouped.mapValues { $0.count }
    }
    
    /// Import CSV file
    func importCSV(from url: URL, context: ModelContext) {
        isImporting = true
        errorMessage = nil
        
        Task {
            do {
                guard url.startAccessingSecurityScopedResource() else {
                    throw CSVImporter.CSVError.invalidFormat
                }
                defer { url.stopAccessingSecurityScopedResource() }
                
                let data = try Data(contentsOf: url)
                let rows = try CSVImporter.parse(data)
                
                await MainActor.run {
                    self.importedRows = rows
                    self.showingPreview = true
                    self.isImporting = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isImporting = false
                }
            }
        }
    }
    
    /// Perform the actual import into SwiftData
    func performImport(context: ModelContext, onComplete: @escaping () -> Void) {
        isImporting = true
        importProgress = 0
        
        Task {
            let grouped = Dictionary(grouping: importedRows) { $0.subject }
            let totalCards = importedRows.count
            var processedCards = 0
            
            for (subjectName, rows) in grouped {
                let subjectEntity = await findOrCreateSubject(
                    name: subjectName, 
                    context: context
                )
                
                for row in rows {
                    let card = FlashCard(
                        front: row.question,
                        back: row.answer,
                        tags: [subjectName]
                    )
                    
                    let cardEntity = FlashCardEntity(from: card, subject: subjectEntity)
                    context.insert(cardEntity)
                    
                    processedCards += 1
                    await MainActor.run {
                        self.importProgress = Double(processedCards) / Double(totalCards)
                    }
                }
            }
            
            do {
                try context.save()
                await MainActor.run {
                    self.importedCount = totalCards
                    self.importComplete = true
                    self.isImporting = false
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    let message = "Failed to save: \(error.localizedDescription)"
                    self.errorMessage = message
                    self.isImporting = false
                }
            }
        }
    }
    
    /// Find existing subject or create a new one
    private func findOrCreateSubject(
        name: String, 
        context: ModelContext
    ) async -> SubjectEntity {
        let normalizedName = name.trimmingCharacters(in: .whitespaces)
        guard !normalizedName.isEmpty else {
            return await findOrCreateSubject(name: "Imported", context: context)
        }
        
        let descriptor = FetchDescriptor<SubjectEntity>(
            predicate: #Predicate { $0.name == normalizedName }
        )
        
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        
        let newSubject = SubjectEntity(
            id: UUID(), 
            name: normalizedName, 
            cards: []
        )
        context.insert(newSubject)
        return newSubject
    }
    
    /// Reset import state
    func reset() {
        importedRows = []
        errorMessage = nil
        showingPreview = false
        importProgress = 0
        importComplete = false
        importedCount = 0
    }
}
