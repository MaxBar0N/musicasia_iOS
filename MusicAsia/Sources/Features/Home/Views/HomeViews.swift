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
    }
    
    required init?(coder: NSCoder) { fatalError() }
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
    let favButton = UIButton(type: .system)
    let playButton = UIButton(type: .system)
    
    var onFavTapped: (() -> Void)?
    var onPlayTapped: (() -> Void)?
    
    init() {
        super.init(frame: .zero)
        layer.cornerRadius = 12
        clipsToBounds = true
        
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
        
        favButton.addTarget(self, action: #selector(favAction), for: .touchUpInside)
        addSubview(favButton)
        
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .white
        playButton.addTarget(self, action: #selector(playAction), for: .touchUpInside)
        addSubview(playButton)
        
        imageView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        
        overlay.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(40)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
            make.right.equalTo(favButton.snp.left).offset(-5)
        }
        
        playButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalTo(titleLabel)
            make.width.height.equalTo(24)
        }
        
        favButton.snp.makeConstraints { make in
            make.right.equalTo(playButton.snp.left).offset(-10)
            make.centerY.equalTo(titleLabel)
            make.width.height.equalTo(24)
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
        updateFavState(isFav: album.isFavorited)
    }
    
    func updateFavState(isFav: Bool) {
        let iconName = isFav ? "heart.fill" : "heart"
        favButton.setImage(UIImage(systemName: iconName), for: .normal)
        favButton.tintColor = isFav ? UIColor(hex: "#E53E3E") : .white
    }
    
    @objc private func favAction() { onFavTapped?() }
    @objc private func playAction() { onPlayTapped?() }
    
    required init?(coder: NSCoder) { fatalError() }
}


// MARK: - Player Popup View
class PlayerPopupView: UIView {
    private let containerView = UIView()
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        containerView.backgroundColor = UIColor(hex: "#2C2C2E")
        containerView.layer.cornerRadius = 16
        addSubview(containerView)
        
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)
        
        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeBtn.tintColor = .white
        closeBtn.addTarget(self, action: #selector(hide), for: .touchUpInside)
        containerView.addSubview(closeBtn)
        
        let msgLabel = UILabel()
        msgLabel.text = "正在播放中..."
        msgLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        msgLabel.font = .systemFont(ofSize: 14)
        msgLabel.textAlignment = .center
        containerView.addSubview(msgLabel)
        
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(40)
            make.height.equalTo(150)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
        }
        
        closeBtn.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.right.equalToSuperview().offset(-15)
            make.width.height.equalTo(30)
        }
        
        msgLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(30)
            make.centerX.equalToSuperview()
        }
    }
    
    func configure(songName: String) {
        titleLabel.text = songName
    }
    
    func show(in view: UIView) {
        alpha = 0
        view.addSubview(self)
        snp.makeConstraints { make in make.edges.equalToSuperview() }
        UIView.animate(withDuration: 0.3) { self.alpha = 1 }
    }
    
    @objc func hide() {
        UIView.animate(withDuration: 0.3, animations: { self.alpha = 0 }) { _ in
            self.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
