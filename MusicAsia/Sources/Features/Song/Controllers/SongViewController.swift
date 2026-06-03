import UIKit
import SnapKit

class SongViewController: BaseViewController {
    
    // MARK: - UI
    private let searchContainer = UIView()
    private let searchTextField = UITextField()
    
    private let tabStackView = UIStackView()
    private let tabIndicator = UIView()
    private var tabButtons: [UIButton] = []
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let songsStack = UIStackView()
    
    // Pagination footer
    private let footerView = UIView()
    private let loadMoreLabel = UILabel()
    private let arrowIcon = UIImageView(image: UIImage(systemName: "chevron.up.chevron.up"))
    
    // MARK: - Data
    private var currentCategory: SongCategory = .guess
    private var displaySongs: [Song] = []
    
    private var currentPage = 1
    private let pageSize = 10
    private var isSearching = false
    private var isLoading = false
    private var hasMoreData = true
    
    /// 如果从专辑页面跳转过来，会传这个值
    var sourceAlbumId: String?
    var sourceAlbumName: String?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        switchTab(index: 0) // 默认猜你喜欢
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if sourceAlbumId != nil {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        } else {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
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
            string: "请输入歌名或歌手",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.5)]
        )
        searchTextField.returnKeyType = .search
        searchTextField.delegate = self
        searchContainer.addSubview(searchTextField)
        
        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = UIColor(hex: "#16E0BF")
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
        
        // 2. Tabs
        let titles = ["猜你喜欢", "热歌榜", "新歌榜", "K歌榜"]
        for (index, title) in titles.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(title, for: .normal)
            btn.tag = index
            btn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            tabButtons.append(btn)
            tabStackView.addArrangedSubview(btn)
        }
        tabStackView.axis = .horizontal
        tabStackView.distribution = .fillEqually
        view.addSubview(tabStackView)
        
        tabStackView.snp.makeConstraints { make in
            make.top.equalTo(searchContainer.snp.bottom).offset(15)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(40)
        }
        
        tabIndicator.backgroundColor = UIColor(hex: "#16E0BF")
        view.addSubview(tabIndicator)
        // 初始位置设定在第一个
        tabIndicator.snp.makeConstraints { make in
            make.top.equalTo(tabStackView.snp.bottom)
            make.height.equalTo(2)
            make.width.equalTo(40)
            make.centerX.equalTo(tabButtons[0])
        }
        
        // 3. ScrollView & List
        view.addSubview(scrollView)
        scrollView.delegate = self
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(tabIndicator.snp.bottom).offset(10)
            make.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }
        
        songsStack.axis = .vertical
        songsStack.spacing = 20
        contentView.addSubview(songsStack)
        songsStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-80) // 预留初始空间
        }
        
        // 4. Footer
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
        
        scrollView.addSubview(footerView)
    }
    
    // MARK: - Tab Logic
    @objc private func tabTapped(_ sender: UIButton) {
        if isSearching {
            // 搜索状态下点击 tab，清空搜索
            searchTextField.text = ""
            isSearching = false
        }
        switchTab(index: sender.tag)
    }
    
    private func switchTab(index: Int) {
        let categories: [SongCategory] = [.guess, .hot, .new, .ksong]
        currentCategory = categories[index]
        
        for (i, btn) in tabButtons.enumerated() {
            let isSelected = (i == index)
            btn.setTitleColor(isSelected ? .white : UIColor.white.withAlphaComponent(0.6), for: .normal)
            btn.titleLabel?.font = isSelected ? .systemFont(ofSize: 18, weight: .bold) : .systemFont(ofSize: 15, weight: .regular)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.tabIndicator.snp.remakeConstraints { make in
                make.top.equalTo(self.tabStackView.snp.bottom)
                make.height.equalTo(2)
                make.width.equalTo(40)
                make.centerX.equalTo(self.tabButtons[index])
            }
            self.view.layoutIfNeeded()
        }
        
        loadInitialData()
    }
    
    // MARK: - Data Logic
    private func loadInitialData() {
        currentPage = 1
        hasMoreData = true
        loadPageData()
    }
    
    private func loadPageData() {
        print("SongViewController: loadPageData() page \(currentPage) for category \(currentCategory)")
        let searchText = searchTextField.text ?? ""
        
        let completion: (Result<BasePageResponse<CollectionSongsResp>, NetworkError>) -> Void = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let pageResponse):
                let newSongs = pageResponse.data?.voList ?? []
                let uiSongs = newSongs.map { song in
                    Song(id: "\(song.collectionSongsId ?? 0)",
                         name: song.songName ?? "未知歌曲",
                         artist: song.singer ?? "未知歌手",
                         source: (song.songNameSecret?.hasPrefix("http") == true) ? .changba : .unicom,
                         url: song.songNameSecret ?? "",
                         isFavorited: song.userIsCollect ?? false,
                         isPlaying: false,
                         isDownloaded: false)
                }
                
                self.hasMoreData = newSongs.count == self.pageSize
                
                if self.currentPage == 1 {
                    self.displaySongs = uiSongs
                } else {
                    self.displaySongs.append(contentsOf: uiSongs)
                }
                self.refreshListUI()
                self.isLoading = false
                
            case .failure(let error):
                self.isLoading = false
                self.showAlert(message: "获取歌曲列表失败: \(error.localizedDescription)")
            }
        }
        
        isLoading = true
        
        if isSearching {
            // 如果在搜索，直接走 getSongs 搜索名字
            SongAPI.getSongs(pageNum: currentPage, pageSize: pageSize, songName: searchText, completion: completion)
            return
        }
        
        // 否则根据 Category 加载不同接口
        switch currentCategory {
        case .guess: // 猜你喜欢
            if let albumName = sourceAlbumName {
                SongAPI.getSongs(pageNum: currentPage, pageSize: pageSize, collectionName: albumName, completion: completion)
            } else {
                SongAPI.getGuessLike(pageNum: currentPage, pageSize: pageSize, completion: completion)
            }
        case .hot: // 热歌榜
            SongAPI.getSongs(pageNum: currentPage, pageSize: pageSize, hotChart: "1", completion: completion)
        case .new: // 新歌榜
            SongAPI.getSongs(pageNum: currentPage, pageSize: pageSize, newChart: "1", completion: completion)
        case .ksong: // K歌榜
            SongAPI.getSongs(pageNum: currentPage, pageSize: pageSize, kChart: "1", completion: completion)
        }
    }
    
    private func refreshListUI() {
        songsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, song) in displaySongs.enumerated() {
            let row = SongRowView()
            row.configure(with: song)
            row.onFavTapped = { [weak self] in
                self?.handleFav(at: index, songId: Int(song.id) ?? 0, isFav: song.isFavorited)
            }
            row.onPlayTapped = { [weak self] in
                self?.handlePlay(at: index, song: song)
            }
            songsStack.addArrangedSubview(row)
            row.snp.makeConstraints { make in make.height.equalTo(44) }
        }
        updateFooterPosition()
    }
    
    private func updateFooterPosition() {
        DispatchQueue.main.async {
            self.view.layoutIfNeeded()
            let contentHeight = self.songsStack.frame.height + 20
            self.footerView.frame.origin.y = contentHeight
            self.footerView.isHidden = contentHeight == 0 || !self.hasMoreData
            
            self.songsStack.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(10)
                make.left.right.equalToSuperview().inset(20)
            }
            
            if self.footerView.isHidden {
                self.contentView.snp.remakeConstraints { make in
                    make.edges.width.equalToSuperview()
                    make.bottom.equalTo(self.songsStack.snp.bottom).offset(20)
                }
            } else {
                self.contentView.snp.remakeConstraints { make in
                    make.edges.width.equalToSuperview()
                    make.bottom.equalTo(self.footerView.snp.bottom).offset(30)
                }
            }
            self.view.layoutIfNeeded()
        }
    }
    
    private func performSearch(keyword: String) {
        if keyword.isEmpty {
            isSearching = false
            // 恢复当前 Tab
            if let index = tabButtons.firstIndex(where: { $0.titleLabel?.font.pointSize == 18 }) {
                switchTab(index: index)
            } else {
                switchTab(index: 0)
            }
        } else {
            isSearching = true
            // 搜索时不关联专辑，搜索全部
            loadInitialData()
            
            // 将 Tab 全部置灰
            for btn in tabButtons {
                btn.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .normal)
                btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .regular)
            }
            tabIndicator.isHidden = true
        }
    }
    
    // MARK: - Actions (A & B)
    private func handleFav(at index: Int, songId: Int, isFav: Bool) {
        if isFav {
            SongAPI.disCollectSong(collectionSongsId: songId) { [weak self] result in
                if case .success = result {
                    self?.loadPageData() // 刷新当前页
                }
            }
        } else {
            SongAPI.collectSong(collectionSongsId: songId, type: "1") { [weak self] result in
                if case .success = result {
                    self?.showCollectSuccessPopup()
                    self?.loadPageData()
                }
            }
        }
    }
    
    private func handlePlay(at index: Int, song: Song) {
        SongPlaybackManager.shared.playSong(
            songName: song.name,
            songSecret: song.url,
            isDownloaded: song.isDownloaded,
            in: self
        ) { [weak self] in
            // UI 更新
            guard let self = self else { return }
            var updatedSong = song
            updatedSong.isPlaying = true
            self.updateSongState(at: index, song: updatedSong)
        }
    }
    
    private func updateSongState(at index: Int, song: Song) {
        // Just empty method for old reference if any
    }
}

extension SongViewController: UITextFieldDelegate, UIScrollViewDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        performSearch(keyword: textField.text ?? "")
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text, let textRange = Range(range, in: text) {
            let updatedText = text.replacingCharacters(in: textRange, with: string)
            performSearch(keyword: updatedText)
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        performSearch(keyword: "")
        tabIndicator.isHidden = false
        return true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        if offsetY > contentHeight - height + 20 {
            if hasMoreData && !isLoading {
                currentPage += 1
                loadPageData()
            }
        }
    }
}
