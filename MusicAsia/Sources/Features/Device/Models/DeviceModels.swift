import Foundation

struct DeviceModel {
    let id: String
    let name: String
    let serialNo: String
}

class DeviceDataManager {
    static let shared = DeviceDataManager()
    
    var userDevices: [DeviceModel] = []
    
    // 模拟后台真实的设备序列号库
    private let validSerialNumbers = [
        "O123456", "O888888", // O开头：1年
        "T123456", "T999999", // T开头：2年
        "X111111" // 其他：不续费
    ]
    
    // 模拟已被其他人激活的设备
    private let activatedSerialNumbers = ["O888888", "T999999"]
    
    func addDevice(serialNo: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // A1: 验证是否存在
        guard validSerialNumbers.contains(serialNo) else {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "绑定不成功，请绑定正确的设备，谢谢"])
            return completion(.failure(error))
        }
        
        // A2: 验证是否被别人激活
        if activatedSerialNumbers.contains(serialNo) {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "设备已被绑定，不可重复绑定"])
            return completion(.failure(error))
        }
        
        // A3: 修改状态为已激活 (模拟)
        print("设备 \(serialNo) 激活成功，绑定到当前用户")
        
        // A4: 判断序列号并自动续费
        if serialNo.hasPrefix("O") {
            print("识别到 O 开头设备，自动续费 1 年")
            renewMembership(years: 1)
        } else if serialNo.hasPrefix("T") {
            print("识别到 T 开头设备，自动续费 2 年")
            renewMembership(years: 2)
        }
        
        // 成功添加到列表
        let newDevice = DeviceModel(id: UUID().uuidString, name: "设备\(userDevices.count + 1)", serialNo: serialNo)
        userDevices.append(newDevice)
        
        completion(.success(()))
    }
    
    private func renewMembership(years: Int) {
        let currentExp = UfiManager.shared.memberExpiration ?? Date()
        let baseDate = currentExp > Date() ? currentExp : Date()
        let newExp = baseDate.addingTimeInterval(TimeInterval(years * 365 * 86400))
        UfiManager.shared.memberExpiration = newExp
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        print("会员有效期已延长至: \(formatter.string(from: newExp))")
        
        // 调用我们之前写好的 D6 逻辑生成续费记录
        PurchaseDataManager.shared.generateRenewRecords(packageDays: years * 365, isCurrentlyValid: currentExp > Date())
    }
}
