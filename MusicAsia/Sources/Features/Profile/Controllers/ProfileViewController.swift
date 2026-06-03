import UIKit
import SnapKit

class ProfileViewController: BaseViewController {
    
    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let headerCard = ProfileCardView()
    private let songsStack = UIStackView()
    
    // Pagination footer
    private let footerView = UIView()
    private let loadMoreLabel = UILabel()
    private let arrowIcon = UIImageView(image: UIImage(systemName: "chevron.up.chevron.up"))
    
    // Floating Customer Service Button
    private let csButton = UIButton(type: .custom)
    
    // MARK: - Data
    private var displaySongs: [Song] = []
    
    private var currentPage = 1
    private let pageSize = 10
    private var isLoading = false
    private var hasMoreData = true
    
    // Download State
    private var isDownloading = false
    private var downloadPopup: BatchDownloadPopupView?
    
    private var isFirstLoad = true
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstLoad {
            isFirstLoad = false
            loadInitialData()
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = "我的"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.centerX.equalToSuperview()
        }
        
        view.addSubview(scrollView)
        scrollView.delegate = self
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(15)
            make.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }
        
        // 1. Header Card
        headerCard.onRenewTapped = { [weak self] in self?.handleRenew() }
        headerCard.orderBtn.addTarget(self, action: #selector(handleOrderTapped), for: .touchUpInside)
        headerCard.deviceBtn.addTarget(self, action: #selector(handleDeviceTapped), for: .touchUpInside)
        headerCard.backgroundColor = .clear
        contentView.addSubview(headerCard)
        headerCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.left.right.equalToSuperview().inset(15)
            make.height.equalTo(180)
        }
        
        let settingsContainer = UIView()
        settingsContainer.layer.cornerRadius = 4 // 修改为4px圆角
        settingsContainer.clipsToBounds = true
        headerCard.addSubview(settingsContainer)
        
        // 渐变底色 (与下方三个按钮底板保持一致)
        let settingsGradient = CAGradientLayer()
        settingsGradient.colors = [
            UIColor(hex: "#578CEF").withAlphaComponent(0.5).cgColor,
            UIColor(hex: "#371F99").withAlphaComponent(0.5).cgColor
        ]
        settingsGradient.startPoint = CGPoint(x: 0, y: 0.5)
        settingsGradient.endPoint = CGPoint(x: 1, y: 0.5)
        settingsContainer.layer.addSublayer(settingsGradient)
        
        let settingsBtn = UIButton(type: .custom)
        settingsBtn.addTarget(self, action: #selector(handleSettings), for: .touchUpInside)
        
        let settingsStack = UIStackView()
        settingsStack.axis = .horizontal
        settingsStack.spacing = 2
        settingsStack.alignment = .center
        settingsContainer.addSubview(settingsStack)
        
        let settingsLabel = UILabel()
        settingsLabel.text = "个人中心"
        settingsLabel.textColor = .white
        settingsLabel.font = .systemFont(ofSize: 12)
        settingsStack.addArrangedSubview(settingsLabel)
        
        let settingsIcon = UIImageView(image: UIImage(named: "setting_icon")?.withRenderingMode(.alwaysOriginal))
        settingsIcon.contentMode = .scaleAspectFill
        settingsStack.addArrangedSubview(settingsIcon)
        settingsIcon.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }
        
        settingsStack.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview() // 右侧无间距，完全贴边
        }
        
        settingsContainer.addSubview(settingsBtn)
        
        settingsContainer.snp.makeConstraints { make in
            make.top.right.equalToSuperview().inset(15)
            make.height.equalTo(16) // 高度和按钮大小一致
            make.width.equalTo(72)
        }
        
        settingsBtn.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 由于约束固定，直接赋值 frame 避免主线程异步带来的布局闪烁或卡顿
        settingsGradient.frame = CGRect(x: 0, y: 0, width: 72, height: 16)
        
        // 2. Section Header
        let sectionHeader = UIView()
        contentView.addSubview(sectionHeader)
        sectionHeader.snp.makeConstraints { make in
            make.top.equalTo(headerCard.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(30)
        }
        
        let indicator = UIView()
        indicator.backgroundColor = UIColor(hex: "#16E0BF")
        indicator.layer.cornerRadius = 1.5
        sectionHeader.addSubview(indicator)
        indicator.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.width.equalTo(3)
            make.height.equalTo(14)
        }
        
        let listTitle = UILabel()
        listTitle.text = "收藏歌曲"
        listTitle.textColor = .white
        listTitle.font = .systemFont(ofSize: 16, weight: .medium)
        sectionHeader.addSubview(listTitle)
        listTitle.snp.makeConstraints { make in
            make.left.equalTo(indicator.snp.right).offset(8)
            make.centerY.equalToSuperview()
        }
        
        // 下载歌曲容器
        let downloadContainer = UIView()
        downloadContainer.layer.cornerRadius = 4
        downloadContainer.clipsToBounds = true
        sectionHeader.addSubview(downloadContainer)
        
        let downloadGradient = CAGradientLayer()
        downloadGradient.colors = [
            UIColor(hex: "#578CEF").withAlphaComponent(0.85).cgColor,
            UIColor(hex: "#371F99").withAlphaComponent(0.85).cgColor
        ]
        downloadGradient.startPoint = CGPoint(x: 0, y: 0.5)
        downloadGradient.endPoint = CGPoint(x: 1, y: 0.5)
        downloadContainer.layer.addSublayer(downloadGradient)
        
        let downloadBtn = UIButton(type: .custom)
        downloadBtn.addTarget(self, action: #selector(handleBatchDownload), for: .touchUpInside)
        
        let downloadStack = UIStackView()
        downloadStack.axis = .horizontal
        downloadStack.spacing = 2
        downloadStack.alignment = .center
        downloadContainer.addSubview(downloadStack)
        
        let downloadIcon = UIImageView(image: UIImage(named: "download_icon")?.withRenderingMode(.alwaysOriginal))
        downloadIcon.contentMode = .scaleAspectFill
        downloadStack.addArrangedSubview(downloadIcon)
        downloadIcon.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }
        
        let downloadLabel = UILabel()
        downloadLabel.text = "下载歌曲"
        downloadLabel.textColor = .white
        downloadLabel.font = .systemFont(ofSize: 12)
        downloadStack.addArrangedSubview(downloadLabel)
        
        downloadStack.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview() 
        }
        
        downloadContainer.addSubview(downloadBtn)
        
        downloadContainer.snp.makeConstraints { make in
            make.right.centerY.equalToSuperview()
            make.height.equalTo(16)
            make.width.equalTo(72)
        }
        
        downloadBtn.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 由于约束固定，直接赋值 frame 避免主线程异步带来的布局闪烁或卡顿
        downloadGradient.frame = CGRect(x: 0, y: 0, width: 72, height: 16)
        
        // 3. Songs List
        songsStack.axis = .vertical
        songsStack.spacing = 20
        contentView.addSubview(songsStack)
        songsStack.snp.makeConstraints { make in
            make.top.equalTo(sectionHeader.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
            // 移除固定的 bottom 约束，交由动态更新
        }
        
        // 4. Footer
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
        contentView.addSubview(footerView)
        footerView.snp.makeConstraints { make in
            make.top.equalTo(songsStack.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
            make.height.equalTo(60)
        }
        
        // 5. Floating Customer Service Button
        csButton.setImage(UIImage(named: "customer_service_icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        csButton.contentHorizontalAlignment = .fill
        csButton.contentVerticalAlignment = .fill
        csButton.imageView?.contentMode = .scaleAspectFit
        csButton.backgroundColor = .clear // 移除原本写死的绿底色，使用切图自身的颜色/透明度
        csButton.addTarget(self, action: #selector(showCustomerService), for: .touchUpInside)
        view.addSubview(csButton)
        csButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.width.height.equalTo(36)
        }
    }
    
    // MARK: - Data Logic
    private func loadInitialData() {
        currentPage = 1
        hasMoreData = true
        displaySongs.removeAll()
        loadPageData()
    }
    
    private func loadPageData() {
        print("ProfileViewController: loadPageData() page \(currentPage)")
        isLoading = true
        
        ProfileAPI.getMeInfo(pageNum: currentPage, pageSize: pageSize) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let pageResponse):
                guard let data = pageResponse.data else { return }
                
                 let newSongs = data.voList ?? []
                 let uiSongs = newSongs.map { song in
                      Song(id: "\(song.collectionSongsId ?? 0)",
                           name: song.songName ?? "未知歌曲",
                           artist: song.singer ?? "未知歌手",
                           source: (song.songNameSecret?.hasPrefix("http") == true) ? .changba : .unicom,
                           url: song.songNameSecret ?? "",
                           isFavorited: true,
                           isPlaying: false,
                           isDownloaded: false)
                  }
                 
                 // 如果我们需要更新头部：由于原版代码使用了 nameLabel 和 idLabel,
                 // 但这个页面没有暴露，只有假数据。我们可以更新 UserDefaults
                 // 不过既然要求完美对接，我们可以先打印
                 print("用户信息: \(data.name ?? ""), VIP: \(data.endTime ?? "")")
                  
                  // A、展示个人信息及会员到期时间
                  let vipExpStr: String
                  if let endTime = data.endTime, !endTime.isEmpty {
                      vipExpStr = endTime
                  } else {
                      vipExpStr = "---"
                  }
                  
                  var logoUrl = data.logo ?? ""
                  logoUrl = logoUrl.replacingOccurrences(of: "\\", with: "/")
                  if logoUrl.contains("localhost") || logoUrl.contains("127.0.0.1") || logoUrl.contains("192.168.") {
                      if let pathIndex = logoUrl.range(of: "/", options: [], range: logoUrl.index(logoUrl.startIndex, offsetBy: 8)..<logoUrl.endIndex)?.lowerBound {
                          logoUrl = String(logoUrl[pathIndex...])
                      }
                  }
                  if !logoUrl.isEmpty && !logoUrl.hasPrefix("http") {
                      logoUrl = "http://47.243.180.202:48080" + (logoUrl.hasPrefix("/") ? "" : "/") + logoUrl
                  }
                  logoUrl = logoUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? logoUrl
                  
                  let finalName: String
                  if let name = data.name, !name.isEmpty {
                      finalName = name
                  } else if let phone = data.phone, !phone.isEmpty {
                      // 手机号脱敏处理：显示前三后四，中间星号
                      if phone.count == 11 {
                          let start = phone.index(phone.startIndex, offsetBy: 3)
                          let end = phone.index(phone.endIndex, offsetBy: -4)
                          finalName = phone[..<start] + "****" + phone[end...]
                      } else {
                          finalName = phone
                      }
                  } else {
                      finalName = "用户"
                  }
                  
                  let profileInfo = UserProfile(
                      name: finalName,
                      avatarUrl: logoUrl,
                      vipExpiration: nil,
                      formattedExpirationStr: vipExpStr
                  )
                  self.headerCard.configure(with: profileInfo)
                
                self.hasMoreData = newSongs.count == self.pageSize
                
                let startIndex = self.displaySongs.count
                if self.currentPage == 1 {
                    self.displaySongs = uiSongs
                    self.songsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
                } else {
                    self.displaySongs.append(contentsOf: uiSongs)
                }
                
                for (index, song) in uiSongs.enumerated() {
                    let actualIndex = startIndex + index
                    let row = ProfileSongRowView()
                    row.configure(with: song)
                    
                    row.onFavTapped = { [weak self] in
                        self?.handleUnfavorite(at: actualIndex)
                    }
                    
                    row.onSingTapped = { [weak self] in
                        self?.handleSing(at: actualIndex)
                    }
                    
                    self.songsStack.addArrangedSubview(row)
                    row.snp.makeConstraints { make in make.height.equalTo(44) }
                }
                
                self.updateFooterPosition()
                
            case .failure(let error):
                self.showAlert(message: "获取个人信息失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateFooterPosition() {
        let isHidden = self.displaySongs.isEmpty || !self.hasMoreData
        self.footerView.isHidden = isHidden
        
        self.contentView.snp.remakeConstraints { make in
            make.edges.width.equalToSuperview()
            if isHidden {
                make.bottom.equalTo(self.songsStack.snp.bottom).offset(20)
            } else {
                make.bottom.equalTo(self.footerView.snp.bottom).offset(100)
            }
        }
    }
    
    // MARK: - Actions
    @objc private func handleSettings() {
        let settingsVC = SettingsViewController()
        settingsVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    private func handleRenew() {
        print("跳转到购买套餐页面")
        let purchaseVC = PurchaseViewController()
        purchaseVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(purchaseVC, animated: true)
    }
    
    private func handleUnfavorite(at index: Int) {
        // B、取消收藏此首歌，并刷新列表
        let song = displaySongs[index]
        SongAPI.disCollectSong(collectionSongsId: Int(song.id) ?? 0) { [weak self] result in
            if case .success = result {
                self?.currentPage = 1
                self?.loadPageData()
            }
        }
    }
    
    @objc private func showCustomerService() {
        let popup = CustomerServicePopupView()
        popup.show(in: self.navigationController?.view ?? self.view)
    }
    
    @objc private func handleOrderTapped() {
        print("跳转到我的订单页面")
        let orderVC = OrderListViewController()
        orderVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(orderVC, animated: true)
    }
    
    @objc private func handleDeviceTapped() {
        print("跳转到我的设备页面")
        let deviceVC = DeviceViewController()
        deviceVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(deviceVC, animated: true)
    }
    
    // MARK: - Batch Download Logic (C)
    @objc private func handleBatchDownload() {
        // C1 -> C6 鉴权检查
        UfiManager.shared.checkDownloadPermission { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.startBatchDownloadProcess()
            case .failure(let error):
                self.showAlert(message: error.localizedDescription)
            }
        }
    }
    
    private func startBatchDownloadProcess() {
        if isDownloading { return }
        isDownloading = true
        
        // 需要使用设备的 deviceCode
        let deviceCode = UfiManager.shared.currentDeviceSerialNumber ?? ""
        
        // C7. 后端返回此用户未下载的最新200条歌曲 (替换为专门的接口)
        SongAPI.getCollectUnDownload(deviceCode: deviceCode) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let pageResponse):
                guard let data = pageResponse.data else {
                    self.isDownloading = false
                    self.showAlert(message: "暂无需要下载的歌曲")
                    return
                }
                let apiSongs = data.voList ?? []
                if apiSongs.isEmpty {
                    self.isDownloading = false
                    self.showAlert(message: "暂无需要下载的歌曲")
                    return
                }
                
                let songsToDownload = apiSongs.map { song in
                    Song(id: "\(song.collectionSongsId ?? 0)",
                         name: song.songName ?? "未知歌曲",
                         artist: song.singer ?? "未知歌手",
                         source: (song.songNameSecret?.hasPrefix("http") == true) ? .changba : .unicom,
                         url: song.songNameSecret ?? "",
                         isFavorited: true,
                         isPlaying: false,
                         isDownloaded: false)
                }
                
                // 展示弹窗
                self.downloadPopup = BatchDownloadPopupView()
                self.downloadPopup?.configure(count: songsToDownload.count)
                self.downloadPopup?.show(in: self.navigationController?.view ?? self.view)
                
                self.downloadPopup?.onCancel = { [weak self] in
                    // C9. 客户取消下载
                    self?.isDownloading = false
                    print("用户取消了批量下载")
                }
                
                // 串行下载
                self.downloadNextSong(songs: songsToDownload, currentIndex: 0)
                
            case .failure(let error):
                self.isDownloading = false
                self.showAlert(message: "获取待下载歌曲失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func downloadNextSong(songs: [Song], currentIndex: Int) {
        guard isDownloading else { return } // 已取消
        
        if currentIndex >= songs.count {
            // C9. 全部下完
            isDownloading = false
            downloadPopup?.finishDownload(count: songs.count)
            return
        }
        
        let song = songs[currentIndex]
        
        // C7. 处理 URL (唱吧直链 vs 联通加密)
        if song.source == .unicom {
            SongAPI.getSongUrl(cid: song.url) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let decryptedURL):
                        self?.performActualDownload(song: song, url: decryptedURL, allSongs: songs, currentIndex: currentIndex)
                    case .failure(let error):
                        print("批量下载解密失败 \(song.name): \(error.localizedDescription)")
                        // 失败也继续下一首
                        self?.performActualDownload(song: song, url: "", allSongs: songs, currentIndex: currentIndex)
                    }
                }
            }
        } else {
            performActualDownload(song: song, url: song.url, allSongs: songs, currentIndex: currentIndex)
        }
    }
    
    private func performActualDownload(song: Song, url: String, allSongs: [Song], currentIndex: Int) {
        guard isDownloading else { return }
        print("批量下载进度 [\(currentIndex + 1)/\(allSongs.count)]: \(song.name) -> URL: \(url)")
        
        // C8. 模拟下载到 UFI 目录并同步接口
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { // 加快模拟速度
            DispatchQueue.main.async {
                guard self.isDownloading else { return }
                
                // 下载完成后调用同步接口
                if let songId = Int(song.id) {
                    SongAPI.setCollectDownloaded(ids: [songId]) { _ in
                        print("✅ 已同步后台下载状态: \(song.name)")
                    }
                }
                
                // 递归下载下一首
                self.downloadNextSong(songs: allSongs, currentIndex: currentIndex + 1)
            }
        }
    }
    
    // MARK: - Sing Logic (D)
    private func handleSing(at index: Int) {
        var song = displaySongs[index]
        
        // 切换暂停状态
        if song.isPlaying {
            song.isPlaying = false
            AudioPlayerManager.shared.pause()
            updateSongState(at: index, song: song)
            return
        }
        
        SongPlaybackManager.shared.playSong(
            songName: song.name,
            songSecret: song.url,
            isDownloaded: song.isDownloaded,
            in: self
        ) { [weak self] in
            guard let self = self else { return }
            // 暂停其他所有歌曲
            for i in 0..<self.displaySongs.count {
                self.displaySongs[i].isPlaying = false
                if let r = self.songsStack.arrangedSubviews[i] as? ProfileSongRowView {
                    r.configure(with: self.displaySongs[i])
                }
            }
            // 权限验证通过，执行播放
            song.isPlaying = true
            self.displaySongs[index] = song
            if let row = self.songsStack.arrangedSubviews[index] as? ProfileSongRowView {
                row.configure(with: song)
            }
        }
    }
    
    private func updateSongState(at index: Int, song: Song) {
        displaySongs[index] = song
        if let row = songsStack.arrangedSubviews[index] as? ProfileSongRowView {
            row.configure(with: song)
        }
    }
}

extension ProfileViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        // 防御：只有在内容高度大于视图高度，并且滚动到了底部时才触发
        if contentHeight > 0 && offsetY > contentHeight - height + 20 {
            if hasMoreData && !isLoading {
                currentPage += 1
                loadPageData()
            }
        }
    }
}
