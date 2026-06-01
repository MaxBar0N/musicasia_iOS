import Foundation
import Alamofire
import UIKit

/// 自定义网络错误枚举
enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(statusCode: Int, message: String)
    case unknown(Error)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL: return "无效的 URL"
        case .noData: return "未返回任何数据"
        case .decodingError: return "数据解析失败"
        case .serverError(let code, let msg): return "服务器错误 [\(code)]: \(msg)"
        case .unknown(let error): return "未知错误: \(error.localizedDescription)"
        }
    }
}

/// 基础的响应数据结构，根据您的实际后端结构进行调整
struct BaseResponse<T: Decodable>: Decodable {
    var code: Int
    let msg: String?
    let data: T?
    var decodingErrorMsg: String?
    
    var isSuccess: Bool {
        return code == 200 || code == 0 // 假设 200 或 0 是成功状态码
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let codeInt = try? container.decodeIfPresent(Int.self, forKey: .code) {
            code = codeInt
        } else if let codeStr = try? container.decodeIfPresent(String.self, forKey: .code), let codeInt = Int(codeStr) {
            code = codeInt
        } else {
            code = -1
        }
        
        msg = try? container.decodeIfPresent(String.self, forKey: .msg)
        
        do {
            data = try container.decodeIfPresent(T.self, forKey: .data)
            decodingErrorMsg = nil
        } catch {
            print("❌ BaseResponse Data Decoding Error: \(error)")
            decodingErrorMsg = "\(error)"
            data = nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case code, msg, data
    }
}

/// 忽略任意类型的 data 数据
struct AnyDecodableValue: Decodable {
    init(from decoder: Decoder) throws {}
}

/// 带有分页信息的响应结构
struct BasePageResponse<T: Decodable>: Decodable {
    var code: Int
    let msg: String?
    let data: T?
    var decodingErrorMsg: String?
    let pageIndex: Int?
    let pageSize: Int?
    let total: Int?
    
    var isSuccess: Bool {
        return code == 200 || code == 0
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let codeInt = try? container.decodeIfPresent(Int.self, forKey: .code) {
            code = codeInt
        } else if let codeStr = try? container.decodeIfPresent(String.self, forKey: .code), let codeInt = Int(codeStr) {
            code = codeInt
        } else {
            code = -1
        }
        
        msg = try? container.decodeIfPresent(String.self, forKey: .msg)
        
        do {
            data = try container.decodeIfPresent(T.self, forKey: .data)
            decodingErrorMsg = nil
        } catch {
            print("❌ BasePageResponse Data Decoding Error: \(error)")
            decodingErrorMsg = "\(error)"
            data = nil
        }
        pageIndex = try? container.decodeIfPresent(Int.self, forKey: .pageIndex)
        pageSize = try? container.decodeIfPresent(Int.self, forKey: .pageSize)
        total = try? container.decodeIfPresent(Int.self, forKey: .total)
    }
    
    enum CodingKeys: String, CodingKey {
        case code, msg, data, pageIndex, pageSize, total
    }
}

/// 网络请求统一封装类
class NetworkManager {
    static let shared = NetworkManager()
    
    // 自定义 Session，可配置超时时间、请求头拦截器等
    private let session: Session
    
    // 全局基础 URL
    private let baseURL = "http://47.243.180.202:48080"
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30 // 请求超时 30s
        configuration.timeoutIntervalForResource = 60 // 资源超时 60s
        self.session = Session(configuration: configuration)
    }
    
    /// 获取通用的 HTTP Headers (例如 Token, User-Agent 等)
    private func commonHeaders() -> HTTPHeaders {
        var headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        // 如果有 Token，在这里统一添加
        if let token = UserDefaults.standard.string(forKey: "UserToken") {
            // Swagger 文档未明确指定 Token 的 Header 字段名，常用 "Authorization" 或 "token"
            // 假设后端使用 Authorization: Bearer {token} 或者是 header("token")
            headers.add(name: "Authorization", value: "Bearer \(token)")
            headers.add(name: "token", value: token) // 保底兼容
        }
        return headers
    }
    
    /// 核心请求方法，支持泛型解析并处理业务状态码
    /// - Parameters:
    ///   - endpoint: 接口路径，例如 "/songs/list"
    ///   - method: HTTP 方法，默认 GET
    ///   - parameters: 请求参数
    ///   - completion: 完成回调，返回业务数据 T 或 NetworkError
    func request<T: Decodable>(_ endpoint: String, 
                               method: HTTPMethod = .get, 
                               parameters: Parameters? = nil, 
                               completion: @escaping (Result<T, NetworkError>) -> Void) {
        
        let urlString = endpoint.hasPrefix("http") ? endpoint : baseURL + endpoint
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        // 判断参数编码方式：GET 用 URLEncoding，POST 等用 JSONEncoding
        let encoding: ParameterEncoding = (method == .get) ? URLEncoding.default : JSONEncoding.default
        
        session.request(url, 
                        method: method, 
                        parameters: parameters, 
                        encoding: encoding, 
                        headers: commonHeaders())
            .validate(statusCode: 200..<300)
            .responseData { response in
                if let data = response.data, let str = String(data: data, encoding: .utf8) {
                    print("🌐 API Response [\(endpoint)]: \(str)")
                }
            }
            .responseDecodable(of: BaseResponse<T>.self) { response in
                
                // 1. 处理网络层错误 (如 404, 500, 断网)
                if let error = response.error {
                    // 尝试打印出最真实的解析失败原因
                    var errorMsg = error.localizedDescription
                    if case let .responseSerializationFailed(reason) = error,
                       case let .decodingFailed(decodingError) = reason {
                        errorMsg = "解析失败: \(decodingError)"
                        print("❌ JSON 解析严重失败: \(decodingError)")
                    }
                    
                    if let statusCode = response.response?.statusCode {
                        if statusCode == 401 {
                            self.handleTokenExpiration()
                        }
                        completion(.failure(.serverError(statusCode: statusCode, message: "HTTP Error: \(errorMsg)")))
                    } else {
                        completion(.failure(.unknown(error)))
                    }
                    return
                }
                
                // 2. 处理业务层数据
                guard let baseResponse = response.value else {
                    completion(.failure(.decodingError))
                    return
                }
                
                if baseResponse.code == 401 {
                    self.handleTokenExpiration()
                    completion(.failure(.serverError(statusCode: 401, message: "Token 已过期，请重新登录")))
                    return
                }
                
                // 3. 校验业务状态码 (如 code == 200)
                if baseResponse.isSuccess {
                    if let data = baseResponse.data {
                        completion(.success(data))
                    } else if let emptyData = Optional<Any>.none as? T {
                        // 支持 T 为 Optional 且 JSON 中 data 为 null 或缺失的情况
                        completion(.success(emptyData))
                    } else if let errorMsg = baseResponse.decodingErrorMsg {
                        completion(.failure(.serverError(statusCode: 200, message: "解析详情: \(errorMsg)")))
                    } else {
                        completion(.failure(.noData))
                    }
                } else {
                    completion(.failure(.serverError(statusCode: baseResponse.code, message: baseResponse.msg ?? "未知业务错误")))
                }
            }
    }
    
