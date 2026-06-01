import UIKit
import SnapKit

class LoginViewController: BaseViewController {
    
    private let backgroundImageView = UIImageView()
    private let logoImageView = UIImageView()
    
    private let phoneTitleLabel = UILabel()
    private let phoneTextField = CustomTextField()
    
    private let codeTitleLabel = UILabel()
    private let codeTextField = CustomTextField()
    private let sendCodeButton = GradientButton()
    
    private let loginButton = GradientButton()
    private let registerButton = GradientBorderButton()
    
    private var countdownTimer: Timer?
    private var remainingSeconds = 60
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindActions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopTimer()
    }
    
    private func setupUI() {
        setupBackground()
        setupLogo()
        setupPhoneSection()
        setupCodeSection()
        setupActionButtons()
    }
    
    private func setupBackground() {
        // 隐藏 BaseViewController 的默认渐变背景，以显示图片背景
        gradientLayer.isHidden = true
        
        backgroundImageView.image = UIImage(named: "login_background_image")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        view.insertSubview(backgroundImageView, at: 0)
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupLogo() {
        logoImageView.image = UIImage(named: "login_logo_icon") 
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.backgroundColor = .clear 
        
        view.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(60)
            make.centerX.equalToSuperview()
            make.width.equalTo(178)
            make.height.equalTo(133)
        }
    }
    
    private func setupPhoneSection() {
        phoneTitleLabel.text = "手机号"
        phoneTitleLabel.textColor = .white
        phoneTitleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        view.addSubview(phoneTitleLabel)
        
        phoneTextField.setCustomPlaceholder("请输入手机号")
        phoneTextField.keyboardType = .numberPad
        view.addSubview(phoneTextField)
        
        phoneTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp.bottom).offset(120)
            make.left.equalToSuperview().offset(30)
        }
        
        phoneTextField.snp.makeConstraints { make in
            make.top.equalTo(phoneTitleLabel.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(30)
            make.right.equalToSuperview().offset(-30)
            make.height.equalTo(40)
        }
    }
    
    private func setupCodeSection() {
        codeTitleLabel.text = "验证码"
        codeTitleLabel.textColor = .white
        codeTitleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        view.addSubview(codeTitleLabel)
        
        codeTextField.setCustomPlaceholder("请输入验证码")
        codeTextField.keyboardType = .numberPad
        view.addSubview(codeTextField)
        
        sendCodeButton.setTitle("发送", for: .normal)
        view.addSubview(sendCodeButton)
        
        codeTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(phoneTextField.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(30)
        }
        
        sendCodeButton.snp.makeConstraints { make in
            make.top.equalTo(codeTitleLabel.snp.bottom).offset(10)
            make.right.equalToSuperview().offset(-30)
            make.width.equalTo(80)
            make.height.equalTo(40)
        }
        
        codeTextField.snp.makeConstraints { make in
            make.centerY.equalTo(sendCodeButton)
            make.left.equalToSuperview().offset(30)
            make.right.equalTo(sendCodeButton.snp.left).offset(-15)
            make.height.equalTo(40)
        }
    }
    
    private func setupActionButtons() {
        loginButton.setTitle("登录", for: .normal)
        registerButton.setTitle("注册", for: .normal)
        
        let stackView = UIStackView(arrangedSubviews: [loginButton, registerButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 20
        
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.equalTo(codeTextField.snp.bottom).offset(60)
            make.left.equalToSuperview().offset(30)
            make.right.equalToSuperview().offset(-30)
            make.height.equalTo(48)
        }
    }
    
    // MARK: - Actions
    private func bindActions() {
        sendCodeButton.addTarget(self, action: #selector(handleSendCode), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        registerButton.addTarget(self, action: #selector(handleRegister), for: .touchUpInside)
    }
    
    @objc private func handleSendCode() {
        guard let phone = phoneTextField.text, !phone.isEmpty else {
            showAlert(message: "手机号不能为空")
            return
        }
        
        print("正在发送验证码到 \(phone)...")
        startCountdown()
        
        AuthAPI.sendLoginCode(phone: phone) { [weak self] result in
            switch result {
            case .success(let data):
                print("验证码发送成功: \(data ?? "")")
                self?.showAlert(message: "验证码已发送，请注意查收")
            case .failure(let error):
                self?.showAlert(message: "验证码发送失败: \(error.localizedDescription)")
                self?.stopTimer()
            }
        }
    }
    
    @objc private func handleLogin() {
        guard let phone = phoneTextField.text, !phone.isEmpty,
              let code = codeTextField.text, !code.isEmpty else {
            showAlert(message: "手机号或验证码不能为空")
            return
        }
        
        print("正在尝试登录...")
        AuthAPI.login(phone: phone, code: code) { [weak self] result in
            switch result {
            case .success(let token):
                print("登录成功，Token: \(token ?? "")")
                if let token = token, !token.isEmpty {
                    UserDefaults.standard.set(token, forKey: "UserToken")
                }
                self?.navigateToHome()
            case .failure(let error):
                if case .serverError(_, let msg) = error {
                    // 如果提示未注册或其他业务错误
                    if msg.contains("不存在") || msg.contains("未注册") {
                        self?.showAlert(message: "账号不存在，请先注册") {
                            self?.handleRegister()
                        }
                    } else {
                        self?.showAlert(message: "登录失败: \(msg)")
                    }
                } else {
                    self?.showAlert(message: "登录失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func handleRegister() {
        print("跳转到注册页面")
        let registerVC = RegisterViewController()
        navigationController?.pushViewController(registerVC, animated: true)
    }
    
    // MARK: - Business Logic Helpers
    private func startCountdown() {
        sendCodeButton.isEnabled = false
        remainingSeconds = 60
        sendCodeButton.setTitle("\(remainingSeconds)s", for: .normal)
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.remainingSeconds -= 1
            
            if self.remainingSeconds <= 0 {
                self.stopTimer()
            } else {
                self.sendCodeButton.setTitle("\(self.remainingSeconds)s", for: .normal)
            }
        }
    }
    
    private func stopTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        sendCodeButton.isEnabled = true
        sendCodeButton.setTitle("发送", for: .normal)
    }
    
    private func navigateToHome() {
        // 保存登录状态
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        
        // 跳转到包含首页的 TabBarController
        let mainTabBar = MainTabBarController()
        mainTabBar.modalPresentationStyle = .fullScreen
        // 增加简单的转场动画
        mainTabBar.modalTransitionStyle = .crossDissolve
        
        // 为了确保根视图控制器彻底切换，防止内存泄漏或层级问题，建议直接重置 keyWindow 的 rootViewController
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = mainTabBar
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
        } else {
            present(mainTabBar, animated: true)
        }
    }
    
    private func mockRegisterAndNavigateToHome() {
        // 模拟静默注册流程
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.navigateToHome()
        }
    }
    
    // 点击空白处收起键盘
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}
