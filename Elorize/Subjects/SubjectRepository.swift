import Foundation
import SwiftData

protocol SubjectRepository {
	func delete(_ entity: SubjectEntity)
	func insert(_ entity: SubjectEntity) throws
	func save()
}

final class SwiftDataSubjectRepository: SubjectRepository {
	
	private let context: ModelContext
	
	init(context: ModelContext) {
		self.context = context
	}
	
	func delete(_ entity: SubjectEntity) {
		context.delete(entity)
	}
	
	func insert(_ entity: SubjectEntity) throws {
		context.insert(entity)
		try context.save()
	}
	
	func save() {
		do {
			try context.save()
		} catch {
			// Handle save error appropriately (log, assertion, etc.)
#if DEBUG
			print("SwiftDataSubjectRepository save error: \(error)")
#endif
		}
	}
}

