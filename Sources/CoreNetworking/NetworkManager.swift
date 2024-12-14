//
//  NetworkManager.swift
//  DoorDashPrep
//
//  Created by Anton Bezlyudnyy on 10/30/24.
//

import Foundation

public protocol NetworkManagerImpl {
     func makeRequest<T: Decodable>(session: URLSession,
                                   url: URL?,
                                   method: NetworkManager.HTTPMethod,
                                   body: [String : String]?,
                                   headers: [String: String]?,
                                   responseType: T.Type) async throws -> T?
}

public class NetworkManager: NetworkManagerImpl {
    public enum HTTPMethod: String {
        case GET
        case POST
        case PUT
        case DELETE
        case PATCH
    }
    
    public func makeRequest<T: Decodable>(session: URLSession = .shared,
                        url: URL?,
                        method: HTTPMethod = .GET,
                        body: [String : String]? = nil,
                        headers: [String : String]? = nil,
                        responseType: T.Type) async throws -> T?  {
        guard let url = url else {
            throw NetworkingError.inValidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        do {
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode){
                throw NetworkingError.invalidStatusCode(code: httpResponse.statusCode)
            }
            
            guard !data.isEmpty else {
                return nil
            }
            
            if responseType == Data.self {
                return data as? T
            }
            
            let decodedResponse = try JSONDecoder().decode(T.self, from: data)
            return decodedResponse
        } catch _ as DecodingError {
            throw NetworkingError.failedToDecode
        } catch {
            throw NetworkingError.custom(error: error)
        }
        
    }
}

extension NetworkManager {
    public enum NetworkingError: LocalizedError {
        case inValidURL
        case invalidStatusCode(code: Int)
        case invalidData
        case failedToDecode
        case custom(error: Error)
    }
}

extension NetworkManager.NetworkingError {
    public var errorDescription: String? {
        switch self {
        case .inValidURL:
            return "URL isn't valid"
        case .invalidStatusCode:
            return "Invalid status code"
        case .invalidData:
            return "Response is invalid"
        case .failedToDecode:
            return "Failed to decode"
        case .custom(let error):
            return "Something went wrong: \(error.localizedDescription)"
        }
    }
}

