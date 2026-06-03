import Foundation
import AVFoundation
import UIKit

/// 音频播放管理器，封装原生 AVPlayer
class AudioPlayerManager {
    static let shared = AudioPlayerManager()
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    
    var isPlaying: Bool {
        return player?.rate != 0 && player?.error == nil
    }
    
    private init() {
        // 配置音频会话，支持后台播放
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
    }
    
    func pause() {
        player?.pause()
    }
    
    func resume() {
        player?.play()
    }
}

class SongPlaybackManager {
    static let shared = SongPlaybackManager()
    
    private init() {}
    
    /// 统一的播放鉴权与解密逻辑
    /// - Parameters:
    ///   - songName: 歌曲名称
    ///   - songSecret: 歌曲链接或加密串
    ///   - isDownloaded: 是否已下载
    ///   - viewController: 所在的控制器，用于弹窗
    ///   - onSuccess: 鉴权通过并准备开始播放时的回调（用于更新UI状态）
    func playSong(songName: String,
                  songSecret: String,
                  isDownloaded: Bool = false,
                  in viewController: UIViewController,
                  onSuccess: (() -> Void)? = nil) {
        
        print("准备播放: \(songName)")
        
        // 1. VIP 校验
        ProfileAPI.checkUserEndTime { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let resp):
                    if resp.hasPermission != true {
                        self?.showAlert(message: resp.msg ?? "会员已过期，请前往“我的”里面进行续费，谢谢", in: viewController)
                        return
                    }
                    
                    // 2. 蓝牙连接校验
                    let mac = BluetoothManager.shared.currentDeviceMAC ?? ""
                    let name = "BluetoothSpeaker" // 实际应该获取当前连接蓝牙名称
                    
                    if mac.isEmpty {
                        self?.showAlert(message: "当前设备未进行蓝牙连接，无法播放歌曲", in: viewController)
                        return
                    }
                    
                    // 3. 蓝牙权限校验
                    BluetoothAPI.checkBluetooth(mac: mac, name: name) { checkResult in
                        DispatchQueue.main.async {
                            switch checkResult {
                            case .success(let checkResp):
                                if checkResp.hasPermission == true {
                                    // 权限验证通过，触发成功回调
                                    onSuccess?()
                                    // 执行解密与播放
                                    self?.executePlay(songName: songName, songSecret: songSecret, isDownloaded: isDownloaded, in: viewController)
                                } else {
                                    self?.showAlert(message: checkResp.msg ?? "当前连接蓝牙设备超过可连接数量，可连接设备请查看我的蓝牙", in: viewController)
                                }
                            case .failure(let error):
                                self?.showAlert(message: "蓝牙权限校验失败: \(error.localizedDescription)", in: viewController)
                            }
                        }
                    }
                    
                case .failure(let error):
                    self?.showAlert(message: "会员校验失败: \(error.localizedDescription)", in: viewController)
                }
            }
        }
    }
    
    private func executePlay(songName: String, songSecret: String, isDownloaded: Bool, in viewController: UIViewController) {
        // 4. 检查本地下载
        if isDownloaded {
            print("💿 播放本地下载文件: \(songName)")
            // 模拟本地播放，展示弹窗
            self.showPlayerPopup(songName: songName, url: "local_file_path", in: viewController)
            return
        }
        
        // 5. 唱吧直链与联通解密区分
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
        // 复用 PlayerPopupView
        let popup = PlayerPopupView()
        popup.configure(songName: songName)
        if let view = viewController.navigationController?.view ?? viewController.view {
            popup.show(in: view)
        }
    }
    
    private func showAlert(message: String, in viewController: UIViewController) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        viewController.present(alert, animated: true)
    }
}
