import UIKit
import SnapKit

class HomeViewController: BaseViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let adsStack = UIStackView()
    private let songsContainer = UIView()
    private let songsStack = UIStackView()
    private let albumsStack = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }
        
        // 1. Ads Section (A. 广告图)
        adsStack.axis = .horizontal
        adsStack.spacing = 15
        adsStack.distribution = .fillEqually
        contentView.addSubview(adsStack)
        adsStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview().inset(20)
        }
        
        let ad1 = AdCardView(title: "", imageUrl: "banner_singing_image")
        let ad2 = AdCardView(title: "", imageUrl: "banner_film_image")
        
        // 保证广告位宽高比 1:1（正方形）
        ad1.snp.makeConstraints { make in
            make.height.equalTo(ad1.snp.width)
        }
        
        adsStack.addArrangedSubview(ad1)
        adsStack.addArrangedSubview(ad2)
        
        // 2. Recommend Songs (B. 推荐歌曲)
        let songsHeader = SectionHeaderView(title: "推荐歌曲")
        contentView.addSubview(songsHeader)
        songsHeader.snp.makeConstraints { make in
            make.top.equalTo(adsStack.snp.bottom).offset(30)
            make.left.equalToSuperview().offset(20)
        }
        
        songsContainer.backgroundColor = UIColor(hex: "#182238").withAlphaComponent(0.2)
        songsContainer.layer.cornerRadius = 8
        contentView.addSubview(songsContainer)
        
        songsContainer.snp.makeConstraints { make in
            make.top.equalTo(songsHeader.snp.bottom).offset(15)
            make.left.right.equalToSuperview().inset(20)
        }
        
        songsStack.axis = .vertical
        songsStack.spacing = 20
        songsContainer.addSubview(songsStack)
        songsStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(15)
        }
        
        // 3. Recommend Albums (C. 推荐专辑)
        let albumsHeader = SectionHeaderView(title: "推荐专辑")
        contentView.addSubview(albumsHeader)
        albumsHeader.snp.makeConstraints { make in
            make.top.equalTo(songsContainer.snp.bottom).offset(40)
            make.left.equalToSuperview().offset(20)
        }
        
        albumsStack.axis = .horizontal
        albumsStack.spacing = 15
        albumsStack.distribution = .fillEqually
        contentView.addSubview(albumsStack)
        albumsStack.snp.makeConstraints { make in
            make.top.equalTo(albumsHeader.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(120)
            make.bottom.equalToSuperview().offset(-30) // Important for scrollView content size
        }
    }
    
    private func loadData() {
        print("HomeViewController: loadData() start")
        HomeAPI.getIndex { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let indexResp):
                self.handleIndexData(indexResp)
            case .failure(let error):
                self.showAlert(message: "获取首页数据失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleIndexData(_ data: IndexResp) {
        // 更新推荐歌曲
        let songs = data.songsVoList ?? []
        // 只展示热歌榜的最新 6 首，接口理论上已经过滤，这里直接展示
        let displaySongs = Array(songs.prefix(6))
        
        // 移除多余的 view
        while songsStack.arrangedSubviews.count > displaySongs.count {
            songsStack.arrangedSubviews.last?.removeFromSuperview()
        }
        
        for (index, song) in displaySongs.enumerated() {
            let row: SongRowView
            if index < songsStack.arrangedSubviews.count {
                row = songsStack.arrangedSubviews[index] as! SongRowView
            } else {
                row = SongRowView()
                songsStack.addArrangedSubview(row)
                row.snp.makeConstraints { make in make.height.equalTo(44) }
            }
            
            // Map CollectionSongsVO to Song model for UI temporarily
            let uiSong = Song(id: "\(song.collectionSongsId ?? 0)",
                              name: song.songName ?? "未知歌曲",
                              artist: song.singer ?? "未知歌手",
                              source: .changba,
                              url: "",
                              isFavorited: song.userIsCollect ?? false,
                              isPlaying: false,
                              isDownloaded: false)
            row.configure(with: uiSong)
            row.onFavTapped = { [weak self] in
                self?.handleSongFav(at: index, songId: song.collectionSongsId ?? 0, isFav: song.userIsCollect ?? false)
            }
            row.onPlayTapped = { [weak self] in
                self?.handleSongPlay(at: index, song: song)
            }
        }
        
        // 更新推荐专辑
        let albums = data.collectionVoList ?? []
        
        // 移除多余的 view
        while albumsStack.arrangedSubviews.count > albums.count {
            albumsStack.arrangedSubviews.last?.removeFromSuperview()
        }
        
        for (index, album) in albums.enumerated() {
            let card: AlbumCardView
            if index < albumsStack.arrangedSubviews.count {
                card = albumsStack.arrangedSubviews[index] as! AlbumCardView
            } else {
                card = AlbumCardView()
                albumsStack.addArrangedSubview(card)
            }
            
            // 修复：处理图片 URL
            var imageUrl = album.collectionImg ?? ""
            imageUrl = imageUrl.replacingOccurrences(of: "\\", with: "/")
            
            // 如果包含了本地测试或内网的 IP，强行替换为公网 IP
            if imageUrl.contains("localhost") || imageUrl.contains("127.0.0.1") || imageUrl.contains("192.168.") {
                if let pathIndex = imageUrl.range(of: "/", options: [], range: imageUrl.index(imageUrl.startIndex, offsetBy: 8)..<imageUrl.endIndex)?.lowerBound {
                    imageUrl = String(imageUrl[pathIndex...])
                }
            }
            
            if !imageUrl.isEmpty && !imageUrl.hasPrefix("http") {
                imageUrl = "http://47.243.180.202:48080" + (imageUrl.hasPrefix("/") ? "" : "/") + imageUrl
            }
            
            // 对 URL 中的特殊字符（如中文或空格）进行编码
            imageUrl = imageUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? imageUrl
            
            let uiAlbum = Album(id: "\(album.musicCollectionId ?? 0)",
                                name: album.collectionName ?? "未知专辑",
                                coverUrl: imageUrl,
                                isFavorited: false)
            card.configure(with: uiAlbum)
            card.onFavTapped = { [weak self] in
                // Home页的专辑暂不支持收藏
            }
            card.onPlayTapped = { [weak self] in
                self?.handleAlbumPlay(at: index, album: album)
            }
            albumsStack.addArrangedSubview(card)
        }
    }
    
    // MARK: - Actions (业务逻辑)
    
    private func handleSongFav(at index: Int, songId: Int, isFav: Bool) {
        // A. 收藏/取消收藏
        if isFav {
            // 取消收藏
            SongAPI.disCollectSong(collectionSongsId: songId) { [weak self] result in
                if case .success = result {
                    self?.loadData() // 刷新状态
                } else if case .failure(let error) = result {
                    print("取消收藏失败: \(error)")
                }
            }
        } else {
            // 收藏
            SongAPI.collectSong(collectionSongsId: songId, type: "1") { [weak self] result in
                if case .success = result {
                    self?.showCollectSuccessPopup()
                    self?.loadData() // 刷新状态
                } else if case .failure(let error) = result {
                    print("收藏失败: \(error)")
                }
            }
        }
    }
    
    private func handleSongPlay(at index: Int, song: CollectionSongsVO) {
        let songName = song.songName ?? ""
        let secret = song.songNameSecret ?? ""
        
        SongPlaybackManager.shared.playSong(
            songName: songName,
            songSecret: secret,
            isDownloaded: false, // 首页未获取下载状态
            in: self
        ) { [weak self] in
            // 播放成功后的 UI 状态更新（如需要）
            print("鉴权通过，开始播放: \(songName)")
        }
    }
    
    private func handleAlbumPlay(at index: Int, album: MusicCollectionVO) {
        // C: 跳转到歌曲列表，并在“猜你喜欢”的tab中显示此专辑的所有歌曲
        print("跳转到专辑 [\(album.collectionName ?? "")] 的歌曲列表 -> 猜你喜欢")
        
        let songVC = SongViewController()
        songVC.sourceAlbumId = "\(album.musicCollectionId ?? 0)"
        songVC.sourceAlbumName = album.collectionName
        songVC.title = "猜你喜欢 - \(album.collectionName ?? "")"
        songVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(songVC, animated: true)
    }
}
