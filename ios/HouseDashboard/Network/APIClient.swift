import Foundation

struct APIClient {
    static var baseURL: String {
        // Override in Settings bundle or build config for production
        UserDefaults.standard.string(forKey: "api_base_url") ?? "http://localhost:8000"
    }

    enum APIError: Error {
        case invalidURL
        case serverError(Int)
        case decodingError
    }

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    static func post<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body,
        as _: Response.Type
    ) async throws -> Response {
        guard let url = URL(string: "\(baseURL)\(path)") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw APIError.serverError(http.statusCode)
        }
        return try decoder.decode(Response.self, from: data)
    }

    static func get<Response: Decodable>(path: String, as _: Response.Type) async throws -> Response {
        guard let url = URL(string: "\(baseURL)\(path)") else { throw APIError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw APIError.serverError(http.statusCode)
        }
        return try decoder.decode(Response.self, from: data)
    }

    static func patch<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body,
        as _: Response.Type
    ) async throws -> Response {
        guard let url = URL(string: "\(baseURL)\(path)") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw APIError.serverError(http.statusCode)
        }
        return try decoder.decode(Response.self, from: data)
    }
}
