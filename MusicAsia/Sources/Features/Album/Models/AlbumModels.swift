import Foundation

// 在 HomeModels 中扩展数据源
class AlbumDataManager {
    static let shared = AlbumDataManager()
    
    // 模拟全量专辑数据
    var allAlbums: [Album] = [
        Album(id: "1", name: "80后经典", coverUrl: "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?auto=format&fit=crop&w=500&q=60", isFavorited: false),
        Album(id: "2", name: "车载EDM", coverUrl: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=500&q=60", isFavorited: false),
        Album(id: "3", name: "欧美流行日推", coverUrl: "https://images.unsplash.com/photo-1493225457124-a1a2a53702a0?auto=format&fit=crop&w=500&q=60", isFavorited: false),
        Album(id: "4", name: "放松幻想曲", coverUrl: "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?auto=format&fit=crop&w=500&q=60", isFavorited: false),
        Album(id: "5", name: "太空漫游", coverUrl: "https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=500&q=60", isFavorited: false),
        Album(id: "6", name: "工作学习BGM", coverUrl: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=500&q=60", isFavorited: false),
        Album(id: "7", name: "2024欧洲流行", coverUrl: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=500&q=60", isFavorited: false),
        Album(id: "8", name: "晴天散步小曲", coverUrl: "https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?auto=format&fit=crop&w=500&q=60", isFavorited: false)
    ]
    
    /// 模拟获取专辑的所有歌曲
    func getSongsForAlbum(albumId: String) -> [Song] {
        return [
            Song(id: "101", name: "测试歌曲1.mp3", artist: "歌手A", source: .changba, url: "http://example.com/101.mp3", isFavorited: false),
            Song(id: "102", name: "测试歌曲2.mp3", artist: "歌手B", source: .unicom, url: "encrypted_102", isFavorited: false),
            Song(id: "103", name: "测试歌曲3.mp3", artist: "歌手C", source: .changba, url: "http://example.com/103.mp3", isFavorited: false)
        ]
    }
}
