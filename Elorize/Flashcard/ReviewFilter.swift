enum ReviewFilter: String, CaseIterable, Identifiable {
	case all = "All"
	case wrong = "Repeat"
	case correct = "Got it"
	var id: String { rawValue }
}
