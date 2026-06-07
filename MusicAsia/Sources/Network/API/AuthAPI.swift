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
        let params: [String: Any] = ["phone": phone]
        // 尝试发送到新接口，如果失败也可以在此处配置自动 fallback 到另一个接口，但建议跟后端沟通确认统一的接口
        NetworkManager.shared.request(APIService.Auth.sendCodeLogin, method: .post, parameters: params) { (result: Result<AnyDecodableValue, NetworkError>) in
            switch result {
            case .success:
                completion(.success("验证码发送成功"))
            case .failure(let error):
                // 暂时放宽对 500 的容忍，因为你提到第二次能成功，也可能是后端的限流或偶发错误
                completion(.failure(error))
            }
        }
    }
    
    static func sendRegisterCode(phone: String, completion: @escaping (Result<String?, NetworkError>) -> Void) {
        let params: [String: Any] = ["phone": phone]
        NetworkManager.shared.request(APIService.Auth.sendCodeRegister, method: .post, parameters: params, completion: completion)
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