    /// 专门处理分页结构的请求
    func requestPage<T: Decodable>(_ endpoint: String,
                                   method: HTTPMethod = .get,
                                   parameters: Parameters? = nil,
                                   completion: @escaping (Result<BasePageResponse<T>, NetworkError>) -> Void) {
        let urlString = endpoint.hasPrefix("http") ? endpoint : baseURL + endpoint
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        let encoding: ParameterEncoding = (method == .get) ? URLEncoding.default : JSONEncoding.default
        
        session.request(url,
                        method: method,
                        parameters: parameters,
                        encoding: encoding,
                        headers: commonHeaders())
            .validate(statusCode: 200..<300)
            .responseData { response in
                if let data = response.data, let str = String(data: data, encoding: .utf8) {
                    print("🌐 API Page Response [\(endpoint)]: \(str)")
                }
            }
            .responseDecodable(of: BasePageResponse<T>.self) { response in
                if let error = response.error {
                    var errorMsg = error.localizedDescription
                    if case let .responseSerializationFailed(reason) = error,
                       case let .decodingFailed(decodingError) = reason {
                        errorMsg = "解析失败: \(decodingError)"
                        print("❌ JSON 分页解析严重失败: \(decodingError)")
                    }
                    if let statusCode = response.response?.statusCode {
                        if statusCode == 401 {
                            self.handleTokenExpiration()
                        }
                        completion(.failure(.serverError(statusCode: statusCode, message: "HTTP Error: \(errorMsg)")))
                    } else {
                        completion(.failure(.unknown(error)))
                    }
                    return
                }
                
                guard let baseResponse = response.value else {
                    completion(.failure(.decodingError))
                    return
                }
                
                if baseResponse.code == 401 {
                    self.handleTokenExpiration()
                    completion(.failure(.serverError(statusCode: 401, message: "Token 已过期，请重新登录")))
                    return
                }
                
                if baseResponse.isSuccess {
                    if let _ = baseResponse.data {
                        completion(.success(baseResponse))
                    } else if let errorMsg = baseResponse.decodingErrorMsg {
                        completion(.failure(.serverError(statusCode: 200, message: "解析详情: \(errorMsg)")))
                    } else {
                        completion(.success(baseResponse)) // 容错处理
                    }
                } else {
                    completion(.failure(.serverError(statusCode: baseResponse.code, message: baseResponse.msg ?? "未知业务错误")))
                }
        }
    }
    
    /// 极简 API 供 Swift 5.5+ async/await 调用 (推荐使用)
    func requestAsync<T: Decodable>(_ endpoint: String, 
                                    method: HTTPMethod = .get, 
                                    parameters: Parameters? = nil) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            request(endpoint, method: method, parameters: parameters) { (result: Result<T, NetworkError>) in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 文件下载封装，支持断点续传的拓展基础
    func downloadFile(from url: String, 
                      fileName: String? = nil,
                      progressHandler: ((Double) -> Void)? = nil,
                      completion: @escaping (Result<URL, NetworkError>) -> Void) {
        
        let destination: DownloadRequest.Destination = { _, response in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let name = fileName ?? response.suggestedFilename ?? "downloaded_file"
            let fileURL = documentsURL.appendingPathComponent(name)
            // 覆盖旧文件并创建中间目录
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        session.download(url, to: destination)
            .downloadProgress { progress in
                // 在主线程回调进度
                DispatchQueue.main.async {
                    progressHandler?(progress.fractionCompleted)
                }
            }
            .response { response in
                if let error = response.error {
                    completion(.failure(.unknown(error)))
                } else if let fileURL = response.fileURL {
                    completion(.success(fileURL))
                } else {
                    completion(.failure(.noData))
                }
            }
    }
    
    private func handleTokenExpiration() {
        // 在主线程处理 Token 过期
        DispatchQueue.main.async {
            UserDefaults.standard.removeObject(forKey: "UserToken")
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
            
            // 切换到登录页
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                // 如果当前已经在登录页，就不要再重复弹了
                if let rootNav = window.rootViewController as? UINavigationController,
                   rootNav.viewControllers.first is LoginViewController {
                    return
                }
                
                let loginNav = UINavigationController(rootViewController: LoginViewController())
                window.rootViewController = loginNav
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
            }
        }
    }
}
