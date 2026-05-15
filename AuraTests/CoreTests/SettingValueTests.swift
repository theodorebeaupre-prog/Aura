import XCTest
@testable import Aura

final class SettingValueTests: XCTestCase {
    func testCodableRoundTripForAllSupportedTypes() throws {
        let values: [SettingValue] = [
            .bool(true),
            .int(42),
            .double(0.125),
            .string("Dark")
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for value in values {
            let data = try encoder.encode(value)
            let decodedValue = try decoder.decode(SettingValue.self, from: data)
            XCTAssertEqual(decodedValue, value)
        }
    }
}
