import Testing
import Foundation
@testable import Elorize

@Suite("CSV Importer Tests")
struct CSVImporterTests {
    
    @Test("Parse valid CSV with headers")
    func parseValidCSV() throws {
        let csvContent = """
        Chapter,Question,Answer
        Math,What is 2+2?,4
        Science,What is H2O?,Water
        """
        
        let data = csvContent.data(using: .utf8)!
        let rows = try CSVImporter.parse(data)
        
        #expect(rows.count == 2)
        #expect(rows[0].chapter == "Math")
        #expect(rows[0].question == "What is 2+2?")
        #expect(rows[0].answer == "4")
        #expect(rows[1].chapter == "Science")
        #expect(rows[1].question == "What is H2O?")
        #expect(rows[1].answer == "Water")
    }
    
    @Test("Parse CSV with quoted fields containing commas")
    func parseQuotedFields() throws {
        let csvContent = """
        Chapter,Question,Answer
        ML,Why calculus?,"Functions map inputs to outputs (e.g. temperature, wind)"
        """
        
        let data = csvContent.data(using: .utf8)!
        let rows = try CSVImporter.parse(data)
        
        #expect(rows.count == 1)
        #expect(rows[0].chapter == "ML")
        #expect(rows[0].question == "Why calculus?")
        #expect(rows[0].answer == "Functions map inputs to outputs (e.g. temperature, wind)")
    }
    
    @Test("Parse CSV with escaped quotes")
    func parseEscapedQuotes() throws {
        let csvContent = """
        Chapter,Question,Answer
        Grammar,What is a quote?,"Use ""quotation marks"" to quote"
        """
        
        let data = csvContent.data(using: .utf8)!
        let rows = try CSVImporter.parse(data)
        
        #expect(rows.count == 1)
        #expect(rows[0].answer == "Use \"quotation marks\" to quote")
    }
    
    @Test("Parse CSV with empty chapter")
    func parseEmptyChapter() throws {
        let csvContent = """
        Chapter,Question,Answer
        ,What is this?,A question without chapter
        """
        
        let data = csvContent.data(using: .utf8)!
        let rows = try CSVImporter.parse(data)
        
        #expect(rows.count == 1)
        #expect(rows[0].chapter.isEmpty)
        #expect(rows[0].question == "What is this?")
    }
    
    @Test("Skip rows with empty questions")
    func skipEmptyQuestions() throws {
        let csvContent = """
        Chapter,Question,Answer
        Math,,No question here
        Math,What is pi?,3.14159
        """
        
        let data = csvContent.data(using: .utf8)!
        let rows = try CSVImporter.parse(data)
        
        #expect(rows.count == 1)
        #expect(rows[0].question == "What is pi?")
    }
    
    @Test("Skip rows with empty answers")
    func skipEmptyAnswers() throws {
        let csvContent = """
        Chapter,Question,Answer
        Math,What is pi?,
        Math,What is e?,2.71828
        """
        
        let data = csvContent.data(using: .utf8)!
        let rows = try CSVImporter.parse(data)
        
        #expect(rows.count == 1)
        #expect(rows[0].question == "What is e?")
    }
    
    @Test("Parse case-insensitive headers")
    func parseCaseInsensitiveHeaders() throws {
        let csvContent = """
        CHAPTER,QUESTION,ANSWER
        Math,2+2=?,4
        """
        
        let data = csvContent.data(using: .utf8)!
        let rows = try CSVImporter.parse(data)
        
        #expect(rows.count == 1)
        #expect(rows[0].chapter == "Math")
    }
    
    @Test("Parse headers with extra whitespace")
    func parseHeadersWithWhitespace() throws {
        let csvContent = """
          Chapter  ,  Question  ,  Answer  
        Math,2+2=?,4
        """
        
        let data = csvContent.data(using: .utf8)!
        let rows = try CSVImporter.parse(data)
        
        #expect(rows.count == 1)
    }
    
    @Test("Throw error on empty file")
    func throwErrorOnEmptyFile() throws {
        let csvContent = ""
        let data = csvContent.data(using: .utf8)!
        
        #expect(throws: CSVImporter.CSVError.emptyFile) {
            try CSVImporter.parse(data)
        }
    }
    
    @Test("Throw error on missing headers")
    func throwErrorOnMissingHeaders() throws {
        let csvContent = """
        Wrong,Headers,Here
        Math,2+2=?,4
        """
        
        let data = csvContent.data(using: .utf8)!
        
        #expect(throws: CSVImporter.CSVError.missingHeaders) {
            try CSVImporter.parse(data)
        }
    }
    
    @Test("Parse CSV with newlines in data")
    func parseMultipleRows() throws {
        let csvContent = """
        Chapter,Question,Answer
        Chapter 1,Q1,A1
        Chapter 1,Q2,A2
        Chapter 2,Q3,A3
        
        Chapter 2,Q4,A4
        """
        
        let data = csvContent.data(using: .utf8)!
        let rows = try CSVImporter.parse(data)
        
        #expect(rows.count == 4)
        #expect(rows[0].chapter == "Chapter 1")
        #expect(rows[1].chapter == "Chapter 1")
        #expect(rows[2].chapter == "Chapter 2")
        #expect(rows[3].chapter == "Chapter 2")
    }
    
    @Test("Parse CSV with Unicode characters")
    func parseUnicodeCharacters() throws {
        let csvContent = """
        Chapter,Question,Answer
        Math,What is pi?,π ≈ 3.14159
        Chemistry,Water formula?,H₂O
        Language,How to say hello in French?,Bonjour
        Emoji,What is a thumbs up?,👍
        """
        
        let data = csvContent.data(using: .utf8)!
        let rows = try CSVImporter.parse(data)
        
        #expect(rows.count == 4)
        #expect(rows[0].answer == "π ≈ 3.14159")
        #expect(rows[1].answer == "H₂O")
        #expect(rows[2].answer == "Bonjour")
        #expect(rows[3].answer == "👍")
    }
    
    @Test("Parse real-world example")
    func parseRealWorldExample() throws {
        let csvContent = """
        Chapter,Question,Answer
        Chapter 1 – Motivation,Why do we need multidimensional calculus for machine learning?,"Real-world functions map multiple inputs to multiple outputs (e.g. temperature fields, wind velocity, profit depending on many variables). Neural networks involve compositions of such functions with millions of parameters, requiring differentiation in high dimensions."
        """
        
        let data = csvContent.data(using: .utf8)!
        let rows = try CSVImporter.parse(data)
        
        #expect(rows.count == 1)
        #expect(rows[0].chapter == "Chapter 1 – Motivation")
        #expect(rows[0].question == "Why do we need multidimensional calculus for machine learning?")
        #expect(rows[0].answer.contains("Real-world functions"))
        #expect(rows[0].answer.contains("temperature fields"))
    }
}
