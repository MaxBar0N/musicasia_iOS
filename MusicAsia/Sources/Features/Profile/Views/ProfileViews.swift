import UIKit
import SnapKit
import Kingfisher

// MARK: - Profile Card View
class ProfileCardView: UIView {
    private let bgImageView = UIImageView()
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let renewButton = UIButton(type: .custom)
    private let vipLabel = UILabel()
    
    let orderBtn = UIButton(type: .custom)
    let bluetoothBtn = UIButton(type: .custom)
    let deviceBtn = UIButton(type: .custom)
    
    var onRenewTapped: (() -> Void)?
    
    private let renewGradientLayer = CAGradientLayer()
    private let menuContainerView = UIView()
    private let menuGradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        renewGradientLayer.frame = renewButton.bounds
        menuGradientLayer.frame = menuContainerView.bounds
    }
    
    private func setupUI() {
        layer.cornerRadius = 16
        clipsToBounds = true
        backgroundColor = .clear
        
        // 背景图
        bgImageView.contentMode = .scaleAspectFill
        bgImageView.image = UIImage(named: "my_banner_bg_image")
        addSubview(bgImageView)
        
        // Avatar
        avatarImageView.layer.cornerRadius = 8
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
        avatarImageView.tintColor = .white
        addSubview(avatarImageView)
        
        // Name & Renew
        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 20, weight: .bold)
        nameLabel.text = "加载中..."
        addSubview(nameLabel)
        
        // 续费按钮
        renewGradientLayer.colors = [
            UIColor(hex: "#16E0BF").cgColor,
            UIColor(hex: "#2E8AE5").cgColor
        ]
        renewGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        renewGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        renewGradientLayer.cornerRadius = 8
        renewButton.layer.insertSublayer(renewGradientLayer, at: 0)
        
        renewButton.setTitle("续费", for: .normal)
        renewButton.setTitleColor(.white, for: .normal)
        renewButton.titleLabel?.font = .systemFont(ofSize: 10, weight: .medium)
        renewButton.layer.cornerRadius = 8
        renewButton.addTarget(self, action: #selector(renewAction), for: .touchUpInside)
        addSubview(renewButton)
        
        // VIP Label
        vipLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        vipLabel.font = .systemFont(ofSize: 12)
        addSubview(vipLabel)
        
        menuContainerView.layer.cornerRadius = 8
        menuContainerView.clipsToBounds = true
        addSubview(menuContainerView)
        
        menuGradientLayer.colors = [
            UIColor(hex: "#578CEF").withAlphaComponent(0.4).cgColor,
            UIColor(hex: "#371F99").withAlphaComponent(0.4).cgColor
        ]
        menuGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        menuGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        menuContainerView.layer.insertSublayer(menuGradientLayer, at: 0)
        
        // Menu Stack
        let menuStack = UIStackView(arrangedSubviews: [
            createMenuButton(btn: orderBtn, title: "我的订单", icon: "my_order_icon"),
            createMenuButton(btn: bluetoothBtn, title: "我的蓝牙", icon: "my_bluetooth_icon"),
            createMenuButton(btn: deviceBtn, title: "我的设备", icon: "my_device_icon")
        ])
        menuStack.axis = .horizontal
        menuStack.distribution = .fillEqually
        menuStack.spacing = 10
        menuContainerView.addSubview(menuStack)
        
        bgImageView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        
        avatarImageView.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(20)
            make.width.height.equalTo(60)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView).offset(5)
            make.left.equalTo(avatarImageView.snp.right).offset(15)
        }
        
        renewButton.snp.makeConstraints { make in
            make.centerY.equalTo(nameLabel)
            make.left.equalTo(nameLabel.snp.right).offset(10)
            make.width.equalTo(48)
            make.height.equalTo(16)
        }
        
        vipLabel.snp.makeConstraints { make in
            make.bottom.equalTo(avatarImageView).offset(-5)
            make.left.equalTo(nameLabel)
        }
        
        menuContainerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(48) // 40 + 4(top) + 4(bottom) = 48
        }
        
        menuStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
    }
    
    private func createMenuButton(btn: UIButton, title: String, icon: String) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        let iconView = UIImageView(image: UIImage(named: icon))
        iconView.contentMode = .scaleAspectFit
        view.addSubview(iconView)
        
        let label = UILabel()
        label.text = title
        label.textColor = .white
        label.font = .systemFont(ofSize: 12)
        view.addSubview(label)
        
        iconView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(10)
            make.width.height.equalTo(24)
        }
        
        label.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(iconView.snp.right).offset(5)
        }
        
        btn.backgroundColor = .clear
        view.addSubview(btn)
        btn.snp.makeConstraints { make in make.edges.equalToSuperview() }
        
        return view
    }
    
    func configure(with profile: UserProfile) {
        nameLabel.text = profile.name.isEmpty ? "用户" : profile.name
        vipLabel.text = "会员到期：\(profile.formattedExpiration)"
        
        let placeholder = UIImage(systemName: "person.circle.fill")
        if let url = URL(string: profile.avatarUrl), !profile.avatarUrl.isEmpty {
            avatarImageView.kf.setImage(with: url, placeholder: placeholder)
        } else {
            avatarImageView.image = placeholder
            avatarImageView.tintColor = .white
        }
    }
    
    @objc private func renewAction() {
        onRenewTapped?()
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Profile Song Row View
class ProfileSongRowView: UIView {
    let titleLabel = UILabel()
    let artistLabel = UILabel()
    let favButton = UIButton(type: .system)
    let singButton = UIButton(type: .system)
    
    var onFavTapped: (() -> Void)?
    var onSingTapped: (() -> Void)?
    
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
        
        favButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        favButton.tintColor = UIColor(hex: "#E53E3E") // 收藏页默认都是已收藏
        favButton.addTarget(self, action: #selector(favAction), for: .touchUpInside)
        addSubview(favButton)
        
        singButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        singButton.tintColor = .white
        singButton.addTarget(self, action: #selector(singAction), for: .touchUpInside)
        addSubview(singButton)
        
        textStack.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.right.equalTo(favButton.snp.left).offset(-10)
        }
        
        singButton.snp.makeConstraints { make in
            make.right.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
        
        favButton.snp.makeConstraints { make in
            make.right.equalTo(singButton.snp.left).offset(-15)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
    }
    
    func configure(with song: Song) {
        titleLabel.text = song.name
        artistLabel.text = song.artist
        updateSingState(isSinging: song.isPlaying)
    }
    
    func updateSingState(isSinging: Bool) {
        if isSinging {
            singButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            singButton.tintColor = UIColor(hex: "#16E0BF")
        } else {
            singButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
            singButton.tintColor = .white
        }
    }
    
    @objc private func favAction() { onFavTapped?() }
    @objc private func singAction() { onSingTapped?() }
    
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Batch Download Popup
class BatchDownloadPopupView: UIView {
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let cancelButton = GradientBorderButton()
    
    var onCancel: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        containerView.backgroundColor = UIColor(hex: "#3D3DD8")
        containerView.layer.cornerRadius = 16
        addSubview(containerView)
        
        titleLabel.text = "歌曲下载"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        containerView.addSubview(titleLabel)
        
        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeBtn.tintColor = .white
        closeBtn.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        containerView.addSubview(closeBtn)
        
        messageLabel.textColor = .white
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        containerView.addSubview(messageLabel)
        
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        containerView.addSubview(cancelButton)
        
        // Layout
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(40)
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
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
        }
        
        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(25)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(44)
        }
    }
    
    func configure(count: Int) {
        messageLabel.text = "本次下载\(count)首歌曲，请别关闭页，下载完成，程序会自动关闭此页面"
    }
    
    func finishDownload(count: Int) {
        messageLabel.text = "\(count)首歌已经下载完成"
        cancelButton.setTitle("关闭", for: .normal)
    }
    
    @objc private func cancelTapped() {
        onCancel?()
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

// MARK: - Customer Service Popup
class CustomerServicePopupView: UIView {
    private let containerView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        containerView.backgroundColor = UIColor(hex: "#3D3DD8")
        containerView.layer.cornerRadius = 16
        addSubview(containerView)
        
        let titleLabel = UILabel()
        titleLabel.text = "联系客服"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        containerView.addSubview(titleLabel)
        
        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeBtn.tintColor = .white
        closeBtn.addTarget(self, action: #selector(hide), for: .touchUpInside)
        containerView.addSubview(closeBtn)
        
        // QR Code Placeholder
        let qrImageView = UIImageView()
        qrImageView.backgroundColor = .white
        qrImageView.layer.cornerRadius = 8
        qrImageView.image = UIImage(systemName: "qrcode")
        qrImageView.tintColor = .black
        qrImageView.contentMode = .scaleAspectFit
        containerView.addSubview(qrImageView)
        
        let hintLabel = UILabel()
        hintLabel.text = "请识别二维码联系微信客服"
        hintLabel.textColor = .white
        hintLabel.font = .systemFont(ofSize: 14)
        containerView.addSubview(hintLabel)
        
        let closeButton = GradientBorderButton()
        closeButton.setTitle("关闭", for: .normal)
        closeButton.addTarget(self, action: #selector(hide), for: .touchUpInside)
        containerView.addSubview(closeButton)
        
        // Layout
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(40)
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
        
        qrImageView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(150)
        }
        
        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(qrImageView.snp.bottom).offset(15)
            make.centerX.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(hintLabel.snp.bottom).offset(25)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(44)
        }
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
