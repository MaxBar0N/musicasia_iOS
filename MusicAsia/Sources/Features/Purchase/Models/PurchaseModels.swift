import Foundation

struct PackageCategory {
    let id: String
    let name: String
    let desc: String
    var packages: [PackageItem]
    let benefits: [PackageBenefit]
}

struct PackageItem {
    let id: String
    let name: String
    let price: Double
    let originalPrice: Double
    let durationInDays: Int
    let isTrial: Bool
    let activationCodeCount: Int
    var benefits: [String] = []
    var customerDesc: String? = nil
}

struct PackageBenefit {
    let name: String
    let desc: String?
    let price: Double?
}

struct OrderRecord {
    let orderNo: String
    let createTime: Date
    let agentId: String
    let salesmanId: String
    let region: String
    var status: String // "已支付"
    let agentCommission: Double
}

struct RenewRecord {
    let date: Date
    var status: String // "未同步" | "已同步"
}

// 并发安全的激活码分配器 (D5)
class ActivationCodePool {
    private let lock = NSLock()
    private var unusedCodes: [String] = (1...100).map { "CODE-\(UUID().uuidString.prefix(8))-\($0)" }
    
    func fetchCodes(count: Int, userId: String, orderNo: String) -> [String] {
        lock.lock()
        defer { lock.unlock() }
        
        guard unusedCodes.count >= count else { return [] }
        let codes = Array(unusedCodes.prefix(count))
        unusedCodes.removeFirst(count)
        
        // 模拟记录到数据库
        print("分配激活码: \(codes) 给用户: \(userId), 关联订单: \(orderNo)")
        return codes
    }
}

class PurchaseDataManager {
    static let shared = PurchaseDataManager()
    
    let codePool = ActivationCodePool()
    var hasPurchasedTrial = false
    
    // 模拟队列用于定时续费 (E)
    var pendingRenewRecords: [RenewRecord] = []
    
    // 模拟系统今日订单计数器 (D2)
    private var dailyOrderCount: Int = 0
    private var lastOrderDateString: String = ""
    
    func getCategories(isPersonal: Bool) -> [PackageCategory] {
        if isPersonal {
            return [
                PackageCategory(
                    id: "p1", name: "个人套餐", desc: "本套餐适用个人及家庭用户",
                    packages: [
                        PackageItem(id: "p_1y", name: "1年VIP", price: 100, originalPrice: 100, durationInDays: 365, isTrial: false, activationCodeCount: 1),
                        PackageItem(id: "p_2y", name: "2年至尊套餐", price: 180, originalPrice: 120, durationInDays: 730, isTrial: false, activationCodeCount: 2),
                        PackageItem(id: "p_3y", name: "3年终身套餐", price: 240, originalPrice: 320, durationInDays: 1095, isTrial: false, activationCodeCount: 3),
                        PackageItem(id: "p_trial", name: "7天试用", price: 1, originalPrice: 1, durationInDays: 7, isTrial: true, activationCodeCount: 0)
                    ],
                    benefits: [
                        PackageBenefit(name: "联通唱享视界会员", desc: nil, price: nil),
                        PackageBenefit(name: "迷你音乐盒1台", desc: "(移动WIFI、16G内存、唱享视界会员)", price: 199),
                        PackageBenefit(name: "联通3600G全国流量", desc: nil, price: 450),
                        PackageBenefit(name: "联通5G宽视界影视会员", desc: "(含1000G定向流量)", price: 185),
                        PackageBenefit(name: "唱吧K歌VIP会员", desc: nil, price: 185)
                    ]
                )
            ]
        } else {
            return [
                PackageCategory(
                    id: "b1", name: "A套餐", desc: "本套餐适用服装连锁店、美容美发、网吧/游戏厅、彩票店、茶馆、咖啡馆、奶茶店等",
                    packages: [
                        PackageItem(id: "b_a_1y", name: "1年VIP", price: 100, originalPrice: 100, durationInDays: 365, isTrial: false, activationCodeCount: 1),
                        PackageItem(id: "b_a_2y", name: "2年至尊套餐", price: 180, originalPrice: 120, durationInDays: 730, isTrial: false, activationCodeCount: 2),
                        PackageItem(id: "b_a_3y", name: "3年终身套餐", price: 240, originalPrice: 320, durationInDays: 1095, isTrial: false, activationCodeCount: 3)
                    ],
                    benefits: [
                        PackageBenefit(name: "商业音乐公播使用", desc: nil, price: nil),
                        PackageBenefit(name: "高清机顶盒1台", desc: "(2G缓存+16G内存、唱享视界会员)", price: 399),
                        PackageBenefit(name: "商用WIFI2台", desc: nil, price: 1400),
                        PackageBenefit(name: "联通3600G高速流量*2", desc: nil, price: 1200),
                        PackageBenefit(name: "联通5G宽视界影视会员*2", desc: nil, price: 370),
                        PackageBenefit(name: "唱吧K歌VIP会员*2", desc: nil, price: 370)
                    ]
                )
            ]
        }
    }
    
