import SwiftUI
import SwiftData

@main
struct ElorizeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SubjectEntity.self,
            FlashCardEntity.self,
            ReviewEventEntity.self,
            FlowerEntity.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Migrate existing ReviewEventEntity records from old schema
            // Old records will have quality = 0 (default), we update based on isCorrect
            Task { @MainActor in
                let context = container.mainContext
                let descriptor = FetchDescriptor<ReviewEventEntity>()
                
                if let events = try? context.fetch(descriptor) {
                    var migratedCount = 0
                    for event in events {
                        // Update quality for old records where quality is still 0
                        // New records will have quality set explicitly, so won't be 0
                        if event.quality == 0 && event.isCorrect {
                            event.quality = 5
                            migratedCount += 1
                        }
                    }
                    
                    if migratedCount > 0 {
                        try? context.save()
                        print("✅ Migrated \(migratedCount) review events to new quality system")
                    }
                }
            }
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
        .modelContainer(sharedModelContainer)
    }
}
