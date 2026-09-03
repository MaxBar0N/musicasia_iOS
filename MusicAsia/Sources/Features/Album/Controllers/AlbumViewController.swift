import UIKit
import SnapKit

class AlbumViewController: BaseViewController {
    
    // MARK: - UI
    private let searchContainer = UIView()
    private let searchTextField = UITextField()
    
    private var collectionView: UICollectionView!
    private let refreshControl = UIRefreshControl()
    
    // Pagination footer
    private let footerView = UIView()
    private let loadMoreLabel = UILabel()
    private let arrowIcon = UIImageView(image: UIImage(systemName: "chevron.up.chevron.up"))
    
    // MARK: - Data
    private var allAlbums: [Album] = []
    private var displayAlbums: [Album] = []
    
    private var currentPage = 1
    private let pageSize = 10
    private var isSearching = false
    private var isLoading = false
    private var hasMoreData = true
    
    // Download State
    private var isDownloading = false
    private var downloadPopup: DownloadProgressView?
    
    private var currentSearchKeyword: String = ""

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadInitialData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // 1. Search Bar
        searchContainer.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        searchContainer.layer.cornerRadius = 20
        view.addSubview(searchContainer)
        
        searchTextField.textColor = .white
        searchTextField.font = .systemFont(ofSize: 15)
        searchTextField.attributedPlaceholder = NSAttributedString(
            string: "请输入专辑名",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.5)]
        )
        searchTextField.returnKeyType = .search
        searchTextField.delegate = self
        searchContainer.addSubview(searchTextField)
        
        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = UIColor(hex: "#16E0BF")
        searchIcon.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSearchIconTapped))
        searchIcon.addGestureRecognizer(tapGesture)
        searchContainer.addSubview(searchIcon)
        
        searchContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(40)
        }
        
        searchTextField.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
            make.right.equalTo(searchIcon.snp.left).offset(-10)
        }
        
        searchIcon.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-15)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        
        // 2. Collection View
        let layout = UICollectionViewFlowLayout()
        let width = (UIScreen.main.bounds.width - 40 - 15) / 2
        layout.itemSize = CGSize(width: width, height: width * 0.8) // 比例类似设计图
        layout.minimumInteritemSpacing = 15
        layout.minimumLineSpacing = 15
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(AlbumGridCell.self, forCellWithReuseIdentifier: "AlbumGridCell")
        view.addSubview(collectionView)
        
        refreshControl.tintColor = UIColor(hex: "#16E0BF")
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(searchContainer.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        // 3. Footer (上滑加载更多)
        footerView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 60)
        loadMoreLabel.text = "上滑加载更多"
        loadMoreLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        loadMoreLabel.font = .systemFont(ofSize: 12)
        arrowIcon.tintColor = UIColor.white.withAlphaComponent(0.6)
        
        footerView.addSubview(arrowIcon)
        footerView.addSubview(loadMoreLabel)
        
        arrowIcon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(10)
            make.width.height.equalTo(16)
        }
        loadMoreLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(arrowIcon.snp.bottom).offset(5)
        }
        
        // Use contentInset to make room for footer visually
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        collectionView.addSubview(footerView)
    }
    
    // MARK: - Data Logic (D. 上滑加载更多 / C. 搜索)
    private func loadInitialData() {
        currentPage = 1
        hasMoreData = true
        loadPageData()
    }
    
    @objc private func handleRefresh() {
        loadInitialData()
    }
    
    private func loadPageData() {
        print("AlbumViewController: loadPageData() page \(currentPage)")
        let searchText = currentSearchKeyword
        
        if currentPage == 1 && !refreshControl.isRefreshing {
            showLoading()
        }
        
        AlbumAPI.getAlbums(pageNum: currentPage, pageSize: pageSize, collectionName: searchText) { [weak self] result in
            guard let self = self else { return }
            self.hideLoading()
            self.refreshControl.endRefreshing()
            switch result {
            case .success(let pageResponse):
                let newAlbums = pageResponse.data?.voList ?? []
                let uiAlbums = newAlbums.map { album in
                    var imageUrl = album.collectionImg ?? ""
                    imageUrl = imageUrl.replacingOccurrences(of: "\\", with: "/")
                    
                    if imageUrl.contains("localhost") || imageUrl.contains("127.0.0.1") || imageUrl.contains("192.168.") {
                        if let pathIndex = imageUrl.range(of: "/", options: [], range: imageUrl.index(imageUrl.startIndex, offsetBy: 8)..<imageUrl.endIndex)?.lowerBound {
                            imageUrl = String(imageUrl[pathIndex...])
                        }
                    }
                    
                    if !imageUrl.isEmpty && !imageUrl.hasPrefix("http") {
                        imageUrl = APIConfig.webBaseURL + (imageUrl.hasPrefix("/") ? "" : "/") + imageUrl
                    }
                    
                    // 避免重复编码
                    if URL(string: imageUrl) == nil {
                        imageUrl = imageUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? imageUrl
                    }
                    
                    return Album(id: "\(album.musicCollectionId ?? 0)",
                          name: album.collectionName ?? "未知专辑",
                          coverUrl: imageUrl,
                          isFavorited: false)
                }
                
                self.hasMoreData = newAlbums.count == self.pageSize
                
                if self.currentPage == 1 {
                    self.displayAlbums = uiAlbums
                } else {
                    self.displayAlbums.append(contentsOf: uiAlbums)
                }
                self.collectionView.reloadData()
                self.updateFooterPosition()
                self.isLoading = false
                
            case .failure(let error):
                self.isLoading = false
                self.showAlert(message: "获取专辑列表失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateFooterPosition() {
        DispatchQueue.main.async {
            let contentHeight = self.collectionView.collectionViewLayout.collectionViewContentSize.height
            self.footerView.frame.origin.y = contentHeight
            self.footerView.isHidden = contentHeight == 0 || !self.hasMoreData
        }
    }
    
    private func performSearch(keyword: String) {
        currentSearchKeyword = keyword
        isSearching = !keyword.isEmpty
        currentPage = 1
        hasMoreData = true
        loadPageData()
    }
    
    @objc private func handleSearchIconTapped() {
        searchTextField.resignFirstResponder()
        performSearch(keyword: searchTextField.text ?? "")
    }
    
    // MARK: - Action A: Download & Favorite
    private func handleDownload(for album: Album) {
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
        // A1 -> A6 鉴权检查 (U 盘与会员等权限)
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
        
        // A8. 请求此专辑的所有歌曲
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
            // A10. 客户取消下载
            self?.isDownloading = false
            print("用户取消了下载")
        }
        
        // 串行下载
        downloadNextSong(songs: songs, currentIndex: 0)
    }
    
    private func downloadNextSong(songs: [Song], currentIndex: Int) {
        guard isDownloading else { return } // 已取消
        
        if currentIndex >= songs.count {
            // A10. 全部下完
            isDownloading = false
            downloadPopup?.finishDownload(total: songs.count)
            return
        }
        
        let song = songs[currentIndex]
        
        // A8. 处理 URL (唱吧直链 vs 联通加密)
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
        
        // A9. 模拟下载到 UFI 目录并同步接口
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

// MARK: - CollectionView Delegate & DataSource
extension AlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayAlbums.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumGridCell", for: indexPath) as! AlbumGridCell
        let album = displayAlbums[indexPath.row]
        cell.configure(with: album)
        
        cell.onDownloadTapped = { [weak self] in
            self?.handleDownload(for: album)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // B、演唱（专辑）；跳转到歌曲列表，并在“猜你喜欢”的tab中显示此专辑的所有歌曲
        let album = displayAlbums[indexPath.row]
        let songVC = SongViewController()
        songVC.sourceAlbumId = album.id // 传入 albumId 以便显示此专辑的歌曲
        songVC.sourceAlbumName = album.name
        songVC.title = "猜你喜欢 - \(album.name)"
        songVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(songVC, animated: true)
    }
    
    // UIScrollViewDelegate for Pagination
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isSearching else { return }
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        // 滑动到底部触发加载更多，防御下拉刷新导致的错误触发
        if offsetY > 0 && offsetY > contentHeight - height + 20 {
            if hasMoreData && !isLoading {
                isLoading = true
                currentPage += 1
                loadPageData()
            }
        }
    }
}

// MARK: - UITextField Delegate (Search)
extension AlbumViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        performSearch(keyword: textField.text ?? "")
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        if let textRange = Range(range, in: currentText) {
            let updatedText = currentText.replacingCharacters(in: textRange, with: string)
            performSearch(keyword: updatedText)
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textField.text = ""
        performSearch(keyword: "")
        return false
    }
}
