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
    init() {} // 提供默认构造器
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
    private let baseURL = "https://iosapi.musicasia.cn/prod-api" //"https://www.musicasia.cn/prod-api"
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60 // 请求超时改为 60s
        configuration.timeoutIntervalForResource = 120 // 资源超时改为 120s
        
        // 忽略 SSL 证书校验（针对测试环境或证书不匹配的情况）
        let serverTrustManager = ServerTrustManager(evaluators: [
            "iosapi.musicasia.cn": DisabledTrustEvaluator()
        ])
        
        self.session = Session(configuration: configuration, serverTrustManager: serverTrustManager)
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
 
        // 恢复默认的编码方式：GET 用 URLEncoding，POST 等用 JSONEncoding
        // 从最新的后端报错日志看，后端实际上确实期待 JSON 格式的请求体，所以不能强制转为 URLEncoding
        let encoding: ParameterEncoding = (method == .get) ? URLEncoding.default : JSONEncoding.default
        
        session.request(url, 
                        method: method, 
                        parameters: parameters, 
                        encoding: encoding, 
                        headers: commonHeaders())
            .validate(statusCode: 200..<300)
            .responseData { response in
                if let data = response.data, let str = String(data: data, encoding: .utf8) {
                    // 打印响应数据
                    print("🌐 API Response [\(endpoint)]: \(str)")
                }
                
                if let error = response.error {
                    if let underlyingError = error.underlyingError as? URLError {
                        if underlyingError.code == .timedOut {
                            completion(.failure(.serverError(statusCode: -1001, message: "网络请求超时，请检查网络后重试")))
                            return
                        } else if underlyingError.code == .notConnectedToInternet || underlyingError.code == .networkConnectionLost {
                            // 遇到真正的断网，不应该继续走下面的 decoding，应该直接返回一个友好的无网络提示，而不是让系统抛出英文的 URLError
                            completion(.failure(.serverError(statusCode: -1009, message: "当前网络连接不可用，请检查网络后重试")))
                            return
                        }
                    }
                    
                    var errorMsg = error.localizedDescription
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
                
                guard let data = response.data else {
                    completion(.failure(.noData))
                    return
                }
                
                do {
                    let baseResponse = try JSONDecoder().decode(BaseResponse<T>.self, from: data)
                    
                    if baseResponse.code == 401 {
                        self.handleTokenExpiration()
                        completion(.failure(.serverError(statusCode: 401, message: "Token 已过期，请重新登录")))
                        return
                    }
                    
                    if baseResponse.isSuccess {
                        if let bizData = baseResponse.data {
                            completion(.success(bizData))
                        } else if T.self == AnyDecodableValue.self, let dummy = AnyDecodableValue() as? T {
                            completion(.success(dummy))
                        } else if let emptyData = Optional<Any>.none as? T {
                            completion(.success(emptyData))
                        } else if let errorMsg = baseResponse.decodingErrorMsg {
                            completion(.failure(.serverError(statusCode: 200, message: "解析详情: \(errorMsg)")))
                        } else {
                            // 对于非 AnyDecodableValue 的泛型，如果确实没返回 data 则报错
                            completion(.failure(.noData))
                        }
                    } else {
                        completion(.failure(.serverError(statusCode: baseResponse.code, message: baseResponse.msg ?? "未知业务错误")))
                    }
                } catch {
                    print("❌ JSON 手动解析失败: \(error)")
                    completion(.failure(.decodingError))
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
    
    // 专门为 getInfo 提供的方法，因为它的数据包在 user 字段里而不是 data
    func requestUserInfo<T: Decodable>(_ endpoint: String, method: HTTPMethod = .get, parameters: [String: Any]? = nil, completion: @escaping (Result<T, NetworkError>) -> Void) {
        let url = baseURL + endpoint
        
        session.request(url,
                        method: method,
                        parameters: parameters,
                        encoding: URLEncoding.default,
                        headers: commonHeaders())
            .validate(statusCode: 200..<300)
            .responseData { response in
                if let data = response.data, let str = String(data: data, encoding: .utf8) {
                    print("🌐 API Response [\(endpoint)]: \(str)")
                }
            }
            .responseDecodable(of: UserInfoBaseResponse<T>.self) { response in
                if let error = response.error {
                    completion(.failure(.serverError(statusCode: response.response?.statusCode ?? 500, message: error.localizedDescription)))
                    return
                }
                
                guard let baseResponse = response.value else {
                    completion(.failure(.noData))
                    return
                }
                
                if baseResponse.isSuccess {
                    if let user = baseResponse.user {
                        completion(.success(user))
                    } else {
                        completion(.failure(.noData))
                    }
                } else {
                    completion(.failure(.serverError(statusCode: baseResponse.code, message: baseResponse.msg ?? "未知错误")))
                }
            }
    }
    
    /// 图片上传专属响应结构体（针对 /common/upload 接口字段）
    struct UploadResponse: Decodable {
        let code: Int
        let msg: String?
        let url: String?
        
        var isSuccess: Bool {
            return code == 200 || code == 0
        }
    }
    
    struct UserInfoBaseResponse<T: Decodable>: Decodable {
        let code: Int
        let msg: String?
        let user: T?
        
        var isSuccess: Bool {
            return code == 200 || code == 0
        }
    }
    
    /// 图片上传
    func uploadImage(_ image: UIImage, 
                     endpoint: String,
                     parameters: [String: Any]? = nil,
                     completion: @escaping (Result<String, NetworkError>) -> Void) {
        let urlString = endpoint.hasPrefix("http") ? endpoint : baseURL + endpoint
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        // 降低图片压缩质量以减小文件体积，加速上传
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(.failure(.noData))
            return
        }
        
        // 针对文件上传，如果后端不需要 JSON，我们需要覆盖 Content-Type，Alamofire的 upload 会自动处理 multipart
        var headers = commonHeaders()
        headers.remove(name: "Content-Type")
        
        session.upload(multipartFormData: { multipartFormData in
            // 追加图片数据
            multipartFormData.append(imageData, withName: "file", fileName: "upload.jpg", mimeType: "image/jpeg")
            
            // 追加其他参数
            if let params = parameters {
                for (key, value) in params {
                    if let stringValue = value as? String, let stringData = stringValue.data(using: .utf8) {
                        multipartFormData.append(stringData, withName: key)
                    } else if let intValue = value as? Int, let stringData = "\(intValue)".data(using: .utf8) {
                        multipartFormData.append(stringData, withName: key)
                    }
                }
            }
        }, to: url, method: .post, headers: headers)
        .validate(statusCode: 200..<300)
        .responseData { response in
            if let data = response.data, let str = String(data: data, encoding: .utf8) {
                print("🌐 API Upload Response [\(endpoint)]: \(str)")
            }
            
            if let error = response.error {
                // 如果网络超时，给予明确的提示
                if let underlyingError = error.underlyingError as? URLError, underlyingError.code == .timedOut {
                    completion(.failure(.serverError(statusCode: -1001, message: "图片上传超时，请检查网络后重试")))
                    return
                }
                
                if let statusCode = response.response?.statusCode {
                    if statusCode == 401 {
                        self.handleTokenExpiration()
                    }
                    completion(.failure(.serverError(statusCode: statusCode, message: "Upload Error: \(error.localizedDescription)")))
                } else {
                    completion(.failure(.unknown(error)))
                }
                return
            }
            
            guard let data = response.data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                // 使用专属的 UploadResponse 进行解析，因为它的图片地址字段是 url 而不是嵌套在 data 里的
                let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
                
                if uploadResponse.code == 401 {
                    self.handleTokenExpiration()
                    completion(.failure(.serverError(statusCode: 401, message: "Token 已过期，请重新登录")))
                    return
                }
                
                if uploadResponse.isSuccess {
                    if let urlString = uploadResponse.url {
                        completion(.success(urlString))
                    } else {
                        completion(.failure(.serverError(statusCode: 200, message: "上传成功但未返回图片地址")))
                    }
                } else {
                    completion(.failure(.serverError(statusCode: uploadResponse.code, message: uploadResponse.msg ?? "上传失败")))
                }
            } catch {
                completion(.failure(.decodingError))
            }
        }
    }
    
    private func handleTokenExpiration() {
        // 在主线程处理 Token 过期
        DispatchQueue.main.async {
            UserDefaults.standard.removeObject(forKey: "UserToken")
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
            UserDefaults.standard.removeObject(forKey: "UserRegisterType")
            
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
