import UIKit
import SnapKit
import Kingfisher

class SettingsViewController: BaseViewController {
    
    // MARK: - UI Components
    private let avatarImg = UIImageView()
    private let nameLabel = UILabel()
    private let vipLabel = UILabel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "个人中心"
        setupUI()
        fetchUserInfo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: - Data
    private func fetchUserInfo() {
        ProfileAPI.getMeInfo(pageNum: 1, pageSize: 1) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let pageResponse):
                    guard let data = pageResponse.data else { return }
                    
                    // Name
                    let finalName: String
                    if let name = data.name, !name.isEmpty {
                        finalName = name
                    } else if let phone = data.phone, !phone.isEmpty {
                        if phone.count == 11 {
                            let start = phone.index(phone.startIndex, offsetBy: 3)
                            let end = phone.index(phone.endIndex, offsetBy: -4)
                            finalName = phone[..<start] + "****" + phone[end...]
                        } else {
                            finalName = phone
                        }
                    } else {
                        finalName = "用户"
                    }
                    self.nameLabel.text = finalName
                    
                    // VIP
                    if let endTime = data.endTime, !endTime.isEmpty {
                        self.vipLabel.text = "会员到期：\(endTime)"
                    } else {
                        self.vipLabel.text = "会员到期：---"
                    }
                    
                    // Avatar
                    var logoUrl = data.logo ?? ""
                    logoUrl = logoUrl.replacingOccurrences(of: "\\", with: "/")
                    if logoUrl.contains("localhost") || logoUrl.contains("127.0.0.1") || logoUrl.contains("192.168.") {
                        if let pathIndex = logoUrl.range(of: "/", options: [], range: logoUrl.index(logoUrl.startIndex, offsetBy: 8)..<logoUrl.endIndex)?.lowerBound {
                            logoUrl = String(logoUrl[pathIndex...])
                        }
                    }
                    if !logoUrl.isEmpty && !logoUrl.hasPrefix("http") {
                        logoUrl = APIConfig.webBaseURL + (logoUrl.hasPrefix("/") ? "" : "/") + logoUrl
                    }
                    logoUrl = logoUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? logoUrl
                    
                    let placeholder = UIImage(systemName: "person.crop.square.fill")
                    if let url = URL(string: logoUrl), !logoUrl.isEmpty {
                        self.avatarImg.kf.setImage(with: url, placeholder: placeholder)
                    } else {
                        self.avatarImg.image = placeholder
                        self.avatarImg.tintColor = .white
                    }
                    
                case .failure(let error):
                    print("获取个人信息失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func setupUI() {
        let profileCard = UIImageView()
        profileCard.image = UIImage(named: "my_banner_bg_image")
        profileCard.contentMode = .scaleAspectFill
        profileCard.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        profileCard.layer.cornerRadius = 15
        profileCard.clipsToBounds = true
        profileCard.isUserInteractionEnabled = true
        view.addSubview(profileCard)
        
        profileCard.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(100)
        }
        
        avatarImg.layer.cornerRadius = 10
        avatarImg.clipsToBounds = true
        avatarImg.contentMode = .scaleAspectFill
        avatarImg.image = UIImage(systemName: "person.crop.square.fill")
        avatarImg.tintColor = .white
        profileCard.addSubview(avatarImg)
        
        avatarImg.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(60)
        }
        
        nameLabel.text = "加载中..."
        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 20, weight: .bold)
        profileCard.addSubview(nameLabel)
        
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarImg.snp.right).offset(15)
            make.top.equalTo(avatarImg).offset(5)
        }
        
        vipLabel.text = "会员到期：..."
        vipLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        vipLabel.font = .systemFont(ofSize: 12)
        profileCard.addSubview(vipLabel)
        
        vipLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
        }
        
        // 2. 协议列表菜单
        let userAgreementBtn = createMenuButton(title: "用户服务协议")
        userAgreementBtn.addTarget(self, action: #selector(handleUserAgreement), for: .touchUpInside)
        
        let privacyBtn = createMenuButton(title: "隐私协议")
        privacyBtn.addTarget(self, action: #selector(handlePrivacyPolicy), for: .touchUpInside)
        
        view.addSubview(userAgreementBtn)
        userAgreementBtn.snp.makeConstraints { make in
            make.top.equalTo(profileCard.snp.bottom).offset(30)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
        
        view.addSubview(privacyBtn)
        privacyBtn.snp.makeConstraints { make in
            make.top.equalTo(userAgreementBtn.snp.bottom).offset(15)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
        
        // 3. 底部退出注销按钮
        let logoutBtn = GradientButton()
        logoutBtn.setTitle("快速退出", for: .normal)
        logoutBtn.layer.cornerRadius = 25
        logoutBtn.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)
        view.addSubview(logoutBtn)
        
        logoutBtn.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-80)
            make.left.right.equalToSuperview().inset(30)
            make.height.equalTo(50)
        }
        
        let deleteAccountBtn = UIButton(type: .system)
        deleteAccountBtn.setTitle("注销用户", for: .normal)
        deleteAccountBtn.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .normal)
        deleteAccountBtn.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        deleteAccountBtn.layer.cornerRadius = 25
        deleteAccountBtn.addTarget(self, action: #selector(handleDeleteAccount), for: .touchUpInside)
        view.addSubview(deleteAccountBtn)
        
        deleteAccountBtn.snp.makeConstraints { make in
            make.top.equalTo(logoutBtn.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(30)
            make.height.equalTo(50)
        }
    }
    
    private func createMenuButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        btn.layer.cornerRadius = 12
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 15)
        btn.addSubview(titleLabel)
        
        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = UIColor.white.withAlphaComponent(0.5)
        btn.addSubview(arrow)
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }
        arrow.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.width.equalTo(10)
            make.height.equalTo(16)
        }
        
        return btn
    }
    
    // MARK: - Actions
    @objc private func handleUserAgreement() {
        let vc = AgreementViewController()
        vc.agreementTitle = "使用协议"
        vc.urlString = APIConfig.agreementURL
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func handlePrivacyPolicy() {
        let vc = AgreementViewController()
        vc.agreementTitle = "隐私协议"
        vc.urlString = APIConfig.privacyURL
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func handleLogout() {
        showConfirmDialog(title: "退出账号", message: "确定退出？", confirmTitle: "确定") {
            self.executeLogout()
        }
    }
    
    @objc private func handleDeleteAccount() {
        showConfirmDialog(title: "注销账号", message: "确定注销账号？", confirmTitle: "确定注销") {
            print("执行逻辑删除此用户...")
            self.executeLogout()
        }
    }
    
    private func executeLogout() {
        // 清空 Token 和状态
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "UserToken")
        UserDefaults.standard.removeObject(forKey: "UserRegisterType")
        
        // 切换根视图到登录页
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let loginNav = UINavigationController(rootViewController: LoginViewController())
            loginNav.isNavigationBarHidden = true
            window.rootViewController = loginNav
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
        }
    }
    
    // 自定义弹窗
    private func showConfirmDialog(title: String, message: String, confirmTitle: String, onConfirm: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        let confirmAction = UIAlertAction(title: confirmTitle, style: .destructive) { _ in
            onConfirm()
        }
        
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        present(alert, animated: true, completion: nil)
    }
}