import Foundation

/// 外部接口响应结构
struct ExternalAPIResponse {
    let success: Bool
    let message: String
}

/// 提供给外部系统的接口服务 (模拟后端接收 API 请求的处理逻辑)
class ExternalMembershipAPI {
    static let shared = ExternalMembershipAPI()
    
    // 模拟合法的 appkey
    private let validAppKey = "1A2B3C4D5E6F7G8H"
    
    // 模拟防灾处理队列 (D7 异步处理)
    private let taskQueue = DispatchQueue(label: "com.musicasia.external.api.queue", qos: .userInitiated)
    
    /// 供外部系统调用的开通接口
    /// - Parameters:
    ///   - appkey: 接口调用有效性的key (16位)
    ///   - packageId: 套餐id
    ///   - phone: 用户手机号
    /// - Returns: 立即返回接收结果 (同步)，实际处理为异步 (D7)
    func openMembership(appkey: String, packageId: String, phone: String) -> ExternalAPIResponse {
        
        // A1. 判断appkey验证
        guard appkey == validAppKey else {
            return ExternalAPIResponse(success: false, message: "appkey有误，无法调用系统")
        }
        
        // A2. 套餐id验证 (目前支持月套餐和1年套餐)
        let availablePackages = [
            "pkg_month": PackageItem(id: "pkg_month", name: "1个月VIP", price: 15, originalPrice: 15, durationInDays: 30, isTrial: false, activationCodeCount: 0),
            "pkg_1year": PackageItem(id: "pkg_1year", name: "1年VIP", price: 100, originalPrice: 100, durationInDays: 365, isTrial: false, activationCodeCount: 1)
        ]
        
        guard let package = availablePackages[packageId] else {
            return ExternalAPIResponse(success: false, message: "套餐id有误，续费失败")
        }
        
        // D7. 后续B\D估计要做异步处理，我们接收到了，就算成功了
        taskQueue.async {
            self.processMembership(phone: phone, package: package)
        }
        
        return ExternalAPIResponse(success: true, message: "接收成功，正在处理")
    }
    
    /// 异步处理核心逻辑
    private func processMembership(phone: String, package: PackageItem) {
        // B. 会员验证
        let userExists = checkUserExists(phone: phone)
        if !userExists {
            print("👤 会员不存在，自动生成手机号为 \(phone) 的新会员记录")
            createUser(phone: phone)
        }
        
        // D. 订单生成 (完全复用已有的高并发/复杂续费逻辑)
        let manager = PurchaseDataManager.shared
        
        // D1. 生成订单
        let orderNo = manager.generateOrderNo()
        print("✅ D1(外部): 生成订单，订单号: \(orderNo)，状态: 已支付")
        
        // D3. 生成代理分成
        let commission = Double(package.price) * 0.1
        print("✅ D3(外部): 生成代理分成: \(commission)元")
        
        // D4. 增加会员有效期
        let currentExp = UfiManager.shared.memberExpiration ?? Date()
        let isCurrentlyValid = currentExp > Date()
        let baseDate = isCurrentlyValid ? currentExp : Date()
        let newExp = baseDate.addingTimeInterval(TimeInterval(package.durationInDays * 86400))
        UfiManager.shared.memberExpiration = newExp
        print("✅ D4(外部): 会员有效期已延长至: \(newExp)")
        
        // D5. 分配激活码 (已使用 NSLock 保证高并发安全)
        if package.activationCodeCount > 0 {
            let codes = manager.codePool.fetchCodes(count: package.activationCodeCount, userId: phone, orderNo: orderNo)
            print("✅ D5(外部): 成功分配并记录激活码: \(codes)")
        }
        
        // D6. 生成续费记录 (联通接口逻辑)
        manager.generateRenewRecords(packageDays: package.durationInDays, isCurrentlyValid: isCurrentlyValid)
    }
    
    // 模拟数据库查询
    private func checkUserExists(phone: String) -> Bool {
        return phone == "13800138000" // 模拟老用户
    }
    
    private func createUser(phone: String) {
        // 模拟入库
    }
}
