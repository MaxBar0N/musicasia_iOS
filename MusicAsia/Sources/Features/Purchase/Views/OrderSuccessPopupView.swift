import UIKit
import SnapKit

class OrderSuccessPopupView: UIView {
    private let containerView = UIView()
    private let containerGradientLayer = CAGradientLayer()
    private let titleLabel = UILabel()
    private let orderNoLabel = UILabel()
    private let homeButton = GradientBorderButton()
    private let receiveCodeButton = GradientButton()
    
    var onHomeTapped: (() -> Void)?
    var onReceiveCodeTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        addSubview(containerView)
        
        containerGradientLayer.colors = [
            UIColor(hex: "#50A4E0").cgColor,
            UIColor(hex: "#7835EB").cgColor
        ]
        containerGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        containerGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        containerView.layer.insertSublayer(containerGradientLayer, at: 0)
        
        titleLabel.text = "恭喜你,下单成功"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        containerView.addSubview(titleLabel)
        
        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeBtn.tintColor = .white
        closeBtn.addTarget(self, action: #selector(hide), for: .touchUpInside)
        containerView.addSubview(closeBtn)
        
        // 礼盒图片
        let giftImageView = UIImageView()
        giftImageView.image = UIImage(named: "order_success_image")
        giftImageView.contentMode = .scaleAspectFill
        giftImageView.clipsToBounds = true
        containerView.addSubview(giftImageView)
        
        // 订单号背景
        let orderNoBg = UIView()
        orderNoBg.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        orderNoBg.layer.cornerRadius = 6
        containerView.addSubview(orderNoBg)
        
        orderNoLabel.textColor = .white
        orderNoLabel.font = .systemFont(ofSize: 14)
        orderNoBg.addSubview(orderNoLabel)
        
        // 按钮
        homeButton.setTitle("返回首页", for: .normal)
        homeButton.customCornerRadius = 22
        homeButton.addTarget(self, action: #selector(homeAction), for: .touchUpInside)
        containerView.addSubview(homeButton)
        
        receiveCodeButton.setTitle("领取VIP激活码", for: .normal)
        receiveCodeButton.customCornerRadius = 22
        receiveCodeButton.addTarget(self, action: #selector(receiveCodeAction), for: .touchUpInside)
        containerView.addSubview(receiveCodeButton)
        
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
        
        giftImageView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(80)
        }
        
        orderNoBg.snp.makeConstraints { make in
            make.top.equalTo(giftImageView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.height.equalTo(36)
            make.width.equalTo(200)
        }
        
        orderNoLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(15)
        }
        
        let stackView = UIStackView(arrangedSubviews: [homeButton, receiveCodeButton])
        stackView.axis = .horizontal
        stackView.spacing = 15
        stackView.distribution = .fillEqually
        containerView.addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(orderNoBg.snp.bottom).offset(30)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(44)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerGradientLayer.frame = containerView.bounds
    }
    
    func configure(orderNo: String) {
        orderNoLabel.text = "订单号   \(orderNo)"
    }
    
    @objc private func homeAction() {
        onHomeTapped?()
        hide()
    }
    
    @objc private func receiveCodeAction() {
        onReceiveCodeTapped?()
        hide()
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
