//
//  NetworkLayer.swift
//
//  Created by Inti Albuquerque on 10/04/23.
//
import Foundation

public protocol NetworkLayerURLBuilder {
    func url() -> URL?
}

public protocol DecoderProtocol {
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable
}

public protocol EncoderProtocol {
    func encode<T>(_ value: T) throws -> Data where T : Encodable
}
extension JSONDecoder: DecoderProtocol {}
extension JSONEncoder: EncoderProtocol {}

public enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
}

public enum NetworkLayerUtils {
    private static let decoder = JSONDecoder()
    public static let encoder = JSONEncoder()
    public static func defaultDecoder(
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

public struct NetworkLayerRequest {
    let urlBuilder: NetworkLayerURLBuilder
    let headers: [String: String]?
    let body: Data?
    let requestTimeOut: Float?
    let httpMethod: HTTPMethod
    
    public init(urlBuilder: NetworkLayerURLBuilder,
                headers: [String: String]? = nil,
                reqBody: Encodable? = nil,
                reqTimeout: Float? = nil,
                httpMethod: HTTPMethod,
                encoder: EncoderProtocol = NetworkLayerUtils.encoder
    ) {
        self.urlBuilder = urlBuilder
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

public struct NetworkLayerError: Error {
    let title: String
    let message: String
}

public protocol NetworkLayerProtocol {
    var requestTimeOut: Float { get }
    
    func request<ResponseType: Decodable>(_ req: NetworkLayerRequest, cachingPolicy: NSURLRequest.CachePolicy, decoder: DecoderProtocol) async throws -> ResponseType
}

public actor NetworkLayer: NetworkLayerProtocol {
    
    public static let defaultNetworkLayer = NetworkLayer()
    
    public let requestTimeOut: Float
    
    public init(requestTimeOut: Float = 30) {
        self.requestTimeOut = requestTimeOut
    }
    
    public func request<ResponseType: Decodable>(
        _ req: NetworkLayerRequest,
        cachingPolicy: NSURLRequest.CachePolicy,
        decoder: DecoderProtocol = NetworkLayerUtils.defaultDecoder()) async throws -> ResponseType {
            
            var sessionConfig = URLSessionConfiguration.default
            sessionConfig.requestCachePolicy = cachingPolicy
            sessionConfig.timeoutIntervalForRequest = TimeInterval(req.requestTimeOut ?? requestTimeOut)
            
            guard let url = req.urlBuilder.url() else {
                throw NetworkLayerError(
                    title: "Invalid Url",
                    message: "The Url you are trying to call in not valid"
                )
            }
            let data = try await URLSession.shared.data(for: req.buildURLRequest(with: url))
            return try decoder.decode(ResponseType.self, from: data.0)
        }
}
