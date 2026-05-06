import Foundation
import Testing
@testable import FuelNow

private final class FuelNowTestsBundleToken: NSObject {}

@Suite(.serialized)
struct TankerkoenigClientTests {
    @Test func fetchStationsSuccessDecodesFixture() async throws {
        let data = try loadFixture(named: "tankerkoenig-list-ok-sample")
        defer { MockURLProtocol.handler = nil }
        MockURLProtocol.handler = { request in
            let url = try #require(request.url)
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let client = TankerkoenigClient(apiKey: "test-uuid-key", session: mockSession())
        let stations = try await client.fetchStations(latitude: 52.53, longitude: 13.44, radiusKm: 5)

        #expect(stations.count == 1)
        let station = try #require(stations.first)
        #expect(station.name == "TOTAL BERLIN")
        #expect(station.price(for: .diesel) == 1.109)
    }

    @Test func fetchStationsEmptyListWhenOkNoStations() async throws {
        let body = Data(#"{"ok":true,"stations":[]}"#.utf8)
        defer { MockURLProtocol.handler = nil }
        MockURLProtocol.handler = { request in
            let url = try #require(request.url)
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, body)
        }

        let client = TankerkoenigClient(apiKey: "test-uuid-key", session: mockSession())
        let stations = try await client.fetchStations(latitude: 0, longitude: 0, radiusKm: 10)
        #expect(stations.isEmpty)
    }

    @Test func fetchStationsApiOkFalseThrows() async throws {
        let body = Data(#"{"ok":false,"message":"parameter error"}"#.utf8)
        defer { MockURLProtocol.handler = nil }
        MockURLProtocol.handler = { request in
            let url = try #require(request.url)
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, body)
        }

        let client = TankerkoenigClient(apiKey: "test-uuid-key", session: mockSession())

        do {
            _ = try await client.fetchStations(latitude: 1, longitude: 2, radiusKm: 5)
            Issue.record("Expected TankerkoenigClient.Failure")
        } catch let failure as TankerkoenigClient.Failure {
            guard case let .apiFailed(message) = failure else {
                Issue.record("Expected apiFailed, got \(failure)")
                return
            }
            #expect(message.contains("parameter"))
        }
    }

    @Test func fetchStationsRateLimitedThrows() async throws {
        defer { MockURLProtocol.handler = nil }
        MockURLProtocol.handler = { request in
            let url = try #require(request.url)
            let response = HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let client = TankerkoenigClient(apiKey: "test-uuid-key", session: mockSession())

        do {
            _ = try await client.fetchStations(latitude: 1, longitude: 2, radiusKm: 5)
            Issue.record("Expected TankerkoenigClient.Failure.rateLimited")
        } catch let failure as TankerkoenigClient.Failure {
            guard case .rateLimited = failure else {
                Issue.record("Expected rateLimited, got \(failure)")
                return
            }
        }
    }

    @Test func fetchStationsMalformedJSONThrowsDecoding() async throws {
        defer { MockURLProtocol.handler = nil }
        MockURLProtocol.handler = { request in
            let url = try #require(request.url)
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data("{".utf8))
        }

        let client = TankerkoenigClient(apiKey: "test-uuid-key", session: mockSession())

        do {
            _ = try await client.fetchStations(latitude: 1, longitude: 2, radiusKm: 5)
            Issue.record("Expected decoding failure")
        } catch let failure as TankerkoenigClient.Failure {
            guard case .decoding = failure else {
                Issue.record("Expected decoding, got \(failure)")
                return
            }
        }
    }

    @Test func fetchStationsRepositoryPlaceholderUUIDThrowsMissingAPIKey() async throws {
        defer { MockURLProtocol.handler = nil }
        MockURLProtocol.handler = { request in
            let url = try #require(request.url)
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"ok":true,"stations":[]}"#.utf8))
        }

        let client = TankerkoenigClient(apiKey: APIKeys.tankerkoenigRepositoryPlaceholderUUID, session: mockSession())

        do {
            _ = try await client.fetchStations(latitude: 1, longitude: 2, radiusKm: 5)
            Issue.record("Expected missingAPIKey")
        } catch let failure as TankerkoenigClient.Failure {
            guard case .missingAPIKey = failure else {
                Issue.record("Expected missingAPIKey, got \(failure)")
                return
            }
        }
    }

    @Test func apiFailedGermanKeyRevokedMessageIsClarified() {
        let failure = TankerkoenigClient.Failure.apiFailed(message: "Key existiert nicht oder ist deaktiviert")
        let desc = failure.errorDescription
        #expect(desc?.contains("API-Key") == true)
        #expect(desc?.contains("TAN-72") == true)
    }

    @Test func fetchStationsMissingAPIKeyThrows() async throws {
        defer { MockURLProtocol.handler = nil }
        MockURLProtocol.handler = { request in
            let url = try #require(request.url)
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"ok":true,"stations":[]}"#.utf8))
        }

        let client = TankerkoenigClient(apiKey: "PASTE_YOUR_KEY_HERE", session: mockSession())

        do {
            _ = try await client.fetchStations(latitude: 1, longitude: 2, radiusKm: 5)
            Issue.record("Expected missingAPIKey")
        } catch let failure as TankerkoenigClient.Failure {
            guard case .missingAPIKey = failure else {
                Issue.record("Expected missingAPIKey, got \(failure)")
                return
            }
        }
    }

    @Test func fetchStationsProxyModeOmitsApiKeyAndPreservesQuery() async throws {
        let body = Data(#"{"ok":true,"stations":[]}"#.utf8)
        defer { MockURLProtocol.handler = nil }
        MockURLProtocol.handler = { request in
            let url = try #require(request.url)
            #expect(url.host == "proxy.example.com")
            let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
            let names = try #require(components.queryItems?.map(\.name))
            #expect(names.contains("lat"))
            #expect(names.contains("lng"))
            #expect(names.contains("rad"))
            #expect(names.contains("type"))
            #expect(names.contains("sort"))
            #expect(names.contains("apikey") == false)
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, body)
        }

        let base = try #require(URL(string: "https://proxy.example.com"))
        let client = TankerkoenigClient(configuration: .proxy(baseURL: base), session: mockSession())
        _ = try await client.fetchStations(latitude: 52.5, longitude: 13.4, radiusKm: 10)
    }

    @Test func radiusIsClampedToAPIUpperBound() async throws {
        defer { MockURLProtocol.handler = nil }
        MockURLProtocol.handler = { request in
            let url = try #require(request.url)
            let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
            let rad = try #require(components.queryItems?.first(where: { $0.name == "rad" })?.value)
            #expect(rad == "25.000000")
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let body = Data(#"{"ok":true,"stations":[]}"#.utf8)
            return (response, body)
        }

        let client = TankerkoenigClient(apiKey: "test-uuid-key", session: mockSession())
        _ = try await client.fetchStations(latitude: 1, longitude: 2, radiusKm: 99)
    }

    private func loadFixture(named name: String) throws -> Data {
        let bundle = Bundle(for: FuelNowTestsBundleToken.self)
        let url = try #require(bundle.url(forResource: name, withExtension: "json"))
        return try Data(contentsOf: url)
    }

    private func mockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}

private final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?

    override static func canInit(with request: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
