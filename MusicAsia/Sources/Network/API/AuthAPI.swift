import Foundation
import Alamofire

struct LoginBody: Encodable {
    let username: String
    let code: String
}

struct PhoneRegisterBody: Encodable {
    var phone: String
    var code: String
    var registerType: String
    var area: String?
    var salesmanCode: String?
    var serviceCode: String?
    var companyName: String?
    var businessLicense: String?
    var companyPic1: String?
    var companyPic2: String?
    var companyPic3: String?
    var companyPic4: String?
}

struct ProvinceVO: Decodable {
    let id: String?
    let name: String?
}

struct AreaBySalesmanCodeResp: Decodable {
    let children: [ProvinceVO]?
}

class AuthAPI {
    
    // MARK: - 发送验证码
    static func sendLoginCode(phone: String, completion: @escaping (Result<String?, NetworkError>) -> Void) {
        sendCode(endpoint: APIService.Auth.sendCodeLogin, phone: phone, attempt: 1, completion: completion)
    }

    static func sendRegisterCode(phone: String, completion: @escaping (Result<String?, NetworkError>) -> Void) {
        sendCode(endpoint: APIService.Auth.sendCodeRegister, phone: phone, attempt: 1, completion: completion)
    }

    /// 统一发送验证码逻辑：首次请求偶发失败（后端冷启动 / 限流 / 连接预热）时自动重试，
    /// 避免「第一次发送失败、第二次才成功」的情况直接暴露给用户。
    private static func sendCode(endpoint: String, phone: String, attempt: Int, completion: @escaping (Result<String?, NetworkError>) -> Void) {
        let params: [String: Any] = ["phone": phone]
        NetworkManager.shared.request(endpoint, method: .post, parameters: params) { (result: Result<AnyDecodableValue, NetworkError>) in
            switch result {
            case .success:
                completion(.success("验证码发送成功"))
            case .failure(let error):
                if attempt < 3 && isTransientError(error) {
                    // 瞬时错误自动重试，最多 3 次，间隔递增，避免打断倒计时
                    let delay = 1.0 * Double(attempt)
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                        sendCode(endpoint: endpoint, phone: phone, attempt: attempt + 1, completion: completion)
                    }
                } else {
                    completion(.failure(error))
                }
            }
        }
    }

    /// 判断是否为可重试的瞬时错误（服务器 5xx、超时、网络不可用等）。
    /// 注意 401（未注册）等业务错误不重试，直接交由上层处理。
    private static func isTransientError(_ error: NetworkError) -> Bool {
        switch error {
        case .serverError(let statusCode, _):
            return statusCode >= 500 || statusCode == -1001 || statusCode == -1009
        case .unknown:
            return true
        default:
            return false
        }
    }

    // MARK: - 登录与注册
    static func login(phone: String, code: String, completion: @escaping (Result<String?, NetworkError>) -> Void) {
        let params: [String: Any] = ["username": phone, "code": code]
        NetworkManager.shared.request(APIService.Auth.login, method: .post, parameters: params, completion: completion)
    }
    
    static func register(body: PhoneRegisterBody, completion: @escaping (Result<String?, NetworkError>) -> Void) {
        // 由于这里需要传 JSON Body，我们可以手动转换成字典，或者让 NetworkManager 支持传入 Encodable
        do {
            let data = try JSONEncoder().encode(body)
            if let params = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                NetworkManager.shared.request(APIService.Auth.register, method: .post, parameters: params, completion: completion)
            }
        } catch {
            completion(.failure(.decodingError))
        }
    }
    
    // MARK: - 业务员获取地区
    static func getAreaBySalesmanCode(code: String, completion: @escaping (Result<AreaBySalesmanCodeResp, NetworkError>) -> Void) {
        let params: [String: Any] = ["salesmanCode": code]
        NetworkManager.shared.request(APIService.Auth.getArea, method: .get, parameters: params, completion: completion)
    }
}

