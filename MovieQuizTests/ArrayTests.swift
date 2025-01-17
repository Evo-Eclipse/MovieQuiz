import XCTest
@testable import MovieQuiz

final class ArrayTests: XCTestCase {
    func testGetValueInRange() throws {
        // Given
        let array = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]

        // When
        let val = array[safe: 2]

        // Then
        XCTAssertNotNil(val)
        XCTAssertEqual(val, 5)
    }

    func testGetValueOutOfRange() throws {
        // Given
        let array = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]

        // When
        let val = array[safe: 10]

        // Then
        XCTAssertNil(val)
    }
}
