import Foundation

struct UserCollectionSongsResp: Decodable {
    let name: String?
    let phone: String?
    let logo: String?
    let endTime: String?
    let rechargeCode: String?
    let voList: [UserCollectionSongsVO]?
}

struct UserCollectionSongsVO: Decodable {
    let userCollectionSongsId: Int?
    let collectionSongsId: Int?
    let songName: String?
    let songNameSecret: String?
    let singer: String?
    let songTime: String?
}

class ProfileAPI {
    // 获取“我的”首页数据（包含用户信息和分页收藏歌曲）
    static func getMeInfo(pageNum: Int, pageSize: Int, completion: @escaping (Result<BasePageResponse<UserCollectionSongsResp>, NetworkError>) -> Void) {
        let params: [String: Any] = ["pageNum": pageNum, "pageSize": pageSize]
        NetworkManager.shared.requestPage(APIService.User.me, method: .get, parameters: params, completion: completion)
    }
    
    // MARK: - 判断用户VIP是否过期
    static func checkUserEndTime(completion: @escaping (Result<CheckHasPermissionResp, NetworkError>) -> Void) {
        // 根据文档：返回值为 BaseResponse«CheckHasPermissionResp»，无参数体
        NetworkManager.shared.request(APIService.User.checkUserEndTime, method: .post, parameters: nil, completion: completion)
    }
}
