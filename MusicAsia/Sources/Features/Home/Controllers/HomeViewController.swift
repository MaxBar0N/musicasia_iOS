import UIKit
import SnapKit

class HomeViewController: BaseViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let refreshControl = UIRefreshControl()
    
    private let adsStack = UIStackView()
    private let songsContainer = UIView()
    private let songsStack = UIStackView()
    private let albumsScrollView = UIScrollView()
    private let albumsStack = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
        NotificationCenter.default.addObserver(self, selector: #selector(playerStateChanged), name: NSNotification.Name("PlayerStateChanged"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
        
        refreshControl.tintColor = UIColor(hex: "#16E0BF")
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        scrollView.refreshControl = refreshControl
        
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
        
        ad1.onTap = { [weak self] in
            self?.showAlert(message: "唱吧APP暂不支持IOS系统")
        }
        
        ad2.onTap = { [weak self] in
            // 5G宽视界跳转逻辑
            let appScheme = "wotvapp://" // 5G宽视界 schema
            let fallbackUrl = "https://webwotv.chinaunicomvideo.cn/wovideo/wotvStarKaraoke/index.html#/subject/catauto1111130298?reflectionId=ACT0580848008&channel=xnkg"
            
            if let schemeURL = URL(string: appScheme), UIApplication.shared.canOpenURL(schemeURL) {
                UIApplication.shared.open(schemeURL, options: [:], completionHandler: nil)
            } else {
                self?.showAlert(message: "5G宽视界未安装，请前往安装，谢谢") {
                    if let webURL = URL(string: fallbackUrl) {
                        UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
                    }
                }
            }
        }
        
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
        
        albumsScrollView.showsHorizontalScrollIndicator = false
        albumsScrollView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        contentView.addSubview(albumsScrollView)
        albumsScrollView.snp.makeConstraints { make in
            make.top.equalTo(albumsHeader.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
            make.height.equalTo(120)
            make.bottom.equalToSuperview().offset(-30) // Important for scrollView content size
        }
        
        albumsStack.axis = .horizontal
        albumsStack.spacing = 15
        albumsStack.distribution = .fill
        albumsScrollView.addSubview(albumsStack)
        albumsStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
    }
    
    private func loadData() {
        print("HomeViewController: loadData() start")
        if !refreshControl.isRefreshing {
            showLoading()
        }
        HomeAPI.getIndex { [weak self] result in
            guard let self = self else { return }
            self.hideLoading()
            self.refreshControl.endRefreshing()
            switch result {
            case .success(let indexResp):
                self.handleIndexData(indexResp)
            case .failure(let error):
                self.showAlert(message: "获取首页数据失败: \(error.localizedDescription)")
            }
        }
    }
    
    @objc private func handleRefresh() {
        loadData()
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
            let isCurrent = (song.songName == SongPlaybackManager.shared.currentSongName)
            let uiSong = Song(id: "\(song.collectionSongsId ?? 0)",
                              name: song.songName ?? "未知歌曲",
                              artist: song.singer ?? "未知歌手",
                              source: .changba,
                              url: "",
                              isFavorited: song.userIsCollect ?? false,
                              isPlaying: isCurrent && AudioPlayerManager.shared.isPlaying,
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
                card.snp.makeConstraints { make in
                    make.width.equalTo(120) // 设定为120使其成为正方形，并支持横向滚动
                }
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
                imageUrl = "https://iosapi.musicasia.cn" + (imageUrl.hasPrefix("/") ? "" : "/") + imageUrl
            }
            
            // 避免重复编码
            if URL(string: imageUrl) == nil {
                imageUrl = imageUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? imageUrl
            }
            
            let uiAlbum = Album(id: "\(album.musicCollectionId ?? 0)",
                                name: album.collectionName ?? "未知专辑",
                                coverUrl: imageUrl,
                                isFavorited: false)
            card.configure(with: uiAlbum)
            card.onDownloadTapped = { [weak self] in
                self?.handleAlbumDownload(for: uiAlbum)
            }
            card.onPlayTapped = { [weak self] in
                self?.handleAlbumPlay(at: index, album: album)
            }
        }
    }
    
    private var isDownloading = false
    private var downloadPopup: DownloadProgressView?
    
    // MARK: - Actions (业务逻辑)
    
    @objc private func playerStateChanged() {
        // 更新列表中的播放状态
        for (index, view) in songsStack.arrangedSubviews.enumerated() {
            guard let row = view as? SongRowView else { continue }
            // 判断这行是否是当前播放的歌曲
            // 但是这里我们没有保存 songs 数组供复用。我们在 handleIndexData 中绑定了。
            // 简单的方法是比较 songName
            let isCurrent = (row.titleLabel.text == SongPlaybackManager.shared.currentSongName)
            row.updatePlayState(isPlaying: isCurrent && AudioPlayerManager.shared.isPlaying)
        }
    }
    
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
            isTrial: true,       // 首页歌曲属于试听歌曲，跳过会员验证
            in: self
        ) {
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
    
    // MARK: - Download Logic
    private func handleAlbumDownload(for album: Album) {
        showLoading()
        
        // 1. 获取该专辑的所有歌曲
        SongAPI.getSongs(pageNum: 1, pageSize: 1000, collectionName: album.name) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let pageResponse):
                let songs = pageResponse.data?.voList ?? []
                if songs.isEmpty {
                    self.hideLoading()
                    self.showAlert(message: "该专辑暂无歌曲")
                    return
                }
                
                // 2. 遍历收藏专辑里的所有歌曲
                let group = DispatchGroup()
                for song in songs {
                    // 如果还没有收藏，则调用收藏接口 (type: "1" 表示单曲)
                    if song.userIsCollect != true {
                        group.enter()
                        SongAPI.collectSong(collectionSongsId: song.collectionSongsId ?? 0, type: "1", collectionName: nil) { _ in
                            group.leave()
                        }
                    }
                }
                
                // 所有歌曲收藏完成后
                group.notify(queue: .main) {
                    self.hideLoading()
                    // 3. 收藏完成后静默检查 U 盘权限
                    self.checkPermissionAndDownload(album: album)
                }
                
            case .failure(let error):
                self.hideLoading()
                self.showAlert(message: "获取专辑歌曲失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func checkPermissionAndDownload(album: Album) {
        UfiManager.shared.checkDownloadPermission { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.startDownloadProcess(for: album)
            case .failure(let error):
                // 提示用户需要插入 U 盘，同时阻断后续的下载弹窗
                self.showAlert(message: error.localizedDescription)
            }
        }
    }
    
    private func startDownloadProcess(for album: Album) {
        if isDownloading { return }
        isDownloading = true
        
        // 请求此专辑的所有歌曲
        SongAPI.getSongs(pageNum: 1, pageSize: 1000, collectionName: album.name) { [weak self] songResult in
            guard let self = self else { return }
            switch songResult {
            case .success(let pageResponse):
                let apiSongs = pageResponse.data?.voList ?? []
                if apiSongs.isEmpty {
                    self.isDownloading = false
                    self.showAlert(message: "该专辑暂无歌曲可供下载")
                    return
                }
                
                // 转换为 UI 模型
                let songs = apiSongs.map { song in
                    Song(id: "\(song.collectionSongsId ?? 0)",
                         name: song.songName ?? "未知歌曲",
                         artist: song.singer ?? "未知歌手",
                         source: (song.songNameSecret?.hasPrefix("http") == true) ? .changba : .unicom,
                         url: song.songNameSecret ?? "",
                         isFavorited: song.userIsCollect ?? true, // 刚收藏过
                         isPlaying: false,
                         isDownloaded: false)
                }
                
                self.showDownloadPopup(with: songs)
                
            case .failure(let error):
                self.isDownloading = false
                self.showAlert(message: "获取专辑歌曲失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func showDownloadPopup(with songs: [Song]) {
        // 展示弹窗
        downloadPopup = DownloadProgressView()
        downloadPopup?.show(in: self.navigationController?.view ?? self.view)
        downloadPopup?.updateProgress(current: 0, total: songs.count)
        
        downloadPopup?.onCancel = { [weak self] in
            self?.isDownloading = false
            print("用户取消了下载")
        }
        
        // 串行下载
        downloadNextSong(songs: songs, currentIndex: 0)
    }
    
    private func downloadNextSong(songs: [Song], currentIndex: Int) {
        guard isDownloading else { return } // 已取消
        
        if currentIndex >= songs.count {
            isDownloading = false
            downloadPopup?.finishDownload(total: songs.count)
            return
        }
        
        let song = songs[currentIndex]
        
        // 处理 URL (唱吧直链 vs 联通加密)
        if song.source == .unicom {
            SongAPI.getSongUrl(cid: song.url) { [weak self] result in
                switch result {
                case .success(let decryptedURL):
                    self?.performActualDownload(song: song, url: decryptedURL, allSongs: songs, currentIndex: currentIndex)
                case .failure(let error):
                    print("解密失败 \(song.name): \(error.localizedDescription)")
                    // 失败也继续下一首
                    self?.performActualDownload(song: song, url: "", allSongs: songs, currentIndex: currentIndex)
                }
            }
        } else {
            performActualDownload(song: song, url: song.url, allSongs: songs, currentIndex: currentIndex)
        }
    }
    
    private func performActualDownload(song: Song, url: String, allSongs: [Song], currentIndex: Int) {
        guard isDownloading else { return }
        print("开始下载: \(song.name) -> URL: \(url)")
        
        // 模拟下载到 UFI 目录并同步接口
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) { // 模拟下载耗时 1.5s
            DispatchQueue.main.async {
                guard self.isDownloading else { return }
                print("下载完成并同步接口: \(song.name)")
                
                self.downloadPopup?.updateProgress(current: currentIndex + 1, total: allSongs.count)
                // 递归下载下一首
                self.downloadNextSong(songs: allSongs, currentIndex: currentIndex + 1)
            }
        }
    }
}
