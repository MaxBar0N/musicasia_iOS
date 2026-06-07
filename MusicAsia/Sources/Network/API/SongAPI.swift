import Foundation

struct CollectionSongsResp: Decodable {
    let voList: [CollectionSongsVO]?
}

struct UserCollectSongsReq: Encodable {
    var collectionSongsId: Int
    var type: String? // "1": 歌曲, "2": 专辑
    var collectionName: String?
    var deviceCode: String?
}

struct GetSongUrlReq: Encodable {
    let cid: String
}

struct CheckBluetoothReq: Encodable {
    let bluetoothMacAddress: String?
    let bluetoothName: String?
}

struct CheckHasPermissionResp: Decodable {
    let hasPermission: Bool?
    let msg: String?
}

struct UserBluetoothVO: Decodable {
    let bluetoothName: String?
    let userBluetoothId: Int?
}

struct UserBluetoothResp: Decodable {
    let voList: [UserBluetoothVO]?
}

class BluetoothAPI {
    // 判断蓝牙是否有权限
    static func checkBluetooth(mac: String?, name: String?, completion: @escaping (Result<CheckHasPermissionResp, NetworkError>) -> Void) {
        let body = CheckBluetoothReq(bluetoothMacAddress: mac, bluetoothName: name)
        do {
            let data = try JSONEncoder().encode(body)
            if let params = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                NetworkManager.shared.request(APIService.User.checkBluetooth, method: .post, parameters: params, completion: completion)
            }
        } catch {
            completion(.failure(.decodingError))
        }
    }
    
    // 获取蓝牙列表
    static func getBluetoothList(completion: @escaping (Result<UserBluetoothResp, NetworkError>) -> Void) {
        NetworkManager.shared.request("/phone/user/bluetooth/list", method: .get, parameters: nil) { (result: Result<UserBluetoothResp, NetworkError>) in
            completion(result)
        }
    }
}

struct SetDownloadedReq: Encodable {
    let ids: [Int]
}

struct DeviceCodeReq: Encodable {
    let deviceCode: String
}

class SongAPI {
    
    // MARK: - 获取歌曲播放URL
    static func getSongUrl(cid: String, completion: @escaping (Result<String, NetworkError>) -> Void) {
        let body = GetSongUrlReq(cid: cid)
        do {
            let data = try JSONEncoder().encode(body)
            if let params = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                NetworkManager.shared.request(APIService.Song.getSongUrl, method: .post, parameters: params) { (result: Result<String, NetworkError>) in
                    completion(result)
                }
            }
        } catch {
            completion(.failure(.decodingError))
        }
    }
    
    // MARK: - 获取歌曲列表 (支持搜索及排行榜)
    static func getSongs(pageNum: Int,
                         pageSize: Int,
                         songName: String? = nil,
                         hotChart: String? = nil,
                         newChart: String? = nil,
                         kChart: String? = nil,
                         collectionName: String? = nil,
                         completion: @escaping (Result<BasePageResponse<CollectionSongsResp>, NetworkError>) -> Void) {
        
        var params: [String: Any] = ["pageNum": pageNum, "pageSize": pageSize]
        if let songName = songName, !songName.isEmpty { params["songName"] = songName }
        if let hotChart = hotChart { params["hotChart"] = hotChart }
        if let newChart = newChart { params["newChart"] = newChart }
        if let kChart = kChart { params["KChart"] = kChart } // 注意文档是大写KChart
        if let collectionName = collectionName, !collectionName.isEmpty { params["collectionName"] = collectionName }
        
        NetworkManager.shared.requestPage(APIService.Song.pageMusic, method: .get, parameters: params, completion: completion)
    }
    
    // MARK: - 猜你喜欢 (默认按最新专辑歌曲)
    static func getGuessLike(pageNum: Int, pageSize: Int, completion: @escaping (Result<BasePageResponse<CollectionSongsResp>, NetworkError>) -> Void) {
        let params: [String: Any] = ["pageNum": pageNum, "pageSize": pageSize]
        NetworkManager.shared.requestPage(APIService.Song.guessLike, method: .get, parameters: params, completion: completion)
    }
    
    // MARK: - 收藏/取消收藏
    static func collectSong(collectionSongsId: Int, type: String = "1", collectionName: String? = nil, deviceCode: String? = nil, completion: @escaping (Result<AnyDecodableValue?, NetworkError>) -> Void) {
        let body = UserCollectSongsReq(collectionSongsId: collectionSongsId, type: type, collectionName: collectionName, deviceCode: deviceCode)
        do {
            let data = try JSONEncoder().encode(body)
            if let params = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                NetworkManager.shared.request(APIService.Song.collect, method: .post, parameters: params) { (result: Result<AnyDecodableValue?, NetworkError>) in
                    if case .success = result {
                        NotificationCenter.default.post(name: NSNotification.Name("UserCollectionChanged"), object: nil)
                    }
                    completion(result)
                }
            }
        } catch {
            completion(.failure(.decodingError))
        }
    }
    
    static func disCollectSong(collectionSongsId: Int, completion: @escaping (Result<AnyDecodableValue?, NetworkError>) -> Void) {
        let body = UserCollectSongsReq(collectionSongsId: collectionSongsId)
        do {
            let data = try JSONEncoder().encode(body)
            if let params = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                NetworkManager.shared.request(APIService.Song.disCollect, method: .post, parameters: params) { (result: Result<AnyDecodableValue?, NetworkError>) in
                    if case .success = result {
                        NotificationCenter.default.post(name: NSNotification.Name("UserCollectionChanged"), object: nil)
                    }
                    completion(result)
                }
            }
        } catch {
            completion(.failure(.decodingError))
        }
    }
    
    // MARK: - 获取所有未下载歌曲
    static func getCollectUnDownload(deviceCode: String, completion: @escaping (Result<BaseResponse<CollectionSongsResp>, NetworkError>) -> Void) {
        let body = DeviceCodeReq(deviceCode: deviceCode)
        do {
            let data = try JSONEncoder().encode(body)
            if let params = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                // 根据文档，返回的是 BaseResponse 包含 CollectionSongsResp
                NetworkManager.shared.request(APIService.Song.getCollectUnDownload, method: .post, parameters: params, completion: completion)
            }
        } catch {
            completion(.failure(.decodingError))
        }
    }
    
    // MARK: - 将未下载歌曲设为已下载
    static func setCollectDownloaded(ids: [Int], completion: @escaping (Result<BaseResponse<String>, NetworkError>) -> Void) {
        let body = SetDownloadedReq(ids: ids)
        do {
            let data = try JSONEncoder().encode(body)
            if let params = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                NetworkManager.shared.request(APIService.Song.setCollectDownloaded, method: .post, parameters: params, completion: completion)
            }
        } catch {
            completion(.failure(.decodingError))
        }
    }
}
