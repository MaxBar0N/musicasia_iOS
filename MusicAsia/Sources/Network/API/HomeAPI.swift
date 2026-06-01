import Foundation

struct IndexResp: Decodable {
    let collectionVoList: [MusicCollectionVO]?
    let songsVoList: [CollectionSongsVO]?
}

struct MusicCollectionVO: Decodable {
    let musicCollectionId: Int?
    let collectionName: String?
    let collectionImg: String?
    let recommend: String?
}

struct CollectionSongsVO: Decodable {
    let collectionSongsId: Int?
    let songName: String?
    let songNameSecret: String?
    let singer: String?
    let collectionName: String?
    let songTime: String?
    var userIsCollect: Bool?
    let hotChart: String?
    let newChart: String?
    let kchart: String?
}

class HomeAPI {
    static func getIndex(completion: @escaping (Result<IndexResp, NetworkError>) -> Void) {
        NetworkManager.shared.request(APIService.Home.index, method: .get, completion: completion)
    }
}
