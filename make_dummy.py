import os

with open('DummyAlamofire/Alamofire.swift', 'w') as f:
    f.write('''import Foundation
public struct Session {
    public init(configuration: URLSessionConfiguration) {}
    public func request(_ url: Any, method: HTTPMethod, parameters: Any?, encoding: ParameterEncoding, headers: HTTPHeaders) -> DataRequest { return DataRequest() }
    public func download(_ url: Any, to: Any) -> DownloadRequest { return DownloadRequest() }
}
public struct DataRequest {
    public func validate(statusCode: Range<Int>) -> Self { return self }
    public func responseDecodable<T>(of type: T.Type, completionHandler: @escaping (AFDataResponse<T>) -> Void) {}
}
public struct DownloadRequest {
    public typealias Destination = (URL, HTTPURLResponse) -> (destinationURL: URL, options: DownloadOptions)
    public struct DownloadOptions: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let removePreviousFile = DownloadOptions(rawValue: 1)
        public static let createIntermediateDirectories = DownloadOptions(rawValue: 2)
    }
    public func downloadProgress(closure: @escaping (Progress) -> Void) -> Self { return self }
    public func response(completionHandler: @escaping (AFDownloadResponse<URL?>) -> Void) {}
}
public struct AFDataResponse<T> {
    public let error: Error? = nil
    public let response: HTTPURLResponse? = nil
    public let value: T? = nil
}
public struct AFDownloadResponse<T> {
    public let error: Error? = nil
    public let fileURL: URL? = nil
}
public typealias Parameters = [String: Any]
public struct HTTPHeaders: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, String)...) {}
    public mutating func add(name: String, value: String) {}
}
public enum HTTPMethod { case get, post }
public protocol ParameterEncoding {}
public struct URLEncoding: ParameterEncoding { public static let `default` = URLEncoding() }
public struct JSONEncoding: ParameterEncoding { public static let `default` = JSONEncoding() }
''')
