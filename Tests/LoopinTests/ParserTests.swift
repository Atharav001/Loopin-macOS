import XCTest
@testable import Loopin

final class ParserTests: XCTestCase {
    func testNaturalLanguageParserTimeRanges() {
        let cal = Calendar.current
        let today = Date()
        
        // Test "coding 2-4pm"
        let res1 = NaturalLanguageParser.parse(text: "coding 2-4pm", baseDate: today)
        XCTAssertEqual(res1.title, "coding")
        XCTAssertEqual(cal.component(.hour, from: res1.startAt), 14)
        XCTAssertEqual(cal.component(.hour, from: res1.endAt), 16)
        
        // Test "meeting 10am to 11am"
        let res2 = NaturalLanguageParser.parse(text: "meeting 10am to 11am", baseDate: today)
        XCTAssertEqual(res2.title, "meeting")
        XCTAssertEqual(cal.component(.hour, from: res2.startAt), 10)
        XCTAssertEqual(cal.component(.hour, from: res2.endAt), 11)
        
        // Test "lunch 12:30-1:30pm"
        let res3 = NaturalLanguageParser.parse(text: "lunch 12:30-1:30pm", baseDate: today)
        XCTAssertEqual(res3.title, "lunch")
        XCTAssertEqual(cal.component(.hour, from: res3.startAt), 12)
        XCTAssertEqual(cal.component(.minute, from: res3.startAt), 30)
        XCTAssertEqual(cal.component(.hour, from: res3.endAt), 13)
        XCTAssertEqual(cal.component(.minute, from: res3.endAt), 30)
    }
    
    func testClassifierEngineLongestMatch() {
        let rules: [ClassificationRule] = [
            ClassificationRule(phrase: "youtube", category: "YouTube Watching", productivity: "wasteful"),
            ClassificationRule(phrase: "youtube shorts", category: "YouTube Shorts", productivity: "wasteful"),
            ClassificationRule(phrase: "coding", category: "Coding", productivity: "productive")
        ]
        
        let match1 = ClassifierEngine.classify(text: "watching youtube shorts right now", rules: rules)
        XCTAssertNotNil(match1)
        XCTAssertEqual(match1?.category, "YouTube Shorts")
        
        let match2 = ClassifierEngine.classify(text: "swift coding session", rules: rules)
        XCTAssertNotNil(match2)
        XCTAssertEqual(match2?.category, "Coding")
        XCTAssertEqual(match2?.productivity, .productive)
    }
}
