enum ReviewFilter: String, CaseIterable, Identifiable {
	case all = "All"
	case wrong = "Wrong"
	case correct = "Correct"
	var id: String { rawValue }
}
