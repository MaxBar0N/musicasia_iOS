import Foundation

enum SongCategory {
    case guess
    case hot
    case new
    case ksong
}

class SongDataManager {
    static let shared = SongDataManager()
    
    // 模拟全量歌曲数据
    var allSongs: [Song] = []
    
    init() {
        generateMockData()
    }
    
    private func generateMockData() {
        for i in 1...50 {
            let category: SongCategory
            if i % 4 == 0 { category = .hot }
            else if i % 4 == 1 { category = .new }
            else if i % 4 == 2 { category = .ksong }
            else { category = .guess }
            
            let artist = i % 2 == 0 ? "刘德华" : "周杰伦"
            let source: SongSource = i % 2 == 0 ? .changba : .unicom
            
            allSongs.append(Song(
                id: "\(i)",
                name: "测试歌曲_\(category)_\(i).mp3",
                artist: artist,
                source: source,
                url: source == .changba ? "http://example.com/\(i).mp3" : "encrypted_\(i)",
                isFavorited: false,
                isPlaying: false
            ))
        }
    }
    
    func getSongs(for category: SongCategory, albumId: String? = nil) -> [Song] {
        if category == .guess {
            if let _ = albumId {
                // 如果从专辑进来，显示该专辑的歌曲
                return allSongs.filter { $0.id.hasSuffix("1") || $0.id.hasSuffix("3") }
            } else {
                // 否则默认读取最新专辑的歌曲
                return allSongs.filter { $0.id.hasSuffix("2") || $0.id.hasSuffix("4") }
            }
        } else if category == .hot {
            return allSongs.filter { $0.name.contains("hot") }
        } else if category == .new {
            return allSongs.filter { $0.name.contains("new") }
        } else if category == .ksong {
            return allSongs.filter { $0.name.contains("ksong") }
        }
        return []
    }
    
    func searchSongs(keyword: String) -> [Song] {
        return allSongs.filter { 
            $0.name.lowercased().contains(keyword.lowercased()) || 
            $0.artist.lowercased().contains(keyword.lowercased()) 
        }
    }
    
    /// B3: 将蓝牙设备的名称和mac地址，请求到后台，由后台判断蓝牙设备是否有权限播放歌曲
    func checkBluetoothPermissionAsync(name: String, mac: String, completion: @escaping (Bool) -> Void) {
        // 模拟网络请求
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            // 简单模拟：如果 mac 以 11 开头，则有权限
            let hasPermission = mac.hasPrefix("11")
            DispatchQueue.main.async {
                completion(hasPermission)
            }
        }
    }
}
