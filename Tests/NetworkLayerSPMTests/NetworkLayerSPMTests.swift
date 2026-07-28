import Testing
import Foundation
@testable import NetworkLayerSPM

private enum TestEndpoint: NetworkLayerURLBuilder {
    case valid
    case invalid

    func url() -> URL? {
        switch self {
        case .valid: URL(string: "https://example.com/data.json")
        case .invalid: nil
        }
    }
}

private struct SamplePayload: Decodable, Sendable, Equatable {
    let firstName: String
    let count: Int
}

@Suite
struct NetworkLayerRequestTests {
    @Test func buildsURLRequestWithMethodHeadersAndBody() throws {
        let request = NetworkLayerRequest(
            urlBuilder: TestEndpoint.valid,
            headers: ["Authorization": "Bearer token"],
            reqBody: ["hello": "world"],
            httpMethod: .POST
        )
        let url = try #require(TestEndpoint.valid.url())
        let urlRequest = request.buildURLRequest(with: url)

        #expect(urlRequest.httpMethod == "POST")
        #expect(urlRequest.allHTTPHeaderFields?["Authorization"] == "Bearer token")
        #expect(urlRequest.httpBody != nil)
        #expect(urlRequest.url == url)
    }
}

@Suite
struct NetworkLayerDecoderTests {
    @Test func defaultDecoderConvertsSnakeCase() throws {
        let data = Data(#"{"first_name":"Ada","count":3}"#.utf8)
        let decoded = try NetworkLayerUtils.defaultDecoder().decode(SamplePayload.self, from: data)
        #expect(decoded == SamplePayload(firstName: "Ada", count: 3))
    }

    @Test func decoderHonoursCustomKeyStrategy() {
        // With default keys, snake_case must NOT map to camelCase. Regression guard:
        // defaultDecoder previously ignored its parameter and always snake-cased.
        let data = Data(#"{"first_name":"Ada","count":3}"#.utf8)
        let decoder = NetworkLayerUtils.defaultDecoder(keyDecodingStrategy: .useDefaultKeys)
        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(SamplePayload.self, from: data)
        }
    }
}

@Suite
struct NetworkLayerExecutionTests {
    @Test func requestThrowsNetworkLayerErrorForInvalidURL() async {
        let request = NetworkLayerRequest(urlBuilder: TestEndpoint.invalid, httpMethod: .GET)
        await #expect(throws: NetworkLayerError.self) {
            let _: SamplePayload = try await NetworkLayer.defaultNetworkLayer.request(request)
        }
    }
}
