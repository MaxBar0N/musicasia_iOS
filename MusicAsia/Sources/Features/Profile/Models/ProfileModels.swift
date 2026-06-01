import Foundation

struct UserProfile {
    let name: String
    let avatarUrl: String
    let vipExpiration: Date?
    var formattedExpirationStr: String? = nil
    
    var formattedExpiration: String {
        if let str = formattedExpirationStr { return str }
        guard let date = vipExpiration else { return "---" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}

class ProfileDataManager {
    static let shared = ProfileDataManager()
    
    // 模拟用户信息
    func getUserProfile() -> UserProfile {
        return UserProfile(
            name: "陈晓光",
            avatarUrl: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=200&q=80",
            vipExpiration: UfiManager.shared.memberExpiration
        )
    }
    
    // 模拟所有收藏歌曲
    var allFavoritedSongs: [Song] = []
    
    init() {
        // 生成大量收藏歌曲假数据
        for i in 1...30 {
            let artist = i % 2 == 0 ? "刘德华" : "周杰伦"
            let source: SongSource = i % 2 == 0 ? .changba : .unicom
            allFavoritedSongs.append(Song(
                id: "fav_\(i)",
                name: "收藏歌曲_\(i).mp3",
                artist: artist,
                source: source,
                url: source == .changba ? "http://example.com/fav_\(i).mp3" : "encrypted_fav_\(i)",
                isFavorited: true,
                isPlaying: false,
                isDownloaded: i % 3 == 0 // 模拟部分已下载
            ))
        }
    }
    
    // 模拟获取未下载的最新歌曲 (最多 200 条)
    func getUndownloadedSongs() -> [Song] {
        var undownloaded: [Song] = []
        for i in 1...20 { // 演示使用 20 首
            undownloaded.append(Song(
                id: "undl_\(i)",
                name: "未下载歌曲_\(i).mp3",
                artist: "歌手",
                source: .changba,
                url: "http://example.com/undl_\(i).mp3",
                isFavorited: false,
                isPlaying: false,
                isDownloaded: false
            ))
        }
        return undownloaded
    }
    
    // 检查VIP有效性
    func checkVIPValidityAsync(completion: @escaping (Bool) -> Void) {
        // 暂时假设总是有效
        DispatchQueue.main.async {
            completion(true)
        }
    }
}
