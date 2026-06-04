import UIKit

/// 渐变色实心按钮 (用于“登录”、“发送”按钮)
class GradientButton: UIButton {
    private let gradientLayer = CAGradientLayer()
    var customCornerRadius: CGFloat? {
        didSet {
            setNeedsLayout()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }
    
    private func setupGradient() {
        // 设置渐变颜色 #16E0BF -> #2E8AE5
        gradientLayer.colors = [
            UIColor(hex: "#16E0BF").cgColor,
            UIColor(hex: "#2E8AE5").cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        layer.insertSublayer(gradientLayer, at: 0)
        setTitleColor(.white, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        let cornerRadius: CGFloat = customCornerRadius ?? (bounds.height / 2)
        layer.cornerRadius = cornerRadius
        gradientLayer.cornerRadius = cornerRadius
        gradientLayer.maskedCorners = layer.maskedCorners
    }
    
    /// 设置按钮不可用时的状态
    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1.0 : 0.5
        }
    }
}

/// 渐变色边框按钮 (用于“注册”按钮)
class GradientBorderButton: UIButton {
    private let gradientLayer = CAGradientLayer()
    private let shapeLayer = CAShapeLayer()
    var customCornerRadius: CGFloat? {
        didSet {
            setNeedsLayout()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradientBorder()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradientBorder()
    }
    
    private func setupGradientBorder() {
        gradientLayer.colors = [
            UIColor(hex: "#16E0BF").cgColor,
            UIColor(hex: "#2E8AE5").cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        // 设置遮罩层的线条属性，宽度设为2px以匹配设计要求
        shapeLayer.lineWidth = 2.0
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.black.cgColor // 颜色无所谓，仅作遮罩
        
        gradientLayer.mask = shapeLayer
        layer.addSublayer(gradientLayer)
        
        // 提取渐变的中间色作为文字颜色
        setTitleColor(UIColor(hex: "#22B5D2"), for: .normal)
        titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        
        let cornerRadius: CGFloat = customCornerRadius ?? 8
        // 路径需要向内缩进线宽的一半，否则边框会被裁剪
        let path = UIBezierPath(roundedRect: bounds.insetBy(dx: 1.0, dy: 1.0), cornerRadius: cornerRadius)
        shapeLayer.path = path.cgPath
        layer.cornerRadius = cornerRadius
    }
}

/// 自定义带有内边距和半透明背景的输入框
class CustomTextField: UITextField {
    private let padding = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyle()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStyle()
    }
    
    private func setupStyle() {
        // 白色，20%透明度
        backgroundColor = UIColor.white.withAlphaComponent(0.2)
        layer.cornerRadius = 8
        textColor = .white
        font = .systemFont(ofSize: 15)
        tintColor = UIColor(hex: "#16E0BF") // 光标颜色
    }
    
    /// 设置占位符文本及颜色
    func setCustomPlaceholder(_ text: String) {
        attributedPlaceholder = NSAttributedString(
            string: text,
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.5)]
        )
    }
    
    // 以下三个方法用于增加文字与边框的间距
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
}
