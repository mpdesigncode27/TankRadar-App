import Foundation
import Testing
@testable import TankRadar

struct FuelTypeTests {
    @Test func displayNamesGerman() {
        #expect(FuelType.e5.displayName == "Super E5")
        #expect(FuelType.e10.displayName == "Super E10")
        #expect(FuelType.diesel.displayName == "Diesel")
    }

    @Test func identifiableMatchesRawValue() {
        for fuel in FuelType.allCases {
            #expect(fuel.id == fuel.rawValue)
            #expect(fuel.tankerkoenigJSONKey == fuel.rawValue)
        }
    }

    @Test func codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for fuel in FuelType.allCases {
            let data = try encoder.encode(fuel)
            let decoded = try decoder.decode(FuelType.self, from: data)
            #expect(decoded == fuel)
        }
    }

    @Test func allCasesCount() {
        #expect(FuelType.allCases.count == 3)
    }
}
