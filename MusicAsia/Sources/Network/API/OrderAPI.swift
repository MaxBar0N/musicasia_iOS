import Foundation

struct PhoneOrderResp: Decodable {
    let voList: [PhoneOrderVO]?
}

struct PhoneOrderVO: Decodable {
    let orderId: Int?
    let orderCode: String?
    let createTime: String?
    let setMenuImg: String?
    let setMenuName: String?
    let setMenuType: String?
    let codeVOS: [ActivationCodeVO]?
}

struct ActivationCodeVO: Decodable {
    let activationCodeId: Int?
    let changBaCode: String?
    let lianTongCode: String?
}

struct DictDataVO: Decodable {
    let dictCode: Int?
    let dictSort: Int?
    let dictLabel: String?
    let dictValue: String?
    let dictType: String?
    let status: String?
    let remark: String?
}

struct AppSetMenuResp: Decodable {
    var voList: [AppSetMenuVO]?
    
    init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            voList = try container.decodeIfPresent([AppSetMenuVO].self, forKey: .voList)
        } catch {
            let container = try decoder.singleValueContainer()
            voList = try container.decode([AppSetMenuVO].self)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case voList
    }
}

struct AppSetMenuVO: Decodable {
    let setMenuId: AnyDecodableValueStr?
    let setMenuName: AnyDecodableValueStr?
    let nowPrice: AnyDecodableValueStr?
    let originPrice: AnyDecodableValueStr?
    let customerDescription: AnyDecodableValueStr?
    let content: AnyDecodableValueStr?
    let activationCodeNumber: AnyDecodableValueStr?
    let setMenuYear: AnyDecodableValueStr?
    let timeType: AnyDecodableValueStr?
}

struct AnyDecodableValueStr: Decodable {
    var value: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            value = str
        } else if let intVal = try? container.decode(Int.self) {
            value = String(intVal)
        } else if let doubleVal = try? container.decode(Double.self) {
            value = String(doubleVal)
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal ? "1" : "0"
        } else {
            value = "0"
        }
    }
}

struct PlaceOrderReq: Encodable {
    let setMenuId: Int
}

struct PrepayWithRequestPaymentResponse: Decodable {
    let appid: String?
    let nonceStr: String?
    let packageVal: String?
    let partnerId: String?
    let prepayId: String?
    let sign: String?
    let timestamp: String?
    let orderId: Int? // 假设后端能同时返回 orderId 供查询状态
}

struct H5OrderPayResp: Decodable {
    let h5Url: String?
    let orderCode: String?
    let orderId: Int?
}

struct OrderPaymentQueryReq: Encodable {
    let orderId: Int
}

struct QueryOrderPayStatusResp: Decodable {
    let isPay: Bool?
}

struct AppleIapCreateResp: Decodable {
    let appAccountToken: String?
    let appleProductId: String?
    let orderCode: String?
    let orderId: Int?
}

struct AppleIapVerifyReq: Encodable {
    let orderId: Int
    let signedTransactionInfo: String
}

class OrderAPI {
    
    // 获取订单分页列表
    static func getOrders(pageNum: Int, pageSize: Int, completion: @escaping (Result<BasePageResponse<PhoneOrderResp>, NetworkError>) -> Void) {
        let params: [String: Any] = ["pageNum": pageNum, "pageSize": pageSize]
        NetworkManager.shared.requestPage(APIService.Order.page, method: .get, parameters: params, completion: completion)
    }
    
    // 获取套餐列表
    static func getMenuList(dictValue: String? = nil, completion: @escaping (Result<AppSetMenuResp, NetworkError>) -> Void) {
        var params: [String: Any] = [:]
        if let val = dictValue { params["dictValue"] = val }
        // 注意：/order/menu/list 如果后台没配 dictValue，可以尝试用 dictType，某些后台框架的字典接口用的是 dictType
        // 如果业务里明确是用 dictValue=APP，那可能是后台确实没数据。这里做一下兼容。
        NetworkManager.shared.request(APIService.Order.menuList, method: .get, parameters: params, completion: completion)
    }
    
    // 获取字典
    static func getDictData(dictType: String, completion: @escaping (Result<[DictDataVO], NetworkError>) -> Void) {
        let path = APIService.System.dictData + "/\(dictType)"
        NetworkManager.shared.request(path, method: .get, parameters: nil, completion: completion)
    }
    
    // App 下单
    static func placeAppOrder(setMenuId: Int, completion: @escaping (Result<PrepayWithRequestPaymentResponse, NetworkError>) -> Void) {
        let body = PlaceOrderReq(setMenuId: setMenuId)
        do {
            let data = try JSONEncoder().encode(body)
            if let params = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                NetworkManager.shared.request(APIService.Order.payApp, method: .post, parameters: params, completion: completion)
            }
        } catch {
            completion(.failure(.decodingError))
        }
    }
    
    // H5 下单
    static func placeH5Order(setMenuId: Int, completion: @escaping (Result<H5OrderPayResp, NetworkError>) -> Void) {
        let body = PlaceOrderReq(setMenuId: setMenuId)
        do {
            let data = try JSONEncoder().encode(body)
            if let params = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                NetworkManager.shared.request(APIService.Order.payH5, method: .post, parameters: params, completion: completion)
            }
        } catch {
            completion(.failure(.decodingError))
        }
    }
    
    // 苹果内购下单
    static func createAppleOrder(setMenuId: Int, completion: @escaping (Result<AppleIapCreateResp, NetworkError>) -> Void) {
        let body = PlaceOrderReq(setMenuId: setMenuId)
        do {
            let data = try JSONEncoder().encode(body)
            if let params = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                NetworkManager.shared.request(APIService.Order.payAppleCreate, method: .post, parameters: params, completion: completion)
            }
        } catch {
            completion(.failure(.decodingError))
        }
    }
    
    // 苹果内购支付凭证验证
    static func verifyAppleReceipt(orderId: Int, signedTransactionInfo: String, completion: @escaping (Result<QueryOrderPayStatusResp, NetworkError>) -> Void) {
        let body = AppleIapVerifyReq(orderId: orderId, signedTransactionInfo: signedTransactionInfo)
        do {
            let data = try JSONEncoder().encode(body)
            if let params = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                NetworkManager.shared.request(APIService.Order.payAppleVerify, method: .post, parameters: params, completion: completion)
            }
        } catch {
            completion(.failure(.decodingError))
        }
    }

    // 查询订单支付状态
    static func checkPayment(orderId: Int, completion: @escaping (Result<QueryOrderPayStatusResp, NetworkError>) -> Void) {
        let body = OrderPaymentQueryReq(orderId: orderId)
        do {
            let data = try JSONEncoder().encode(body)
            if let params = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                NetworkManager.shared.request(APIService.Order.checkPayment, method: .post, parameters: params, completion: completion)
            }
        } catch {
            completion(.failure(.decodingError))
        }
    }
}
