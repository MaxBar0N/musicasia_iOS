import UIKit
import SnapKit
import PhotosUI

class RegisterViewController: BaseViewController {
    
    // MARK: - UI Components
    private let backgroundImageView = UIImageView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // 使用 UIImageView 作为 cardView 以展示背景图片
    private let cardView = UIImageView()
    
    // Tabs
    private let personalTabBtn = UIButton(type: .system)
    private let businessTabBtn = UIButton(type: .system)
    
    // 渐变指示条
    private let tabIndicator = GradientIndicatorView()
    
    // Form Container
    private let formContainer = UIStackView()
    
    // Common Fields
    private let phoneField = FormInputField(title: "手机号", placeholder: "请输入手机号")
    private let codeField = FormCodeField(title: "验证码", placeholder: "请输入验证码")
    
    // Business Specific Fields
    private let shopNameField = FormInputField(title: "企业/店铺名", placeholder: "请输入企业/店铺名")
    private let serviceIdField = FormInputField(title: "服务工号", placeholder: "请输入服务工号")
    private let businessIdField = FormInputField(title: "业务工号", placeholder: "请输入业务工号")
    private let regionField = FormDropdownField(title: "地区")
    private let licenseUploadView = FormImageUploadView(title: "营业执照")
    private let shopPhotosUploadView = FormImageUploadView(title: "店铺照片", subtitle: "请上传4张店铺照片，大小不超过8cm", maxCount: 4)
    
    // Bottom Elements
    private let checkboxView = AgreementCheckboxView()
    private let registerButton = GradientButton()
    
    // Banner Image
    private let bannerImageView = UIImageView()
    
    // MARK: - Properties
    private var isPersonalMode = true
    private var countdownTimer: Timer?
    private var remainingSeconds = 60
    private var currentUploadView: FormImageUploadView?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "注册"
        setupUI()
        bindActions()
        switchMode(isPersonal: true, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopTimer()
    }
    
    private func setupUI() {
        setupBackground()
        
        scrollView.keyboardDismissMode = .onDrag
        
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        contentView.addGestureRecognizer(tapGesture)
        
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }
        
