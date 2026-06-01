import Foundation

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
        let body = UserDeviceCreateReq(deviceCode: deviceCode)
        do {
            let data = try JSONEncoder().encode(body)
            if let params = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                NetworkManager.shared.request(APIService.User.bindingDevice, method: .post, parameters: params, completion: completion)
            }
        } catch {
            completion(.failure(.decodingError))
        }
    }
}
