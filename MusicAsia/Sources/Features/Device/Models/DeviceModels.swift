import Foundation

struct DeviceModel {
    let id: String
    let name: String
    let serialNo: String
}

class DeviceDataManager {
    static let shared = DeviceDataManager()

    var userDevices: [DeviceModel] = []

    /// 从后端加载当前用户的设备列表
    func loadDevices(completion: @escaping (Result<[DeviceModel], NetworkError>) -> Void) {
        DeviceAPI.getDevices { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let resp):
                    let vos = resp.voList ?? []
                    let devices = vos.enumerated().map { index, vo in
                        DeviceModel(
                            id: "\(vo.userDeviceId ?? 0)",
                            name: "设备\(index + 1)",
                            serialNo: vo.deviceCode ?? ""
                        )
                    }
                    self.userDevices = devices
                    completion(.success(devices))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    /// 调用后端绑定设备
    func addDevice(serialNo: String, completion: @escaping (Result<Void, Error>) -> Void) {
        DeviceAPI.bindDevice(deviceCode: serialNo) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}
