import Foundation

enum SongSource {
    case changba // 唱吧，直接 URL
    case unicom  // 联通，需解密
}

struct Song {
    let id: String
    let name: String
    let artist: String
    let source: SongSource
    let url: String
    var isFavorited: Bool
    var isPlaying: Bool = false
    var isDownloaded: Bool = false // 标识是否已下载到本地
}

struct Album {
    let id: String
    let name: String
    let coverUrl: String
    var isFavorited: Bool
}

/// 模拟业务数据与权限管理
class HomeDataManager {
    static let shared = HomeDataManager()
    
    // 模拟数据
    var recommendSongs: [Song] = [
        Song(id: "1", name: "忘情水.mp3", artist: "刘德华", source: .changba, url: "http://example.com/1.mp3", isFavorited: true),
        Song(id: "2", name: "水手.mp3", artist: "郑智化", source: .unicom, url: "encrypted_url_2", isFavorited: false),
        Song(id: "3", name: "啦啦.mp3", artist: "网络歌手", source: .changba, url: "http://example.com/3.mp3", isFavorited: false),
        Song(id: "4", name: "半岛铁盒.mp3", artist: "周杰伦", source: .unicom, url: "encrypted_url_4", isFavorited: false),
        Song(id: "5", name: "稻香.mp3", artist: "周杰伦", source: .changba, url: "http://example.com/5.mp3", isFavorited: false),
        Song(id: "6", name: "夜的第七章.mp3", artist: "周杰伦", source: .unicom, url: "encrypted_url_6", isFavorited: false)
    ]
    
    var recommendAlbums: [Album] = [
        Album(id: "1", name: "80后经典", coverUrl: "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?auto=format&fit=crop&w=500&q=60", isFavorited: true),
        Album(id: "2", name: "车载EDM", coverUrl: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=500&q=60", isFavorited: false)
    ]
    
    // 权限数据
    private var registeredMACs: [String] = ["AA:BB:CC:DD:EE:FF"]
    private let maxBluetoothCount = 3
    
    /// 检查蓝牙播放权限 (规则 5)
    func checkBluetoothPermission(mac: String) -> Bool {
        if registeredMACs.contains(mac) {
            return true // A1: 在列表里，有权限
        }
        
        if registeredMACs.count < maxBluetoothCount {
            registeredMACs.append(mac)
            return true // A2: 未达上限，添加并授权
        }
        
        return false // A3: 其他情况无权限
    }
    
    /// 模拟异步检查蓝牙播放权限 (规则 5)
    func checkBluetoothPermissionAsync(name: String, mac: String, completion: @escaping (Bool) -> Void) {
        // 模拟网络请求延迟
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            let hasPermission = self.checkBluetoothPermission(mac: mac)
            DispatchQueue.main.async {
                completion(hasPermission)
            }
        }
    }
    
    /// 模拟后台解密联通 URL (规则 4.B2)
    func decryptURL(_ encryptedURL: String, completion: @escaping (String) -> Void) {
        // 模拟网络请求延迟
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            let decrypted = "http://decrypted.example.com/" + encryptedURL + ".mp3"
            DispatchQueue.main.async {
                completion(decrypted)
            }
        }
    }
}
