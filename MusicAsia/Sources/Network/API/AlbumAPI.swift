import Foundation

struct MusicCollectionResp: Decodable {
    let voList: [MusicCollectionVO]?
}

class AlbumAPI {
    static func getAlbums(pageNum: Int, pageSize: Int, collectionName: String? = nil, completion: @escaping (Result<BasePageResponse<MusicCollectionResp>, NetworkError>) -> Void) {
        var params: [String: Any] = ["pageNum": pageNum, "pageSize": pageSize]
        if let collectionName = collectionName, !collectionName.isEmpty {
            params["collectionName"] = collectionName
        }
        
        NetworkManager.shared.requestPage(APIService.Collection.page, method: .get, parameters: params, completion: completion)
    }
}
