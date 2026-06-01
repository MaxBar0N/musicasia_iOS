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
    let res = try JSONDecoder().decode(BaseResponse<String?>.self, from: json)
    print("Success: \(String(describing: res.data))")
} catch {
    print("Error: \(error)")
}
