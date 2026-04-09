import SwiftUI
import SwiftData

struct GardenView: View {
    @Environment(\.modelContext) private var context
    
    @Query(sort: \FlowerEntity.grownAt, order: .reverse)
    private var flowers: [FlowerEntity]
    
    // Grid layout
    private let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Garden stats
                        gardenStats
                        
                        // Flowers grid
                        if flowers.isEmpty {
                            emptyGardenView
                        } else {
                            flowersGrid
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("My Garden")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            deleteAllFlowers()
                        } label: {
                            Label("Clear Garden", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.green.opacity(0.1),
                Color.blue.opacity(0.05),
                Color.app(.background_primary)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var gardenStats: some View {
        HStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("\(flowers.count)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.app(.accent_default))
                
                Text(flowers.count == 1 ? "Flower" : "Flowers")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.app(.background_secondary).opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            VStack(spacing: 8) {
                Text("\(totalStudyMinutes)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.app(.accent_default))
                
                Text("Minutes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.app(.background_secondary).opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var emptyGardenView: some View {
        VStack(spacing: 16) {
            Text("🌱")
                .font(.system(size: 80))
                .padding(.top, 60)
            
            Text("Your garden is empty")
                .font(.title2.bold())
                .foregroundStyle(Color.app(.text_primary))
            
            Text("Complete study timers to grow flowers!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 40)
    }
    
    private var flowersGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Grass decoration
            grassDecoration
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(flowers) { flower in
                    FlowerCardView(flower: flower)
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteFlower(flower)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.app(.background_secondary).opacity(0.5))
        )
    }
    
    private var grassDecoration: some View {
        HStack(spacing: 4) {
            ForEach(0..<15, id: \.self) { _ in
                Text("🌾")
                    .font(.system(size: 20))
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var totalStudyMinutes: Int {
        flowers.reduce(0) { $0 + $1.studyDurationMinutes }
    }
    
    // MARK: - Actions
    
    private func deleteFlower(_ flower: FlowerEntity) {
        withAnimation {
            context.delete(flower)
            try? context.save()
        }
    }
    
    private func deleteAllFlowers() {
        withAnimation {
            flowers.forEach { context.delete($0) }
            try? context.save()
        }
    }
}

// MARK: - Flower Card View

struct FlowerCardView: View {
    let flower: FlowerEntity
    
    var body: some View {
        VStack(spacing: 8) {
            Text(flower.flowerType.emoji)
                .font(.system(size: 50))
                .shadow(radius: 2)
            
            Text(flower.flowerType.rawValue)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(formattedDate)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(flower.flowerType.color.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(flower.flowerType.color.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: flower.grownAt)
    }
}

#Preview {
    let container = try! ModelContainer(
        for: FlowerEntity.self,
        configurations: .init(isStoredInMemoryOnly: true)
    )
    
    // Add sample flowers
    let context = ModelContext(container)
    for _ in 0..<10 {
        let flower = FlowerEntity(
            flowerType: FlowerType.allCases.randomElement()!,
            studyDurationMinutes: 30
        )
        context.insert(flower)
    }
    try? context.save()
    
    return GardenView()
        .modelContainer(container)
}
