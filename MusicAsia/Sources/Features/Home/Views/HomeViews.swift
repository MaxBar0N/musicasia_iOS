import UIKit
import SnapKit
import Kingfisher

// MARK: - Section Header
class SectionHeaderView: UIView {
    private let indicator = UIView()
    private let titleLabel = UILabel()
    
    init(title: String) {
        super.init(frame: .zero)
        
        indicator.backgroundColor = UIColor(hex: "#16E0BF")
        indicator.layer.cornerRadius = 1.5
        addSubview(indicator)
        
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        addSubview(titleLabel)
        
        indicator.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.width.equalTo(3)
            make.height.equalTo(14)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(indicator.snp.right).offset(8)
            make.centerY.right.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Ad Card
class AdCardView: UIView {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    
    var onTap: (() -> Void)?
    
    init(title: String, imageUrl: String) {
        super.init(frame: .zero)
        layer.cornerRadius = 12
        clipsToBounds = true
        
        imageView.contentMode = .scaleAspectFill
        if imageUrl.hasPrefix("http"), let url = URL(string: imageUrl) {
            imageView.kf.setImage(with: url)
        } else if let localImage = UIImage(named: imageUrl) {
            imageView.image = localImage
        } else {
            imageView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        }
        addSubview(imageView)
        
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        addSubview(titleLabel)
        
        imageView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-10)
        }
        
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    @objc private func handleTap() {
        onTap?()
    }
}

// MARK: - Song Row View
class SongRowView: UIView {
    let titleLabel = UILabel()
    let artistLabel = UILabel()
    let favButton = UIButton(type: .system)
    let playButton = UIButton(type: .system)
    
    var onFavTapped: (() -> Void)?
    var onPlayTapped: (() -> Void)?
    
    init() {
        super.init(frame: .zero)
        
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        
        artistLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        artistLabel.font = .systemFont(ofSize: 12)
        
        let textStack = UIStackView(arrangedSubviews: [titleLabel, artistLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        addSubview(textStack)
        
        favButton.tintColor = .white
        favButton.addTarget(self, action: #selector(favAction), for: .touchUpInside)
        addSubview(favButton)
        
        playButton.tintColor = .white
        playButton.addTarget(self, action: #selector(playAction), for: .touchUpInside)
        addSubview(playButton)
        
        textStack.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.right.equalTo(favButton.snp.left).offset(-10)
        }
        
        playButton.snp.makeConstraints { make in
            make.right.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
        
        favButton.snp.makeConstraints { make in
            make.right.equalTo(playButton.snp.left).offset(-15)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
    }
    
    func configure(with song: Song) {
        titleLabel.text = song.name
        artistLabel.text = song.artist
        
        updateFavState(isFav: song.isFavorited)
        updatePlayState(isPlaying: song.isPlaying)
    }
    
    func updateFavState(isFav: Bool) {
        let iconName = isFav ? "heart.fill" : "heart"
        favButton.setImage(UIImage(systemName: iconName), for: .normal)
        favButton.tintColor = isFav ? UIColor(hex: "#E53E3E") : .white
    }
    
    func updatePlayState(isPlaying: Bool) {
        let iconName = isPlaying ? "pause.fill" : "play.fill"
        playButton.setImage(UIImage(systemName: iconName), for: .normal)
    }
    
    @objc private func favAction() { onFavTapped?() }
    @objc private func playAction() { onPlayTapped?() }
    
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Album Card View
class AlbumCardView: UIView {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    let downloadButton = UIButton(type: .system)
    
    var onDownloadTapped: (() -> Void)?
    var onPlayTapped: (() -> Void)?
    
    init() {
        super.init(frame: .zero)
        layer.cornerRadius = 12
        clipsToBounds = true
        
        // Add tap gesture to the whole card
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(playAction))
        self.addGestureRecognizer(tapGesture)
        self.isUserInteractionEnabled = true
        
        imageView.contentMode = .scaleAspectFill
        addSubview(imageView)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.8).cgColor]
        let overlay = UIView()
        overlay.layer.addSublayer(gradientLayer)
        addSubview(overlay)
        
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        addSubview(titleLabel)
        
        // 下载按钮使用本地资源
        downloadButton.setImage(UIImage(named: "download_icon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        downloadButton.contentHorizontalAlignment = .fill
        downloadButton.contentVerticalAlignment = .fill
        downloadButton.imageView?.contentMode = .scaleAspectFit
        downloadButton.addTarget(self, action: #selector(downloadAction), for: .touchUpInside)
        addSubview(downloadButton)
        
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
            print("AlbumCardView Loading URL: \(url.absoluteString)")
            imageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "music.note.list"),
                options: nil,
                completionHandler: { result in
                    switch result {
                    case .success(let value):
                        print("AlbumCardView Image loaded successfully: \(value.source.url?.absoluteString ?? "")")
                    case .failure(let error):
                        print("AlbumCardView Image load failed: \(error.localizedDescription) for URL: \(url.absoluteString)")
                    }
                }
            )
        } else {
            print("AlbumCardView Invalid URL string: \(album.coverUrl)")
            imageView.image = UIImage(systemName: "music.note.list")
        }
    }
    
    @objc private func downloadAction() { onDownloadTapped?() }
    @objc private func playAction() { onPlayTapped?() }
    
    required init?(coder: NSCoder) { fatalError() }
}



