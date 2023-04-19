//
//  NetworkLayer.swift
//
//  Created by Inti Albuquerque on 10/04/23.
//
import Foundation

protocol DecoderProtocol {
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable
}

protocol EncoderProtocol {
    func encode<T>(_ value: T) throws -> Data where T : Encodable
}
extension JSONDecoder: DecoderProtocol {}
extension JSONEncoder: EncoderProtocol {}

enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
}

enum NetworkLayerUtils {
    private static let decoder = JSONDecoder()
    static let encoder = JSONEncoder()
    static func defaultDecoder(
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase
    ) -> JSONDecoder {
        
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

extension Encodable {
    func encode(encoder: EncoderProtocol) -> Data? {
        return try? encoder.encode(self)
    }
}

struct NetworkLayerRequest {
    let url: String
    let headers: [String: String]?
    let body: Data?
    let requestTimeOut: Float?
    let httpMethod: HTTPMethod
    
    init(url: String,
                headers: [String: String]? = nil,
                reqBody: Encodable? = nil,
                reqTimeout: Float? = nil,
                httpMethod: HTTPMethod,
                encoder: EncoderProtocol = NetworkLayerUtils.encoder
    ) {
        self.url = url
        self.headers = headers
        self.body = reqBody?.encode(encoder: encoder)
        self.requestTimeOut = reqTimeout
        self.httpMethod = httpMethod
    }
    
    func buildURLRequest(with url: URL) -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethod.rawValue
        urlRequest.allHTTPHeaderFields = headers ?? [:]
        urlRequest.httpBody = body
        return urlRequest
    }
}

struct NetworkLayerError: Error {
    let title: String
    let message: String
}

protocol NetworkLayerProtocol {
    var requestTimeOut: Float { get }
    
    func request<ResponseType: Decodable>(_ req: NetworkLayerRequest, decoder: DecoderProtocol) async throws -> ResponseType
}

actor NetworkLayer: NetworkLayerProtocol {
    
    static let defaultNetworkLayer = NetworkLayer()
    
    let requestTimeOut: Float
    
    init(requestTimeOut: Float = 30) {
        self.requestTimeOut = requestTimeOut
    }
    
    func request<ResponseType: Decodable>(
        _ req: NetworkLayerRequest,
        decoder: DecoderProtocol = NetworkLayerUtils.defaultDecoder()) async throws -> ResponseType {
            
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = TimeInterval(req.requestTimeOut ?? requestTimeOut)
            
            guard let url = URL(string: req.url) else {
                throw NetworkLayerError(
                    title: "Invalid Url",
                    message: "The Url you are trying to call in not valid"
                )
            }
            let data = try await URLSession.shared.data(for: req.buildURLRequest(with: url))
            return try decoder.decode(ResponseType.self, from: data.0)
        }
}
