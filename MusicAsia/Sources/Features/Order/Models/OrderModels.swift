import Foundation

struct OrderModel {
    let id: String
    let title: String
    let orderNo: String
    let createTime: String
    let status: String
    let activationCodes: [String]
}

class OrderDataManager {
    static let shared = OrderDataManager()
    
    var allOrders: [OrderModel] = []
    
    init() {
        // 生成模拟订单数据
        for i in 1...30 {
            let codes = [
                "18888288188\(i)",
                "23222999999\(i)",
                "05656456086\(i)"
            ]
            allOrders.append(OrderModel(
                id: "\(i)",
                title: i % 2 == 0 ? "2年VIP套餐" : "1年VIP套餐",
                orderNo: "DD250619000\(String(format: "%02d", i))",
                createTime: "2025.06.19 10:10:\(String(format: "%02d", i % 60))",
                status: "已支付",
                activationCodes: codes
            ))
        }
    }
}
