import UIKit
import SnapKit

// MARK: - Empty State View
class DeviceEmptyView: UIView {

    var onBindTapped: (() -> Void)?

    private let bindButton = GradientButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true

        let imageView = UIImageView(image: UIImage(named: "add_device_image"))
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)

        imageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-80)
            make.width.equalTo(200)
            make.height.equalTo(140)
        }

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 5
        stack.isUserInteractionEnabled = true
        addSubview(stack)

        let text1 = UILabel()
        text1.text = "暂无设备"
        text1.textColor = UIColor.white.withAlphaComponent(0.8)
        text1.font = .systemFont(ofSize: 14)
        stack.addArrangedSubview(text1)

        stack.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }

        bindButton.setTitle("绑定设备", for: .normal)
        bindButton.customCornerRadius = 22
        bindButton.addTarget(self, action: #selector(bindTapped), for: .touchUpInside)
        addSubview(bindButton)

        bindButton.snp.makeConstraints { make in
            make.top.equalTo(stack.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.width.equalTo(160)
            make.height.equalTo(44)
        }
    }

    @objc private func bindTapped() {
        onBindTapped?()
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Device Row View
class DeviceRowView: UIView {
    let nameLabel = UILabel()
    let serialLabel = UILabel()
    let deleteButton = UIButton(type: .system)
    
    var onDeleteTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white.withAlphaComponent(0.1)
        layer.cornerRadius = 8
        
        let serialContainerView = UIView()
        serialContainerView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        serialContainerView.layer.cornerRadius = 6
        addSubview(serialContainerView)
        
        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 15, weight: .medium)
        addSubview(nameLabel)
        
        serialLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        serialLabel.font = .systemFont(ofSize: 15)
        serialContainerView.addSubview(serialLabel)
        
        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.tintColor = .white
        deleteButton.addTarget(self, action: #selector(deleteAction), for: .touchUpInside)
        // 暂时屏蔽删除按钮，因为后端尚未提供删除接口
        deleteButton.isHidden = true
        addSubview(deleteButton)
        
        nameLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
        }
        
        deleteButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-15)
            make.centerY.equalToSuperview()
            // 将宽度设为 0，避免占据空间影响布局
            make.width.equalTo(0)
            make.height.equalTo(30)
        }
        
        serialContainerView.snp.makeConstraints { make in
            make.left.equalTo(nameLabel.snp.right).offset(5)
            // 原本是 offset(-15) 依赖 deleteButton 的 left，因为删除了宽度，可以直接靠右
            make.right.equalToSuperview().offset(-15)
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
        }
        
        serialLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }
    }
    
    func configure(device: DeviceModel) {
        nameLabel.text = device.name
        serialLabel.text = device.serialNo
    }
    
    @objc private func deleteAction() {
        onDeleteTapped?()
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Bind Device Popup
class BindDevicePopupView: UIView {
    private let containerView = UIView()
    private let textField = UITextField()
    private let cancelButton = UIButton(type: .system)
    private let bindButton = GradientButton()
    private let gradientLayer = CAGradientLayer()
    
    var onBind: ((String) -> Void)?
    var onScanTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        addSubview(containerView)
        
        // 渐变背景
        gradientLayer.colors = [
            UIColor(hex: "#5E83F2").cgColor,
            UIColor(hex: "#8C52FF").cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        containerView.layer.insertSublayer(gradientLayer, at: 0)
        
        let titleLabel = UILabel()
        titleLabel.text = "绑定设备"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        containerView.addSubview(titleLabel)
        
        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeBtn.tintColor = .white
        closeBtn.addTarget(self, action: #selector(hide), for: .touchUpInside)
        containerView.addSubview(closeBtn)
        
        // Input Field
        let inputBg = UIView()
        inputBg.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        inputBg.layer.cornerRadius = 8
        containerView.addSubview(inputBg)
        
        textField.textColor = .white
        textField.font = .systemFont(ofSize: 14)
        textField.attributedPlaceholder = NSAttributedString(
            string: "请输入设备码或扫码绑定设备",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.5)]
        )
        inputBg.addSubview(textField)
        
        let scanBtn = UIButton(type: .system)
        scanBtn.setImage(UIImage(systemName: "qrcode.viewfinder"), for: .normal)
        scanBtn.tintColor = .white
        scanBtn.addTarget(self, action: #selector(scanAction), for: .touchUpInside)
        inputBg.addSubview(scanBtn)
        
        // Buttons
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16)
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor.white.cgColor
        cancelButton.clipsToBounds = true
        cancelButton.layer.cornerRadius = 22 // 给一个默认值
        cancelButton.addTarget(self, action: #selector(hide), for: .touchUpInside)
        containerView.addSubview(cancelButton)
        
        bindButton.setTitle("绑定", for: .normal)
        bindButton.clipsToBounds = true
        bindButton.customCornerRadius = 22 // 给一个默认值
        bindButton.addTarget(self, action: #selector(bindAction), for: .touchUpInside)
        containerView.addSubview(bindButton)
        
        // Layout
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(30)
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
        
        inputBg.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(25)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }
        
        textField.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
            make.right.equalTo(scanBtn.snp.left).offset(-10)
        }
        
        scanBtn.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        let stack = UIStackView(arrangedSubviews: [cancelButton, bindButton])
        stack.axis = .horizontal
        stack.spacing = 15
        stack.distribution = .fillEqually
        containerView.addSubview(stack)
        
        stack.snp.makeConstraints { make in
            make.top.equalTo(inputBg.snp.bottom).offset(25)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(44)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = containerView.bounds
        
        // 确保 bounds 已经计算出来后再设置圆角
        if cancelButton.bounds.height > 0 {
            cancelButton.layer.cornerRadius = cancelButton.bounds.height / 2
        }
        if bindButton.bounds.height > 0 {
            bindButton.customCornerRadius = bindButton.bounds.height / 2
        }
    }
    
    @objc private func bindAction() {
        guard let text = textField.text, !text.isEmpty else { return }
        onBind?(text)
    }
    
    @objc private func scanAction() {
        onScanTapped?()
    }
    
    func show(in view: UIView) {
        textField.text = ""
        alpha = 0
        view.addSubview(self)
        snp.makeConstraints { make in make.edges.equalToSuperview() }
        
        // 强制触发布局以保证弹出前 bounds 已经计算完成，从而应用正确的圆角
        self.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.3) { self.alpha = 1 }
    }
    
    @objc func hide() {
        endEditing(true)
        UIView.animate(withDuration: 0.3, animations: { self.alpha = 0 }) { _ in
            self.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
