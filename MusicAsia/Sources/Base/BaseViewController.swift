import UIKit
import SnapKit

// MARK: - Collect Success Popup
class CollectSuccessPopupView: UIView {
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let textLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        containerView.backgroundColor = UIColor(hex: "#17181A").withAlphaComponent(0.24)
        containerView.layer.cornerRadius = 16
        addSubview(containerView)
        
        iconImageView.image = UIImage(named: "collection_successful_icon")
        iconImageView.contentMode = .scaleAspectFit
        containerView.addSubview(iconImageView)
        
        textLabel.text = "收藏成功"
        textLabel.textColor = .white
        textLabel.font = .systemFont(ofSize: 14)
        textLabel.textAlignment = .center
        containerView.addSubview(textLabel)
        
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(104)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.width.equalTo(80)
            make.height.equalTo(60)
        }
        
        textLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(-6)
            make.centerX.equalToSuperview()
        }
    }
    
    func show(in view: UIView) {
        alpha = 0
        view.addSubview(self)
        snp.makeConstraints { make in make.edges.equalToSuperview() }
        
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1
        }
        
        // 自动消失
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            UIView.animate(withDuration: 0.2, animations: {
                self.alpha = 0
            }) { _ in
                self.removeFromSuperview()
            }
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

/// 全局的基础 ViewController，统一管理背景色、导航栏样式等
class BaseViewController: UIViewController {
    
    // 使用 CAGradientLayer 来实现 CSS 的 linear-gradient
    let gradientLayer = CAGradientLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGlobalBackground()
    }
    
    private func setupGlobalBackground() {
        // 设置一个不透明的背景色，防止 iOS 在转场动画（如 Tab 切换或 Push）时由于背景透明而产生性能开销和卡顿
        view.backgroundColor = UIColor(hex: "#091227")
        
        // 设置渐变颜色: #21418D -> #091227
        gradientLayer.colors = [
            UIColor(hex: "#21418D").cgColor,
            UIColor(hex: "#091227").cgColor
        ]
        
        // CSS 的 135deg 等同于 iOS 中的左上角到右下角
        // (0,0) 为左上角，(1,1) 为右下角
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.locations = [0.0, 1.0]
        
        // 将渐变层插入到视图的最底层
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 当屏幕旋转或视图大小改变时，确保渐变层能铺满整个屏幕
        gradientLayer.frame = view.bounds
    }
    
    /// 通用的提示弹窗
    func showAlert(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    /// 通用的收藏成功弹窗
    func showCollectSuccessPopup() {
        let popup = CollectSuccessPopupView()
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            popup.show(in: window)
        } else {
            popup.show(in: self.view)
        }
    }
}
