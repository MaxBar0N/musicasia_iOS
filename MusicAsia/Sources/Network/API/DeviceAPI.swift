import Foundation
import Alamofire

struct UserDeviceResp: Decodable {
    let voList: [UserDeviceVO]?
}

struct UserDeviceVO: Decodable {
    let userDeviceId: Int?
    let deviceCode: String?
}

struct UserDeviceCreateReq: Encodable {
    let deviceCode: String
}

class DeviceAPI {
    // 获取设备列表
    static func getDevices(completion: @escaping (Result<UserDeviceResp, NetworkError>) -> Void) {
        NetworkManager.shared.request(APIService.User.deviceList, method: .get, completion: completion)
    }
    
    // 绑定设备
    static func bindDevice(deviceCode: String, completion: @escaping (Result<String?, NetworkError>) -> Void) {
        let params: [String: Any] = [
            "deviceCode": deviceCode
        ]
        // 后端日志明确指出："JSON parse error: Unrecognized token 'deviceCode'"
        // 这说明后端框架 (Spring) 实际上在尝试用 Jackson 解析 JSON Body，
        // 而不是解析表单！因为前面我们改成了表单传参 (URLEncoding.default)，
        // 导致 Spring 拿到了 "deviceCode=test_device" 这个纯文本，当做 JSON 解析时报了错。
        // 所以我们必须切回 JSONEncoding.default。
        NetworkManager.shared.request(APIService.User.bindingDevice, method: .post, parameters: params, encoding: Alamofire.JSONEncoding.default, completion: completion)
    }
}
