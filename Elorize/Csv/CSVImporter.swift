import Foundation

/// Utility for parsing CSV files into flashcard data
struct CSVImporter {
    
    /// Represents a single row from the CSV
    struct CSVRow {
        let subject: String
        let question: String
        let answer: String
    }
    
    enum CSVError: LocalizedError, Equatable {
        case invalidFormat
        case missingHeaders
        case invalidRowData(line: Int)
        case emptyFile
        
        var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return String(localized: "Invalid CSV format")
            case .missingHeaders:
                return String(localized: "CSV must contain headers: Subject, Question, Answer")
            case .invalidRowData(let line):
                return String(localized: "Invalid data at line \(line)")
            case .emptyFile:
                return String(localized: "CSV file is empty")
            }
        }
    }
    
    /// Parse CSV data into rows
    /// - Parameter data: CSV file data
    /// - Returns: Array of parsed CSV rows
    static func parse(_ data: Data) throws -> [CSVRow] {
        guard let content = String(data: data, encoding: .utf8), !content.isEmpty else {
            throw CSVError.emptyFile
        }
        
        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard !lines.isEmpty else {
            throw CSVError.emptyFile
        }
        
        // Parse header
        let header = lines[0]
        let headerFields = parseCSVLine(header)
        
        // Validate headers (case-insensitive)
        let normalizedHeaders = headerFields.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
        guard normalizedHeaders.contains("subject"),
              normalizedHeaders.contains("question"),
              normalizedHeaders.contains("answer") else {
            throw CSVError.missingHeaders
        }
        
        // Find column indices
        guard let subjectIndex = normalizedHeaders.firstIndex(of: "subject"),
              let questionIndex = normalizedHeaders.firstIndex(of: "question"),
              let answerIndex = normalizedHeaders.firstIndex(of: "answer") else {
            throw CSVError.missingHeaders
        }
        
        // Parse data rows
        var rows: [CSVRow] = []
        for (index, line) in lines.dropFirst().enumerated() {
            let fields = parseCSVLine(line)
            
            guard fields.count > max(subjectIndex, questionIndex, answerIndex) else {
                throw CSVError.invalidRowData(line: index + 2) // +2 because of 0-index and header
            }
            
            let subject = fields[subjectIndex].trimmingCharacters(in: .whitespaces)
            let question = fields[questionIndex].trimmingCharacters(in: .whitespaces)
            let answer = fields[answerIndex].trimmingCharacters(in: .whitespaces)
            
            // Skip rows with empty essential fields
            guard !question.isEmpty && !answer.isEmpty else {
                continue
            }
            
            rows.append(CSVRow(subject: subject, question: question, answer: answer))
        }
        
        return rows
    }
    
    /// Parse a single CSV line, handling quoted fields
    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        var previousChar: Character?
        
        for char in line {
            if char == "\"" {
                if insideQuotes && previousChar == "\"" {
                    // Escaped quote
                    currentField.append(char)
                    previousChar = nil
                    continue
                }
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
            previousChar = char
        }
        
        // Add the last field
        fields.append(currentField)
        
        return fields.map { field in
            var cleaned = field.trimmingCharacters(in: .whitespaces)
            // Remove surrounding quotes if present
            if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") {
                cleaned = String(cleaned.dropFirst().dropLast())
            }
            // Replace escaped quotes
            cleaned = cleaned.replacingOccurrences(of: "\"\"", with: "\"")
            return cleaned
        }
    }
}