    /// 会员开通接口：提供给其他系统购买会员时续费会员记录
    func openMembership(appkey: String, packageId: String, phone: String, completion: @escaping (Result<String, Error>) -> Void) {
        // A1、判断appkey验证 (假设必须为16位随机数验证)
        if appkey.count != 16 {
            let error = NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "appkey有误，无法调用系统"])
            return completion(.failure(error))
        }
        
        // A2、套餐id验证
        let allPackages = getCategories(isPersonal: true).flatMap({ $0.packages }) + getCategories(isPersonal: false).flatMap({ $0.packages })
        guard let package = allPackages.first(where: { $0.id == packageId }) else {
            let error = NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "套餐id有误，续费失败"])
            return completion(.failure(error))
        }
        
        // B、会员验证：使用手机号查询此会员
        print("【会员验证】查询手机号 \(phone) 的用户，不存在则生成新用户记录")
        let userId = "USER_\(phone)"
        
        // D1、生成订单，记录时间、代理、状态"已支付"
        let orderNo = generateOrderNo()
        let orderRecord = OrderRecord(orderNo: orderNo, createTime: Date(), agentId: "AGENT_001", salesmanId: "SALES_001", region: "CN", status: "已支付", agentCommission: 0)
        print("✅ D1: 生成订单，订单号: \(orderNo)，状态: 已支付")
        
        // D3、生成代理分成
        let commission = Double(package.price) * 0.1 // 模拟10%分成
        print("✅ D3: 读取代理分成，生成订单代理分成金额: \(commission)元")
        
        // D4、根据套餐期限，增加会员有效期
        let currentExp = UfiManager.shared.memberExpiration ?? Date()
        let isCurrentlyValid = currentExp > Date()
        let baseDate = isCurrentlyValid ? currentExp : Date()
        let newExp = baseDate.addingTimeInterval(TimeInterval(package.durationInDays * 86400))
        UfiManager.shared.memberExpiration = newExp
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        print("✅ D4: 会员有效期已延长至: \(formatter.string(from: newExp))")
        
        // D5、根据套餐分配激活码
        if package.activationCodeCount > 0 {
            let codes = codePool.fetchCodes(count: package.activationCodeCount, userId: userId, orderNo: orderNo)
            print("✅ D5: 成功分配并记录激活码，状态修改为已领取: \(codes)")
        }
        
        // D6、生成续费记录
        generateRenewRecords(packageDays: package.durationInDays, isCurrentlyValid: isCurrentlyValid)
        
        // D7、返回续费结果给外部系统
        print("✅ D7: 返回续费结果成功")
        completion(.success(orderNo))
    }
    
    // 生成订单号 (D1 & D2)
    func generateOrderNo() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMdd"
        let dateStr = formatter.string(from: Date())
        
        // D2、递增今日订单编号+1
        if lastOrderDateString != dateStr {
            lastOrderDateString = dateStr
            dailyOrderCount = 0
        }
        dailyOrderCount += 1
        
        let countStr = String(format: "%04d", dailyOrderCount)
        return "D\(dateStr)\(countStr)"
    }
    
    // 生成续费记录 (D6)
    func generateRenewRecords(packageDays: Int, isCurrentlyValid: Bool) {
        let years = packageDays / 365
        let months = years * 12
        let today = Date()
        let calendar = Calendar.current
        
        if packageDays < 365 {
            // D6-1 & D6-2 (非年套餐): 直接调用多一次联通接口
            print("✅ D6: 【联通接口】非年套餐，直接调用一次联通接口，完成当月续费同步")
            return
        }
        
        // 年套餐
        var startMonthIndex = 1
        
        if !isCurrentlyValid {
            // D6-1: 如果不在有效期，调用一次联通接口完成当月续费，然后生成往后的未同步记录
            print("✅ D6-1: 【联通接口】用户不在有效期，立即调用一次联通接口完成当月续费！")
        } else {
            // D6-2 & D6-3: 如果在有效期内
            let currentHour = calendar.component(.hour, from: today)
            let currentDay = calendar.component(.day, from: today)
            
            // D6-3: 每月28号4点之后支付的特殊处理
            if currentDay >= 28 && currentHour >= 4 {
                print("✅ D6-3: 【联通接口】触发 28号4点后支付规则，拿当月的一条未同步记录调一次联通接口，完成下月续费，并修改状态为'已同步'")
            } else {
                print("✅ D6-2: 【联通接口】用户在有效期内，按最后的未同步记录下个月往后生成记录")
            }
        }
        
        // 生成“年数”*12个月28号的0点的续费、状态为“未同步”的记录
        for i in startMonthIndex...months {
            if let targetDate = calendar.date(byAdding: .month, value: i, to: today) {
                var components = calendar.dateComponents([.year, .month], from: targetDate)
                components.day = 28
                components.hour = 0
                
                if let recordDate = calendar.date(from: components) {
                    pendingRenewRecords.append(RenewRecord(date: recordDate, status: "未同步"))
                }
            }
        }
        print("✅ D6: 共生成了 \(months - startMonthIndex + 1) 条每月28号0点的'未同步'续费记录")
    }
    
    // 月定时续费 (E)
    func runMonthlyRenewTask() {
        print("⏰ E: 触发月定时续费任务 (每月28号4点)")
        let now = Date()
        
        // E1、读取当前时间之前的“未同步”状态的续费数据
        let recordsToProcess = pendingRenewRecords.filter { $0.status == "未同步" && $0.date <= now }
        
        for (index, record) in recordsToProcess.enumerated() {
            // E2、调用联通接口同步，生成接口调用记录
            print("   正在同步记录: \(record.date)")
            let isSuccess = Bool.random() // 模拟联通接口成功或失败
            if isSuccess {
                print("   ✅ 联通接口同步成功，状态改为'已同步'")
                if let idx = pendingRenewRecords.firstIndex(where: { $0.date == record.date }) {
                    pendingRenewRecords[idx].status = "已同步"
                }
            } else {
                print("   ❌ 联通接口同步失败，设置5分钟后重试")
                // 实际业务中这里可以扔到重试队列
            }
        }
    }
}
