import UIKit
import SnapKit

class CustomAlertView: UIView {
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    
    let purchaseButton = GradientButton()
    let activateButton = GradientBorderButton()
    
    var onClose: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        containerView.backgroundColor = UIColor(hex: "#3D3DD8") // 提示框背景色
        containerView.layer.cornerRadius = 16
        addSubview(containerView)
        
        titleLabel.text = "温馨提示"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        containerView.addSubview(titleLabel)
        
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        containerView.addSubview(closeButton)
        
        messageLabel.text = "你已完成注册，请确认是否已有设备，如果没有请选“购买”，如有请选“激活”，谢谢"
        messageLabel.textColor = .white
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.numberOfLines = 0
        containerView.addSubview(messageLabel)
        
        purchaseButton.setTitle("购买", for: .normal)
        activateButton.setTitle("激活", for: .normal)
        
        let stackView = UIStackView(arrangedSubviews: [purchaseButton, activateButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 15
        containerView.addSubview(stackView)
        
        // Layout
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(40)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.right.equalToSuperview().offset(-15)
            make.width.height.equalTo(30)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
        }
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(25)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(44)
        }
    }
    
    @objc private func closeTapped() {
        onClose?()
        self.removeFromSuperview()
    }
    
    func show(in view: UIView) {
        alpha = 0
        view.addSubview(self)
        snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
