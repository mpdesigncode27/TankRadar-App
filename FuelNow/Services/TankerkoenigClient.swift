import Foundation

/// Tankerkönig JSON API — Umkreissuche (`list.php`).
///
/// Dokumentation: [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de/?page=info).
/// Für stabiles `Station`-Decoding wird **`type=all`** verwendet (getrennte Felder `e5`/`e10`/`diesel`).
///
/// **Architektur-Entscheidung (TAN-82, `docs/TANKERKOENIG_CACHING.md`):**
/// FuelNow spiegelt Tankerkönig-Daten **nicht** in eine eigene DB mit
/// periodischer Aktualisierung. Tankerkönig untersagt das im Free Tier
/// explizit und sperrt sonst den API-Key. Default bleibt **on-demand** über
/// diesen Client; Caching-Verbesserungen laufen über `StationStore`
/// (Region-Bucket-TTL: TAN-83) und einen Stammdaten-Cache (TAN-84).
/// Wer hier einen periodischen Server-Poller einbauen möchte, muss zuerst
/// die ADR revidieren.
///
/// **API-Key:** Im direkten Modus steckt der Key in der Anfrage (nicht „geheim“ im Binary).
/// Für Produktion ohne sichtbaren Key: ``TankerkoenigAPIConfiguration`` / Proxy — siehe `TankerkoenigAPIConfiguration.swift`.
actor TankerkoenigClient {
    enum Failure: Swift.Error, LocalizedError, Sendable {
        case missingAPIKey
        case invalidURL
        case network(URLError)
        case http(statusCode: Int)
        case rateLimited
        case apiFailed(message: String)
        case decoding(DecodingError)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                """
                Tankerkönig API-Key fehlt oder ist noch der Platzhalter — TAN-72 / APIKeys, \
                oder einen Proxy setzen (TankerkoenigProxyBaseURL / TANKERKOENIG_PROXY_BASE_URL).
                """
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            case .invalidURL:
                "Ungültige Anfrage-URL für Tankerkönig list.php."
            case let .network(err):
                err.localizedDescription
            case let .http(code):
                "HTTP \(code) von Tankerkönig."
            case .rateLimited:
                "Tankerkönig API hat mit zu vielen Anfragen geantwortet (HTTP 429). Bitte später erneut versuchen."
            case let .apiFailed(message):
                TankerkoenigClient.userFacingTankerkoenigApiMessage(message)
            case let .decoding(err):
                err.localizedDescription
            }
        }
    }

    nonisolated private struct ListResponse: Decodable {
        let ok: Bool
        let stations: [Station]?
        let message: String?
    }

    private let configuration: TankerkoenigAPIConfiguration
    private let session: URLSession

    /// Standard: Proxy falls konfiguriert, sonst direkt mit ``APIKeys``.
    init(session: URLSession = .shared) {
        self.init(configuration: .resolved(), session: session)
    }

    /// Direkter Modus mit festem Key (Tests, Tools).
    init(apiKey: String, session: URLSession = .shared) {
        self.init(configuration: .direct(apiKey: apiKey), session: session)
    }

    init(configuration: TankerkoenigAPIConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    /// Lädt Tankstellen im Radius um einen Punkt (`list.php`).
    /// - Parameter radiusKm: wird auf **1…25 km** begrenzt (API-Maximum).
    func fetchStations(latitude: Double, longitude: Double, radiusKm: Double) async throws -> [Station] {
        let rad = min(max(radiusKm, 1), 25)

        let url: URL
        switch configuration {
        case .direct(let apiKey):
            let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard APIKeys.isConfiguredTankerkoenigKey(trimmedKey) else {
                throw Failure.missingAPIKey
            }
            url = try Self.makeListURL(
                host: "creativecommons.tankerkoenig.de",
                apiKey: trimmedKey,
                latitude: latitude,
                longitude: longitude,
                radKm: rad
            )
        case .proxy(let baseURL):
            let pathURL = baseURL.appendingPathComponent("json").appendingPathComponent("list.php")
            url = try Self.makeListURL(hostFromAbsoluteURL: pathURL, apiKey: nil, latitude: latitude, longitude: longitude, radKm: rad)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            throw Failure.network(urlError)
        } catch {
            throw Failure.network(URLError(.unknown))
        }

        guard let http = response as? HTTPURLResponse else {
            throw Failure.http(statusCode: -1)
        }

        switch http.statusCode {
        case 200:
            break
        case 429:
            throw Failure.rateLimited
        default:
            throw Failure.http(statusCode: http.statusCode)
        }

        let decoded: ListResponse
        do {
            decoded = try JSONDecoder().decode(ListResponse.self, from: data)
        } catch let err as DecodingError {
            throw Failure.decoding(err)
        } catch {
            throw Failure.decoding(
                DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: String(describing: error)))
            )
        }

        guard decoded.ok else {
            let msg = decoded.message.flatMap { raw -> String? in
                let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                return t.isEmpty ? nil : t
            }
            throw Failure.apiFailed(message: msg ?? "Tankerkönig API meldet ok=false ohne Nachricht.")
        }

        return decoded.stations ?? []
    }

    nonisolated private static func makeListURL(
        host: String,
        apiKey: String?,
        latitude: Double,
        longitude: Double,
        radKm: Double
    ) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "/json/list.php"
        components.queryItems = listQueryItems(latitude: latitude, longitude: longitude, radKm: radKm, apiKey: apiKey)
        guard let url = components.url else {
            throw Failure.invalidURL
        }
        return url
    }

    /// Baut eine URL aus einer bereits absoluten Basis (Proxy), inkl. Pfad `…/json/list.php`.
    nonisolated private static func makeListURL(
        hostFromAbsoluteURL absolute: URL,
        apiKey: String?,
        latitude: Double,
        longitude: Double,
        radKm: Double
    ) throws -> URL {
        guard var components = URLComponents(url: absolute, resolvingAgainstBaseURL: false) else {
            throw Failure.invalidURL
        }
        components.queryItems = listQueryItems(latitude: latitude, longitude: longitude, radKm: radKm, apiKey: apiKey)
        guard let url = components.url else {
            throw Failure.invalidURL
        }
        return url
    }

    nonisolated private static func listQueryItems(
        latitude: Double,
        longitude: Double,
        radKm: Double,
        apiKey: String?
    ) -> [URLQueryItem] {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "lat", value: formatCoordinate(latitude)),
            URLQueryItem(name: "lng", value: formatCoordinate(longitude)),
            URLQueryItem(name: "rad", value: formatCoordinate(radKm)),
            URLQueryItem(name: "type", value: "all"),
            URLQueryItem(name: "sort", value: "dist"),
        ]
        if let apiKey {
            items.append(URLQueryItem(name: "apikey", value: apiKey))
        }
        return items
    }

    nonisolated private static func formatCoordinate(_ value: Double) -> String {
        String(format: "%.6f", value)
    }

    /// Tankerkönig liefert u. a. deutschsprachige Key-Fehler; für Siri/Kurzbefehle klarere Hinweise.
    nonisolated private static func userFacingTankerkoenigApiMessage(_ message: String) -> String {
        let lower = message.lowercased()
        if lower.contains("key existiert nicht"), lower.contains("deaktiviert") {
            return """
            Der Tankerkönig-API-Key wird von der API abgelehnt (ungültig oder deaktiviert). \
            Bitte einen gültigen Key hinterlegen — README und Linear TAN-72.
            """
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return message
    }
}
