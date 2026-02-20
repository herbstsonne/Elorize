import Foundation
import SwiftData

final class FlashcardRepository {
  private let context: ModelContext

  init(context: ModelContext) {
    self.context = context
  }

  func save() {
    do {
      try context.save()
    } catch {
      // Handle save error appropriately (log, assertion, etc.)
      #if DEBUG
      print("FlashCardRepository save error: \(error)")
      #endif
    }
  }

  func commitSubjectEdit(_ subject: SubjectEntity, newName: String) {
    let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
    subject.name = trimmed
    try? context.save()
  }

  func deleteCards(at offsets: IndexSet, in cards: [FlashCardEntity]) {
    for index in offsets {
      let card = cards[index]
      context.delete(card)
    }
    try? context.save()
  }

  func deleteSubjects(at offsets: IndexSet, subjects: [SubjectEntity]) {
    for index in offsets {
      let subject = subjects[index]
      for card in subject.flashCardsArray {
        context.delete(card)
      }
      context.delete(subject)
    }
    try? context.save()
  }

  func saveNew(subject entity: SubjectEntity) {
    context.insert(entity)
    try? context.save()
  }

  func saveNew(flashCard entity: FlashCardEntity) {
    context.insert(entity)
    try? context.save()
  }
  
  func fetchEntity(forId id: UUID) -> FlashCardEntity? {
    var matchedEntity: FlashCardEntity?
    let descriptor = FetchDescriptor<FlashCardEntity>()
    if let entities = try? context.fetch(descriptor) {
      matchedEntity = entities.first(where: { entity in
        entity.id == id
      })
    }
    return matchedEntity
  }
}
