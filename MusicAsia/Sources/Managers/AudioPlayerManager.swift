import Foundation
import AVFoundation
import UIKit

class AudioPlayerManager {
    static let shared = AudioPlayerManager()
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    
    var isPlaying: Bool {
        return player?.rate != 0 && player?.error == nil
    }
    
    private init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    func play(url: URL) {
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.play()
        NotificationCenter.default.post(name: NSNotification.Name("PlayerStateChanged"), object: nil)
    }
    
    func pause() {
        player?.pause()
        NotificationCenter.default.post(name: NSNotification.Name("PlayerStateChanged"), object: nil)
    }
    
    func resume() {
        player?.play()
        NotificationCenter.default.post(name: NSNotification.Name("PlayerStateChanged"), object: nil)
    }
    
    func stop() {
        player?.pause()
        player = nil
        playerItem = nil
        NotificationCenter.default.post(name: NSNotification.Name("PlayerStateChanged"), object: nil)
    }
}

class SongPlaybackManager {
    static let shared = SongPlaybackManager()
    
    var currentSongName: String?
    var currentSongSecret: String?
    
    private init() {}
    
    func stop() {
        AudioPlayerManager.shared.stop()
        currentSongName = nil
        currentSongSecret = nil
    }
    
    /// 统一的播放鉴权与解密逻辑
    /// - Parameters:
    ///   - songName: 歌曲名称
    ///   - songSecret: 歌曲链接或加密串
    ///   - isDownloaded: 是否已下载
    ///   - isTrial: 是否为试听歌曲（跳过VIP鉴权）
    ///   - viewController: 所在的控制器，用于弹窗
    ///   - onSuccess: 鉴权通过并准备开始播放时的回调（用于更新UI状态）
    func playSong(songName: String,
                  songSecret: String,
                  isDownloaded: Bool = false,
                  isTrial: Bool = false,
                  in viewController: UIViewController,
                  onSuccess: (() -> Void)? = nil) {
        
        if currentSongSecret == songSecret {
            if AudioPlayerManager.shared.isPlaying {
                AudioPlayerManager.shared.pause()
            } else {
                AudioPlayerManager.shared.resume()
            }
            onSuccess?()
            return
        }
        
        print("准备播放: \(songName)")
        
        if isTrial {
            self.checkBluetoothAndPlay(songName: songName, songSecret: songSecret, isDownloaded: isDownloaded, isTrial: isTrial, onSuccess: onSuccess, viewController: viewController)
        } else {
            ProfileAPI.checkUserEndTime { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let resp):
                        if resp.hasPermission != true {
                            self?.showAlert(message: resp.msg ?? "会员已过期，请前往“我的”里面进行续费，谢谢", in: viewController)
                            return
                        }
                        
                        self?.checkBluetoothAndPlay(songName: songName, songSecret: songSecret, isDownloaded: isDownloaded, isTrial: isTrial, onSuccess: onSuccess, viewController: viewController)
                        
                    case .failure(let error):
                        self?.showAlert(message: "会员校验失败: \(error.localizedDescription)", in: viewController)
                    }
                }
            }
        }
    }
    
    private func checkBluetoothAndPlay(songName: String, songSecret: String, isDownloaded: Bool, isTrial: Bool, onSuccess: (() -> Void)?, viewController: UIViewController) {
        BluetoothManager.shared.getAvailableBluetoothName { [weak self] bluetoothName in
            DispatchQueue.main.async {
                if !BluetoothManager.shared.isBluetoothPoweredOn {
                    let alert = UIAlertController(title: "提示", message: "请在系统设置中打开蓝牙并允许App使用蓝牙权限", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "取消", style: .cancel))
                    alert.addAction(UIAlertAction(title: "去设置", style: .default, handler: { _ in
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }))
                    viewController.present(alert, animated: true)
                    return
                }
                
                guard let name = bluetoothName, !name.isEmpty else {
                    self?.showAlert(message: "当前设备未进行蓝牙连接，无法播放歌曲", in: viewController)
                    return
                }
                
                if isTrial {
                    self?.currentSongName = songName
                    self?.currentSongSecret = songSecret
                    onSuccess?()
                    self?.executePlay(songName: songName, songSecret: songSecret, isDownloaded: isDownloaded, in: viewController)
                } else {
                    self?.checkBluetoothPermission(mac: name, name: name, songName: songName, songSecret: songSecret, isDownloaded: isDownloaded, onSuccess: onSuccess, viewController: viewController)
                }
            }
        }
    }
    
    private func checkBluetoothPermission(mac: String?, name: String?, songName: String, songSecret: String, isDownloaded: Bool, onSuccess: (() -> Void)?, viewController: UIViewController) {
        BluetoothAPI.checkBluetooth(mac: mac, name: name) { [weak self] checkResult in
            DispatchQueue.main.async {
                switch checkResult {
                case .success(let checkResp):
                    if checkResp.hasPermission == true {
                        self?.currentSongName = songName
                        self?.currentSongSecret = songSecret
                        onSuccess?()
                        self?.executePlay(songName: songName, songSecret: songSecret, isDownloaded: isDownloaded, in: viewController)
                    } else {
                        self?.showAlert(message: checkResp.msg ?? "无权限播放", in: viewController)
                    }
                case .failure(let error):
                    self?.showAlert(message: error.localizedDescription, in: viewController)
                }
            }
        }
    }
    
    private func executePlay(songName: String, songSecret: String, isDownloaded: Bool, in viewController: UIViewController) {
        if isDownloaded {
            print("💿 播放本地下载文件: \(songName)")
            self.showPlayerPopup(songName: songName, url: "local_file_path", in: viewController)
            return
        }
        
        let isChangba = songSecret.hasPrefix("http")
        
        if isChangba {
            let playUrl = songSecret.hasSuffix(".mp3") ? songSecret : songSecret + ".mp3"
            print("▶️ 播放唱吧直链: \(playUrl)")
            if let url = URL(string: playUrl) {
                AudioPlayerManager.shared.play(url: url)
                self.showPlayerPopup(songName: songName, url: playUrl, in: viewController)
            }
        } else {
            print("⏳ 请求后台解密联通 URL...")
            SongAPI.getSongUrl(cid: songSecret) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let decryptedUrlStr):
                        print("▶️ 播放解密后的联通链接: \(decryptedUrlStr)")
                        if let url = URL(string: decryptedUrlStr) {
                            AudioPlayerManager.shared.play(url: url)
                            self?.showPlayerPopup(songName: songName, url: decryptedUrlStr, in: viewController)
                        }
                    case .failure(let error):
                        self?.showAlert(message: "解密歌曲失败: \(error.localizedDescription)", in: viewController)
                    }
                }
            }
        }
    }
    
    private func showPlayerPopup(songName: String, url: String, in viewController: UIViewController) {
        DispatchQueue.main.async {
            GlobalFloatPlayerView.shared.show(songName: songName)
        }
    }
    
    private func showAlert(message: String, in viewController: UIViewController) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        viewController.present(alert, animated: true)
    }
}

