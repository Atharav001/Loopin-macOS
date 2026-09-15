import XCTest
@testable import Loopin

final class QuietHoursTests: XCTestCase {
    func testDaytimeQuietHoursRange() {
        // Quiet hours: 13:00 (780 min) to 15:00 (900 min)
        let startM = 13 * 60 // 780
        let endM = 15 * 60   // 900
        
        // Before range: 12:59 (779 min) -> False
        XCTAssertFalse(LoggingScheduler.evaluateQuietHours(nowMinutes: 779, startMinutes: startM, endMinutes: endM))
        
        // At start boundary: 13:00 (780 min) -> True
        XCTAssertTrue(LoggingScheduler.evaluateQuietHours(nowMinutes: 780, startMinutes: startM, endMinutes: endM))
        
        // Inside range: 14:00 (840 min) -> True
        XCTAssertTrue(LoggingScheduler.evaluateQuietHours(nowMinutes: 840, startMinutes: startM, endMinutes: endM))
        
        // At end boundary: 15:00 (900 min) -> False
        XCTAssertFalse(LoggingScheduler.evaluateQuietHours(nowMinutes: 900, startMinutes: startM, endMinutes: endM))
    }
    
    func testOvernightQuietHoursRange() {
        // Overnight quiet hours: 22:00 (1320 min) to 07:00 (420 min)
        let startM = 22 * 60 // 1320
        let endM = 7 * 60    // 420
        
        // Before overnight start: 21:59 (1319 min) -> False
        XCTAssertFalse(LoggingScheduler.evaluateQuietHours(nowMinutes: 1319, startMinutes: startM, endMinutes: endM))
        
        // Exactly at start: 22:00 (1320 min) -> True
        XCTAssertTrue(LoggingScheduler.evaluateQuietHours(nowMinutes: 1320, startMinutes: startM, endMinutes: endM))
        
        // Late night: 23:30 (1410 min) -> True
        XCTAssertTrue(LoggingScheduler.evaluateQuietHours(nowMinutes: 1410, startMinutes: startM, endMinutes: endM))
        
        // Midnight: 00:00 (0 min) -> True
        XCTAssertTrue(LoggingScheduler.evaluateQuietHours(nowMinutes: 0, startMinutes: startM, endMinutes: endM))
        
        // Early morning: 04:00 (240 min) -> True
        XCTAssertTrue(LoggingScheduler.evaluateQuietHours(nowMinutes: 240, startMinutes: startM, endMinutes: endM))
        
        // End boundary: 07:00 (420 min) -> False
        XCTAssertFalse(LoggingScheduler.evaluateQuietHours(nowMinutes: 420, startMinutes: startM, endMinutes: endM))
        
        // Daytime: 12:00 (720 min) -> False
        XCTAssertFalse(LoggingScheduler.evaluateQuietHours(nowMinutes: 720, startMinutes: startM, endMinutes: endM))
    }
}
