import Foundation
import AVFoundation

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
