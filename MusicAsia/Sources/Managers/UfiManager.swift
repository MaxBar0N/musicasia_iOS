import Foundation

/// 模拟 UFI 硬件状态管理与复杂的鉴权逻辑
class UfiManager {
    static let shared = UfiManager()
    
    // 模拟状态
    var isConnected: Bool = false // 默认未连接U盘
    var isDeviceValid: Bool = true
    var isActivated: Bool = false
    var activatorId: String? = nil
    var currentUserId: String = "user123"
    var currentDeviceSerialNumber: String? = "UFI123456789" // 模拟设备序列号
    
    // 模拟套餐年限 (1: 一年, 2: 两年)
    var deviceYearLimit: Int? = 1
    // 模拟会员到期时间 (默认 30 天后)
    var memberExpiration: Date? = Date().addingTimeInterval(86400 * 30)
    
    /// 检查下载权限并处理激活、续费等逻辑 (A1 - A6)
    func checkDownloadPermission(completion: @escaping (Result<Void, Error>) -> Void) {
        // A1
        guard isConnected else {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "未连接授权设备，不可下载歌曲，请连接授权设备后再下载"])
            return completion(.failure(error))
        }
        
        // A2
        guard isDeviceValid else {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "授权设备不正确，请连接正确的设备再下载，谢谢"])
            return completion(.failure(error))
        }
        
        // A3
        if isActivated {
            if activatorId != currentUserId {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "授权设备已被绑定，不可重复绑定"])
                return completion(.failure(error))
            }
        } else {
            // A4
            isActivated = true
            activatorId = currentUserId
            print("设备已激活，激活人为: \(currentUserId)")
            
            // A5
            if let year = deviceYearLimit, (year == 1 || year == 2) {
                print("执行自动续费逻辑，套餐年限: \(year)年")
                // 模拟自动续费增加到期时间
                let extraTime: TimeInterval = 86400 * 365 * Double(year)
                memberExpiration = (memberExpiration ?? Date()).addingTimeInterval(extraTime)
            }
        }
        
        // A6
        if let exp = memberExpiration, exp < Date() {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "会员已过期，请前往“我的”里面进行续费，谢谢"])
            return completion(.failure(error))
        } else if memberExpiration == nil {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "会员已过期，请前往“我的”里面进行续费，谢谢"])
            return completion(.failure(error))
        }
        
        // 鉴权通过
        completion(.success(()))
    }
}