        setupCardView()
        setupTabs()
        setupBanner()
        setupForm()
    }
    
    private func setupBackground() {
        gradientLayer.isHidden = true
        
        backgroundImageView.image = UIImage(named: "login_background_image")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        view.insertSubview(backgroundImageView, at: 0)
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupCardView() {
        cardView.image = UIImage(named: "register_content_background")
        cardView.contentMode = .scaleToFill
        cardView.isUserInteractionEnabled = true
        cardView.layer.cornerRadius = 20
        cardView.clipsToBounds = true
        
        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview().inset(15)
            make.height.greaterThanOrEqualTo(UIScreen.main.bounds.height * 0.8)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    private func setupTabs() {
        personalTabBtn.setTitle("个人用户", for: .normal)
        personalTabBtn.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        personalTabBtn.setTitleColor(.white, for: .normal)
        
        businessTabBtn.setTitle("商业用户", for: .normal)
        businessTabBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        businessTabBtn.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .normal)
        
        let tabStack = UIStackView(arrangedSubviews: [personalTabBtn, businessTabBtn])
        tabStack.axis = .horizontal
        tabStack.spacing = 20
        
        cardView.addSubview(tabStack)
        tabStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(20)
        }
        
        cardView.addSubview(tabIndicator)
        tabIndicator.snp.makeConstraints { make in
            make.top.equalTo(personalTabBtn.titleLabel!.snp.bottom).offset(2)
            make.height.equalTo(2)
            make.width.equalTo(40)
            make.left.equalTo(personalTabBtn)
        }
        
        let recordImageView = UIImageView()
        recordImageView.image = UIImage(named: "register_top_image")
        recordImageView.contentMode = .scaleAspectFit
        contentView.addSubview(recordImageView)
        recordImageView.snp.makeConstraints { make in
            make.top.equalTo(cardView.snp.top).offset(-20) 
            make.right.equalTo(cardView.snp.right).offset(-20) // 向左偏移 40 (原为 +10，现为 -30)
            make.width.equalTo(80)
            make.height.equalTo(80)
        }
    }
    
    private func setupBanner() {
        bannerImageView.image = UIImage(named: "register_individual_image")
        bannerImageView.backgroundColor = .clear
        bannerImageView.layer.cornerRadius = 10
        bannerImageView.clipsToBounds = true
        bannerImageView.contentMode = .scaleAspectFill
        
        bannerImageView.snp.makeConstraints { make in
            make.height.equalTo(120)
        }
    }
    
    private func setupForm() {
        formContainer.axis = .vertical
        formContainer.spacing = 20
        
        // 将 banner 加入 StackView，隐藏时自动折叠空间
        formContainer.addArrangedSubview(bannerImageView)
        
        // 添加所有的字段到 StackView 中
        formContainer.addArrangedSubview(phoneField)
        formContainer.addArrangedSubview(codeField)
        
        // Business fields
        formContainer.addArrangedSubview(shopNameField)
        formContainer.addArrangedSubview(serviceIdField)
        formContainer.addArrangedSubview(businessIdField)
        formContainer.addArrangedSubview(regionField)
        formContainer.addArrangedSubview(licenseUploadView)
        formContainer.addArrangedSubview(shopPhotosUploadView)
        
        // 先将所有子视图添加到 cardView 中，防止约束找不到共同的父视图而崩溃
        cardView.addSubview(formContainer)
        cardView.addSubview(checkboxView)
        cardView.addSubview(registerButton)
        
        formContainer.snp.makeConstraints { make in
            make.top.equalTo(tabIndicator.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
            // 确保不会撑破卡片
            make.bottom.lessThanOrEqualTo(checkboxView.snp.top).offset(-20)
        }
        
        registerButton.setTitle("注册", for: .normal)
        registerButton.customCornerRadius = 20
        registerButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-20)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(40)
        }
        
        checkboxView.snp.makeConstraints { make in
            make.bottom.equalTo(registerButton.snp.top).offset(-20)
            make.left.right.equalToSuperview().inset(20)
        }
    }
    
    // MARK: - Actions
    private func bindActions() {
        personalTabBtn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        businessTabBtn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        
        codeField.sendButton.addTarget(self, action: #selector(handleSendCode), for: .touchUpInside)
        registerButton.addTarget(self, action: #selector(handleRegister), for: .touchUpInside)
        
        // 监听业务工号的输入变化，模拟带出地区
        businessIdField.textField.addTarget(self, action: #selector(businessIdChanged), for: .editingChanged)
        
        // 地区选择点击事件
        let showRegionPicker = { [weak self] in
            self?.view.endEditing(true)
            
            let picker = RegionPickerView()
            if let window = UIApplication.shared.windows.first {
                picker.show(in: window)
            } else if let view = self?.view {
                picker.show(in: view)
            }
            
            picker.onConfirm = { province, city in
                self?.regionField.provinceButton.setTitle(province, for: .normal)
                self?.regionField.cityButton.setTitle(city, for: .normal)
                
                // 将颜色恢复为白色高亮状态，表示已选择
                self?.regionField.provinceButton.setTitleColor(.white, for: .normal)
                self?.regionField.cityButton.setTitleColor(.white, for: .normal)
            }
        }
        
        regionField.onProvinceTapped = showRegionPicker
        regionField.onCityTapped = showRegionPicker
        
        // 图片上传点击事件
        licenseUploadView.onUploadTapped = { [weak self] in
            self?.view.endEditing(true)
            self?.showPhotoActionSheet(for: self?.licenseUploadView)
        }
        
        shopPhotosUploadView.onUploadTapped = { [weak self] in
            self?.view.endEditing(true)
            self?.showPhotoActionSheet(for: self?.shopPhotosUploadView)
        }
    }
    
    private func showPhotoActionSheet(for uploadView: FormImageUploadView?) {
        guard let uploadView = uploadView else { return }
        self.currentUploadView = uploadView
        
        let alert = UIAlertController(title: "上传照片", message: "请选择照片获取方式", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "拍照", style: .default, handler: { _ in
            self.openImagePicker(sourceType: .camera)
        }))
        
        alert.addAction(UIAlertAction(title: "从相册选择", style: .default, handler: { _ in
            self.openImagePicker(sourceType: .photoLibrary)
        }))
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        
        // 适配 iPad 弹出位置
        if let popover = alert.popoverPresentationController {
            popover.sourceView = uploadView
            popover.sourceRect = uploadView.bounds
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func openImagePicker(sourceType: UIImagePickerController.SourceType) {
        if sourceType == .photoLibrary {
            var config = PHPickerConfiguration()
            config.filter = .images
            
            let currentCount = currentUploadView?.images.count ?? 0
            let maxCount = currentUploadView?.maxCount ?? 1
            let limit = maxCount - currentCount
            
            if limit <= 0 {
                self.showAlert(message: "已达到最大照片数量限制")
                return
            }
            
            config.selectionLimit = limit
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        } else {
            guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
                self.showAlert(message: "当前设备不支持该功能（模拟器可能无法使用相机）")
                return
            }
            let picker = UIImagePickerController()
            picker.sourceType = sourceType
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    private func uploadSelectedImages(_ images: [UIImage], to uploadView: FormImageUploadView?) {
        guard let uploadView = uploadView, !images.isEmpty else { return }
        
        self.showLoading()
        let group = DispatchGroup()
        
        // 使用一个结构体记录每张照片的上传结果（保证顺序）
        struct UploadResult {
            let image: UIImage
            let url: String?
            let errorMsg: String?
        }
        
        // 初始化一个固定大小的数组，防止并发写入导致线程不安全或顺序错乱
        var results: [UploadResult?] = Array(repeating: nil, count: images.count)
        let queue = DispatchQueue(label: "com.musicasia.uploadQueue")
        
        for (index, image) in images.enumerated() {
            group.enter()
            CommonAPI.uploadImage(image: image) { apiResult in
                let resultObj: UploadResult
                switch apiResult {
                case .success(let url):
                    resultObj = UploadResult(image: image, url: url, errorMsg: nil)
                case .failure(let error):
                    resultObj = UploadResult(image: image, url: nil, errorMsg: error.localizedDescription)
                }
                
                queue.async {
                    results[index] = resultObj
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.hideLoading()
            
            var successImages: [UIImage] = []
            var successUrls: [String] = []
            var failureCount = 0
            var lastErrorMsg: String? = nil
            
            for result in results {
                guard let res = result else { continue }
                if let url = res.url {
                    successImages.append(res.image)
                    successUrls.append(url)
                } else {
                    failureCount += 1
                    lastErrorMsg = res.errorMsg
                }
            }
            
            // 将成功的照片添加到 UI 组件中
            if !successImages.isEmpty {
                uploadView.addImages(successImages)
                for url in successUrls {
                    uploadView.addUploadedUrl(url)
                }
            }
            
            // 提示上传结果
            if failureCount > 0 {
                if successImages.isEmpty {
                    self?.showAlert(message: "照片上传失败: \(lastErrorMsg ?? "未知错误")")
                } else {
                    self?.showAlert(message: "已成功上传 \(successImages.count) 张，有 \(failureCount) 张上传失败，请重新选择并上传。")
                }
            }
        }
    }
    
    @objc private func tabTapped(_ sender: UIButton) {
        let isPersonal = (sender == personalTabBtn)
        switchMode(isPersonal: isPersonal, animated: true)
    }
    
    private func switchMode(isPersonal: Bool, animated: Bool = true) {
        self.isPersonalMode = isPersonal
        
        personalTabBtn.titleLabel?.font = isPersonal ? .systemFont(ofSize: 20, weight: .bold) : .systemFont(ofSize: 16, weight: .regular)
        personalTabBtn.setTitleColor(isPersonal ? .white : UIColor.white.withAlphaComponent(0.6), for: .normal)
        
        businessTabBtn.titleLabel?.font = !isPersonal ? .systemFont(ofSize: 20, weight: .bold) : .systemFont(ofSize: 16, weight: .regular)
        businessTabBtn.setTitleColor(!isPersonal ? .white : UIColor.white.withAlphaComponent(0.6), for: .normal)
        
        let updateLayout = {
            self.tabIndicator.snp.remakeConstraints { make in
                let targetBtn = isPersonal ? self.personalTabBtn : self.businessTabBtn
                make.top.equalTo(targetBtn.titleLabel!.snp.bottom).offset(2)
                make.height.equalTo(2)
                make.width.equalTo(40)
                make.left.equalTo(targetBtn)
            }
            self.view.layoutIfNeeded()
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, animations: updateLayout)
        } else {
            updateLayout()
        }
        
        // 控制业务字段的显示隐藏
        let businessFields = [shopNameField, serviceIdField, businessIdField, regionField, licenseUploadView, shopPhotosUploadView]
        for field in businessFields {
            field.isHidden = isPersonal
        }
        
        // 商业用户不展示 Banner
        bannerImageView.isHidden = !isPersonal
    }
    
    // MARK: - Business Logic
    @objc private func handleSendCode() {
        guard let phone = phoneField.textField.text, !phone.isEmpty else {
            showAlert(message: "请输入手机号")
            return
        }
        
        print("发送验证码到 \(phone)")
        startCountdown()
        
        AuthAPI.sendRegisterCode(phone: phone) { [weak self] result in
            switch result {
            case .success(let data):
                print("注册验证码发送成功: \(data ?? "")")
                self?.showAlert(message: "验证码已发送，请注意查收")
            case .failure(let error):
                if case .serverError(_, let msg) = error, msg.contains("已注册") {
                    self?.showAlert(message: "此手机号已注册，请更换手机号注册，谢谢")
                } else {
                    self?.showAlert(message: "验证码发送失败: \(error.localizedDescription)")
                }
                self?.stopTimer()
            }
        }
    }
    
    @objc private func handleRegister() {
        if !checkboxView.isChecked {
            showAlert(message: "请先同意平台注册规则")
            return
        }
        
        guard let phone = phoneField.textField.text, !phone.isEmpty else {
            showAlert(message: "请输入手机号")
            return
        }
        
        guard let code = codeField.textField.text, !code.isEmpty else {
            showAlert(message: "请输入验证码")
            return
        }
        
        var body = PhoneRegisterBody(phone: phone, code: code, registerType: isPersonalMode ? "PERSON" : "BUSINESS")
        UserDefaults.standard.set(body.registerType, forKey: "UserRegisterType") // 缓存给购买套餐分类使用
        
        if isPersonalMode {
            // A2、生成个人用户信息
            print("生成个人用户信息")
            body.area = "默认地区"
            self.submitRegister(body: body)
        } else {
            // B2、业务工号验证
            guard let bizId = businessIdField.textField.text, !bizId.isEmpty else {
                showAlert(message: "请输入业务工号")
                return
            }
            // 真实的业务工号验证应在获取验证码或这里进行后端验证
            body.salesmanCode = bizId
            body.area = regionField.provinceButton.titleLabel?.text
            body.companyName = shopNameField.textField.text
            body.serviceCode = serviceIdField.textField.text
            
            // 直接从 UI 组件中获取已经上传成功的 URL
            body.businessLicense = licenseUploadView.uploadedUrls.first
            let shopUrls = shopPhotosUploadView.uploadedUrls
            if shopUrls.count > 0 { body.companyPic1 = shopUrls[0] }
            if shopUrls.count > 1 { body.companyPic2 = shopUrls[1] }
            if shopUrls.count > 2 { body.companyPic3 = shopUrls[2] }
            if shopUrls.count > 3 { body.companyPic4 = shopUrls[3] }
            
            self.submitRegister(body: body)
        }
    }
    
    private func submitRegister(body: PhoneRegisterBody) {
        AuthAPI.register(body: body) { [weak self] result in
            switch result {
            case .success(let token):
                print("注册成功，Token: \(token ?? "")")
                if let token = token, !token.isEmpty {
                    UserDefaults.standard.set(token, forKey: "UserToken")
                }
                self?.showWarmPrompt()
            case .failure(let error):
                if case .serverError(_, let msg) = error {
                    if msg.contains("过期") {
                        self?.showAlert(message: "验证码已过期，重新获取")
                    } else if msg.contains("验证码不正确") {
                        self?.showAlert(message: "验证码不正确，请重新输入")
                    } else if msg.contains("业务工号不存在") {
                        self?.showAlert(message: "业务工号不存在，请确认，谢谢")
                    } else {
                        self?.showAlert(message: "注册失败: \(msg)")
                    }
                } else {
                    self?.showAlert(message: "注册失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func businessIdChanged() {
        // A、地区：由业务员工号带出所属代理的代理城市
        let bizId = businessIdField.textField.text ?? ""
        if bizId.count >= 4 { // 假设工号到达一定长度才去请求
            AuthAPI.getAreaBySalesmanCode(code: bizId) { [weak self] result in
                switch result {
                case .success(let data):
                    if let firstProvince = data.children?.first {
                        self?.regionField.provinceButton.setTitle(firstProvince.name ?? "未知省份", for: .normal)
                        self?.regionField.cityButton.setTitle("未知城市", for: .normal) // 如果有city的话
                    } else {
                        self?.regionField.provinceButton.setTitle("请选择省份", for: .normal)
                    }
                case .failure:
                    self?.regionField.provinceButton.setTitle("请选择省份", for: .normal)
                    self?.regionField.cityButton.setTitle("请选择城市", for: .normal)
                }
            }
        } else {
            regionField.provinceButton.setTitle("请选择省份", for: .normal)
            regionField.cityButton.setTitle("请选择城市", for: .normal)
        }
    }
    
    private func showWarmPrompt() {
        // 弹出温馨提示
        let alertView = CustomAlertView()
        alertView.show(in: self.navigationController?.view ?? self.view)
        
        alertView.purchaseButton.addTarget(self, action: #selector(handlePurchase), for: .touchUpInside)
        alertView.activateButton.addTarget(self, action: #selector(handleActivate), for: .touchUpInside)
    }
    
    @objc private func handlePurchase() {
        print("点击了购买")
        // 注册完成，保存登录状态
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        
        // 跳转到购买页面 (先进入首页，然后自动切换到“我的”并 Push 到购买)
        let mainTabBar = MainTabBarController()
        mainTabBar.selectedIndex = 3 // "我的" Tab
        if let nav = mainTabBar.viewControllers?[3] as? UINavigationController {
            let purchaseVC = PurchaseViewController()
            nav.pushViewController(purchaseVC, animated: false)
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = mainTabBar
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
        }
    }
    
    @objc private func handleActivate() {
        print("点击了激活")
        // 注册完成，保存登录状态
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        
        // 跳转到设备激活页面 (先进入首页，然后自动切换到“我的”并 Push 到设备页)
        let mainTabBar = MainTabBarController()
        mainTabBar.selectedIndex = 3 // "我的" Tab
        if let nav = mainTabBar.viewControllers?[3] as? UINavigationController {
            let deviceVC = DeviceViewController()
            nav.pushViewController(deviceVC, animated: false)
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = mainTabBar
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
        }
    }
    
    private func navigateToHome() {
        let mainTabBar = MainTabBarController()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = mainTabBar
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
        }
    }
    
    // MARK: - Timer Helpers
    private func startCountdown() {
        codeField.sendButton.isEnabled = false
        remainingSeconds = 60
        codeField.sendButton.setTitle("\(remainingSeconds)s", for: .normal)
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.remainingSeconds -= 1
            
            if self.remainingSeconds <= 0 {
                self.stopTimer()
            } else {
                self.codeField.sendButton.setTitle("\(self.remainingSeconds)s", for: .normal)
            }
        }
    }
    
    private func stopTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        codeField.sendButton.isEnabled = true
        codeField.sendButton.setTitle("发送", for: .normal)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func handleUserAgreement() {
        let vc = AgreementViewController()
        vc.agreementTitle = "使用协议"
        vc.urlString = "https://musicasia.cn/agreement"
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func handlePrivacyPolicy() {
        let vc = AgreementViewController()
        vc.agreementTitle = "隐私协议"
        vc.urlString = "https://musicasia.cn/privacy"
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let image = info[.originalImage] as? UIImage {
            uploadSelectedImages([image], to: currentUploadView)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension RegisterViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard !results.isEmpty else { return }
        
        let group = DispatchGroup()
        var imagesDict: [Int: UIImage] = [:]
        
        for (index, result) in results.enumerated() {
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                    if let image = object as? UIImage {
                        DispatchQueue.main.async {
                            imagesDict[index] = image
                        }
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            let sortedKeys = imagesDict.keys.sorted()
            let sortedImages = sortedKeys.compactMap { imagesDict[$0] }
            self.uploadSelectedImages(sortedImages, to: self.currentUploadView)
        }
    }
}
