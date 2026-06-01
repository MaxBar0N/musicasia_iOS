import UIKit
import SnapKit
import Kingfisher

// MARK: - Album Grid Cell
class AlbumGridCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    let downloadButton = UIButton(type: .system)
    
    var onDownloadTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        
        imageView.contentMode = .scaleAspectFill
        contentView.addSubview(imageView)
        
        // 底部渐变遮罩
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.7).cgColor]
        let overlay = UIView()
        overlay.layer.addSublayer(gradientLayer)
        contentView.addSubview(overlay)
        
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        contentView.addSubview(titleLabel)
        
        // 下载按钮使用本地资源
        downloadButton.setImage(UIImage(named: "download_icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        downloadButton.contentHorizontalAlignment = .fill
        downloadButton.contentVerticalAlignment = .fill
        downloadButton.imageView?.contentMode = .scaleAspectFit
        downloadButton.addTarget(self, action: #selector(downloadAction), for: .touchUpInside)
        contentView.addSubview(downloadButton)
        
        // Layout
        imageView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        
        overlay.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(40)
        }
        
        downloadButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-8)
            make.bottom.equalToSuperview().offset(-8)
            make.width.height.equalTo(20)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.centerY.equalTo(downloadButton)
            make.right.equalTo(downloadButton.snp.left).offset(-8)
        }
        
        DispatchQueue.main.async {
            gradientLayer.frame = overlay.bounds
        }
    }
    
    func configure(with album: Album) {
        titleLabel.text = album.name
        if let url = URL(string: album.coverUrl) {
            print("AlbumGridCell Loading URL: \(url.absoluteString)")
            imageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "music.note.list"),
                options: nil,
                completionHandler: { result in
                    switch result {
                    case .success(let value):
                        print("AlbumGridCell Image loaded successfully: \(value.source.url?.absoluteString ?? "")")
                    case .failure(let error):
                        print("AlbumGridCell Image load failed: \(error.localizedDescription) for URL: \(url.absoluteString)")
                    }
                }
            )
        } else {
            print("AlbumGridCell Invalid URL string: \(album.coverUrl)")
            imageView.image = UIImage(systemName: "music.note.list")
        }
    }
    
    @objc private func downloadAction() {
        onDownloadTapped?()
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Download Progress Popup
class DownloadProgressView: UIView {
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    private let progressBar = UIProgressView(progressViewStyle: .default)
    let cancelButton = UIButton(type: .system)
    let confirmButton = GradientButton()
    
    var onCancel: (() -> Void)?
    var onConfirm: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        containerView.backgroundColor = UIColor(hex: "#21418D")
        containerView.layer.cornerRadius = 16
        addSubview(containerView)
        
        titleLabel.text = "正在下载"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        containerView.addSubview(titleLabel)
        
        statusLabel.text = "准备中..."
        statusLabel.textColor = .white
        statusLabel.font = .systemFont(ofSize: 14)
        containerView.addSubview(statusLabel)
        
        progressBar.progressTintColor = UIColor(hex: "#16E0BF")
        progressBar.trackTintColor = UIColor.white.withAlphaComponent(0.2)
        containerView.addSubview(progressBar)
        
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.setTitleColor(UIColor(hex: "#16E0BF"), for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        containerView.addSubview(cancelButton)
        
        confirmButton.setTitle("确定", for: .normal)
        confirmButton.isHidden = true // 默认隐藏，下载完成显示
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        containerView.addSubview(confirmButton)
        
        // Layout
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(40)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
        }
        
        progressBar.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(4)
        }
        
        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(progressBar.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(40)
        }
        
        confirmButton.snp.makeConstraints { make in
            make.edges.equalTo(cancelButton)
            make.width.equalTo(120)
        }
    }
    
    func updateProgress(current: Int, total: Int) {
        statusLabel.text = "正在下载: \(current)/\(total)"
        let progress = Float(current) / Float(total)
        progressBar.setProgress(progress, animated: true)
    }
    
    func finishDownload(total: Int) {
        titleLabel.text = "下载完成"
        statusLabel.text = "\(total)首歌已经下载完成"
        progressBar.setProgress(1.0, animated: true)
        cancelButton.isHidden = true
        confirmButton.isHidden = false
    }
    
    @objc private func cancelTapped() {
        onCancel?()
        hide()
    }
    
    @objc private func confirmTapped() {
        onConfirm?()
        hide()
    }
    
    func show(in view: UIView) {
        alpha = 0
        view.addSubview(self)
        snp.makeConstraints { make in make.edges.equalToSuperview() }
        UIView.animate(withDuration: 0.3) { self.alpha = 1 }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.3, animations: { self.alpha = 0 }) { _ in
            self.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
