import Foundation

struct BaseResponse<T: Decodable>: Decodable {
    let code: Int
    let msg: String?
    let data: T?
}

let json = """
{ "code": 200, "msg": "ok", "data": null }
""".data(using: .utf8)!

do {
    let baseResponse = try JSONDecoder().decode(BaseResponse<String?>.self, from: json)
    if let data = baseResponse.data {
        print("data exists: \(data)")
    } else if let emptyType = String?.self as? ExpressibleByNilLiteral.Type {
        let emptyData = emptyType.init(nilLiteral: ()) as! String?
        print("Empty Data Passed: \(String(describing: emptyData))")
    } else {
        print("noData")
    }
} catch {
    print("Error: \(error)")
}
