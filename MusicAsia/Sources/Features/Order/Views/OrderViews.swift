import UIKit
import SnapKit

// MARK: - Order List Row View
class OrderRowView: UIView {
    private let bgView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let orderNoLabel = UILabel()
    private let timeLabel = UILabel()
    let viewCodeButton = GradientButton()
    
    var onViewCodeTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        // 背景框
        bgView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        bgView.layer.cornerRadius = 14
        bgView.layer.borderWidth = 0.5
        bgView.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        addSubview(bgView)
        
        // 左侧图片（尺寸 90x90，超出背景框）
        iconImageView.image = UIImage(named: "my_order_item_image")
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.layer.cornerRadius = 12
        iconImageView.clipsToBounds = true
        addSubview(iconImageView)
        
        let iconLabel = UILabel()
        iconLabel.textColor = .white
        iconLabel.font = .systemFont(ofSize: 12, weight: .medium)
        iconLabel.textAlignment = .center
        iconImageView.addSubview(iconLabel)
        
        // Labels
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
        addSubview(titleLabel)
        
        orderNoLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        orderNoLabel.font = .systemFont(ofSize: 12)
        addSubview(orderNoLabel)
        
        timeLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        timeLabel.font = .systemFont(ofSize: 12)
        addSubview(timeLabel)
        
        // Button
        viewCodeButton.setTitle("查看激活码", for: .normal)
        viewCodeButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        viewCodeButton.customCornerRadius = 14
        viewCodeButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        viewCodeButton.clipsToBounds = true
        viewCodeButton.addTarget(self, action: #selector(viewCodeAction), for: .touchUpInside)
        addSubview(viewCodeButton)
        
        // Layout
        bgView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(76)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.left.equalTo(bgView.snp.left)
            make.bottom.equalTo(bgView.snp.bottom)
            make.width.height.equalTo(90)
        }
        
        iconLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-12)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(bgView).offset(12)
            make.left.equalTo(iconImageView.snp.right).offset(12)
        }
        
        orderNoLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.left.equalTo(titleLabel)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(orderNoLabel.snp.bottom).offset(4)
            make.left.equalTo(titleLabel)
        }
        
        viewCodeButton.snp.makeConstraints { make in
            make.right.equalTo(bgView.snp.right)
            make.centerY.equalTo(bgView)
            make.width.equalTo(80)
            make.height.equalTo(28)
        }
        
        // 保存引用用于 configure
        self.iconLabel = iconLabel
    }
    
    private var iconLabel: UILabel!
    
    func configure(with order: OrderModel) {
        titleLabel.text = order.title
        orderNoLabel.text = "订单号 \(order.orderNo)"
        timeLabel.text = order.createTime
        iconLabel.text = order.title
    }
    
    @objc private func viewCodeAction() {
        onViewCodeTapped?()
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Code Row View
class CodeRowView: UIView {
    let codeLabel = UILabel()
    let copyButton = UIButton(type: .custom)
    
    var onCopyTapped: ((String) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // 增加行高并允许自身交互
        self.isUserInteractionEnabled = true
        self.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        
        codeLabel.textColor = .white
        codeLabel.font = .systemFont(ofSize: 14)
        addSubview(codeLabel)
        
        copyButton.setImage(UIImage(systemName: "square.on.square"), for: .normal)
        copyButton.tintColor = .white
        // 放大点击区域
        copyButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        copyButton.addTarget(self, action: #selector(copyAction), for: .touchUpInside)
        addSubview(copyButton)
        
        codeLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(5)
            make.centerY.equalToSuperview()
        }
        
        copyButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(5) // 向右靠抵消部分 insets
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44) // 放大响应区域
        }
    }
    
    private var pureCode: String = ""
    
    func configure(code: String) {
        // 去除前缀，只显示激活码本身
        pureCode = code.components(separatedBy: ":").last ?? code
        codeLabel.text = pureCode
    }
    
    @objc private func copyAction() {
        print("copyAction triggered with pureCode: \(pureCode)")
        // 触发复制时传递纯净的激活码
        onCopyTapped?(pureCode)
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Copy Success Popup
class CopySuccessPopupView: UIView {
    private let containerView = UIView()
    private let gradientLayer = CAGradientLayer()
    
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
        titleLabel.text = "温馨提示"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        containerView.addSubview(titleLabel)
        
        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeBtn.tintColor = .white
        closeBtn.addTarget(self, action: #selector(hide), for: .touchUpInside)
        containerView.addSubview(closeBtn)
        
        let msgLabel = UILabel()
        msgLabel.text = "激活码已拷贝到剪切板，可以进入联通或唱吧\n开通"
        msgLabel.textColor = .white
        msgLabel.font = .systemFont(ofSize: 14)
        msgLabel.numberOfLines = 0
        msgLabel.textAlignment = .center
        containerView.addSubview(msgLabel)
        
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("关闭", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 16)
        closeButton.layer.cornerRadius = 22
        closeButton.layer.borderWidth = 1
        closeButton.layer.borderColor = UIColor.white.cgColor
        closeButton.addTarget(self, action: #selector(hide), for: .touchUpInside)
        containerView.addSubview(closeButton)
        
        // Layout
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(35)
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
            make.top.equalTo(titleLabel.snp.bottom).offset(25)
            make.left.right.equalToSuperview().inset(20)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(msgLabel.snp.bottom).offset(30)
            make.left.right.equalToSuperview().inset(25)
            make.bottom.equalToSuperview().offset(-25)
            make.height.equalTo(44)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = containerView.bounds
    }
    
    func show(in view: UIView) {
        alpha = 0
        view.addSubview(self)
        snp.makeConstraints { make in make.edges.equalToSuperview() }
        
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
        
        // 确保能接收点击事件
        self.isUserInteractionEnabled = true
        self.containerView.isUserInteractionEnabled = true
    }
    
    @objc func hide() {
        UIView.animate(withDuration: 0.3, animations: { self.alpha = 0 }) { _ in
            self.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