class GlobalFloatPlayerView: UIView {
    static let shared = GlobalFloatPlayerView()
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let playPauseButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)
    private let collapseButton = UIButton(type: .system)
    
    private var isCollapsed = false
    private var currentSongName: String = ""
    
    private init() {
        super.init(frame: .zero)
        setupUI()
        setupGestures()
        NotificationCenter.default.addObserver(self, selector: #selector(handleStateChanged), name: NSNotification.Name("PlayerStateChanged"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupUI() {
        backgroundColor = .clear
        
        containerView.backgroundColor = UIColor(hex: "#2C2C2E")
        containerView.layer.cornerRadius = 25
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowRadius = 8
        addSubview(containerView)
        
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textAlignment = .left
        titleLabel.lineBreakMode = .byTruncatingTail
        containerView.addSubview(titleLabel)
        
        playPauseButton.tintColor = UIColor(hex: "#16E0BF")
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        playPauseButton.addTarget(self, action: #selector(playPauseAction), for: .touchUpInside)
        containerView.addSubview(playPauseButton)
        
        collapseButton.tintColor = .white
        collapseButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        collapseButton.addTarget(self, action: #selector(collapseAction), for: .touchUpInside)
        containerView.addSubview(collapseButton)
        
        closeButton.tintColor = .white
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        containerView.addSubview(closeButton)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        collapseButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(collapseButton.snp.right).offset(8)
            make.centerY.equalToSuperview()
            make.width.lessThanOrEqualTo(100)
        }
        
        playPauseButton.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(10)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
        
        closeButton.snp.makeConstraints { make in
            make.left.equalTo(playPauseButton.snp.right).offset(8)
            make.right.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
    }
    
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.addGestureRecognizer(panGesture)
    }
        
    @objc private func handleStateChanged() {
        updatePlayState(isPlaying: AudioPlayerManager.shared.isPlaying)
    }
    
    @objc private func playPauseAction() {
        if AudioPlayerManager.shared.isPlaying {
            AudioPlayerManager.shared.pause()
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            AudioPlayerManager.shared.resume()
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
        NotificationCenter.default.post(name: NSNotification.Name("PlayerStateChanged"), object: nil)
    }
    
    @objc private func collapseAction() {
        isCollapsed.toggle()
        
        let transform = isCollapsed ? CGAffineTransform(rotationAngle: .pi) : .identity
        
        UIView.animate(withDuration: 0.3, animations: {
            self.collapseButton.transform = transform
            self.titleLabel.alpha = self.isCollapsed ? 0 : 1
            self.playPauseButton.alpha = self.isCollapsed ? 0 : 1
            self.closeButton.alpha = self.isCollapsed ? 0 : 1
            
            if self.isCollapsed {
                self.titleLabel.snp.remakeConstraints { make in
                    make.left.equalTo(self.collapseButton.snp.right).offset(0)
                    make.centerY.equalToSuperview()
                    make.width.equalTo(0)
                }
                self.playPauseButton.snp.remakeConstraints { make in
                    make.left.equalTo(self.titleLabel.snp.right).offset(0)
                    make.centerY.equalToSuperview()
                    make.width.height.equalTo(0)
                }
                self.closeButton.snp.remakeConstraints { make in
                    make.left.equalTo(self.playPauseButton.snp.right).offset(0)
                    make.right.equalToSuperview().offset(-12)
                    make.centerY.equalToSuperview()
                    make.width.height.equalTo(0)
                }
            } else {
                self.titleLabel.snp.remakeConstraints { make in
                    make.left.equalTo(self.collapseButton.snp.right).offset(8)
                    make.centerY.equalToSuperview()
                    make.width.lessThanOrEqualTo(100)
                }
                self.playPauseButton.snp.remakeConstraints { make in
                    make.left.equalTo(self.titleLabel.snp.right).offset(10)
                    make.centerY.equalToSuperview()
                    make.width.height.equalTo(30)
                }
                self.closeButton.snp.remakeConstraints { make in
                    make.left.equalTo(self.playPauseButton.snp.right).offset(8)
                    make.right.equalToSuperview().offset(-12)
                    make.centerY.equalToSuperview()
                    make.width.height.equalTo(24)
                }
            }
            self.layoutIfNeeded()
        })
    }
    
    @objc private func closeAction() {
        SongPlaybackManager.shared.stop()
        self.removeFromSuperview()
        NotificationCenter.default.post(name: NSNotification.Name("PlayerStateChanged"), object: nil)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = self.superview else { return }
        
        let translation = gesture.translation(in: superview)
        
        if gesture.state == .changed {
            self.center = CGPoint(x: self.center.x + translation.x, y: self.center.y + translation.y)
            gesture.setTranslation(.zero, in: superview)
        } else if gesture.state == .ended || gesture.state == .cancelled {
            let safeArea = superview.safeAreaInsets
            let padding: CGFloat = 16
            
            var targetX = self.center.x
            var targetY = self.center.y
            
            if self.frame.minX < superview.bounds.midX {
                targetX = padding + self.bounds.width / 2
            } else {
                targetX = superview.bounds.width - padding - self.bounds.width / 2
            }
            
            targetY = max(safeArea.top + padding + self.bounds.height / 2, targetY)
            targetY = min(superview.bounds.height - safeArea.bottom - padding - self.bounds.height / 2, targetY)
            
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                self.center = CGPoint(x: targetX, y: targetY)
            }, completion: nil)
        }
    }
        
    func show(songName: String) {
        self.currentSongName = songName
        self.titleLabel.text = songName
        self.playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        
        if self.superview == nil {
            guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
            window.addSubview(self)
            
            let bottomPadding = window.safeAreaInsets.bottom + 80 // Adjust based on tab bar
            
            self.snp.makeConstraints { make in
                make.right.equalToSuperview().offset(-16)
                make.bottom.equalToSuperview().offset(-bottomPadding)
                make.height.equalTo(50)
            }
        }
    }
    
    func updatePlayState(isPlaying: Bool) {
        let iconName = isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.setImage(UIImage(systemName: iconName), for: .normal)
    }
    
    private func showAlert(message: String, in viewController: UIViewController) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        viewController.present(alert, animated: true)
    }
}
