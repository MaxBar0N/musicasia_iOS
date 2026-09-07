import UIKit
import SnapKit

/// 不支持的设备提示页：本应用仅允许在 iPhone 上使用
class UnsupportedDeviceViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        let logoImageView = UIImageView()
        logoImageView.image = UIImage(named: "login_logo_icon")
        logoImageView.contentMode = .scaleAspectFit
        view.addSubview(logoImageView)

        let titleLabel = UILabel()
        titleLabel.text = "此应用仅支持 iPhone 使用"
        titleLabel.textColor = .white
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)

        let messageLabel = UILabel()
        messageLabel.text = "请使用 iPhone 设备打开「唱享视界」"
        messageLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.textAlignment = .center
        view.addSubview(messageLabel)

        logoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-60)
            make.width.equalTo(120)
            make.height.equalTo(90)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(32)
        }

        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(32)
        }
    }
}
