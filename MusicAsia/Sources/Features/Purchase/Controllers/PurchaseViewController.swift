import UIKit
import SnapKit

class PurchaseViewController: BaseViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let topCardView = UIView()
    private let categoryStackView = UIStackView()
    private let categoryIndicator = UIView()
    private var categoryButtons: [UIButton] = []
    
    private let descLabel = UILabel()
    
    private var collectionView: UICollectionView!
    
    private let wechatPayView = UIView()
    private let agreementView = AgreementCheckboxView(text: "购买代表同意并接受 ", linkText: "《平台交易规则》")
    private let payButton = GradientButton()
    
    private let bottomCardView = UIView()
    private let benefitsStackView = UIStackView()
    
    private var isPersonalUser: Bool = true
    private var categories: [PackageCategory] = []
    private var currentCategoryIndex = 0
    private var currentPackageIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "购买套餐"
        
        setupUI()
        loadData()
        updateUIForCurrentSelection()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func loadData() {
        // 先获取套餐分类字典 user_menu_type
        OrderAPI.getDictData(dictType: "user_menu_type") { [weak self] dictResult in
            guard let self = self else { return }
            
            var dictCategories: [PackageCategory] = []
            
            switch dictResult {
            case .success(let dictList):
                let userType = UserDefaults.standard.string(forKey: "UserRegisterType") ?? "PERSON"
                
                for dict in dictList {
                    guard let label = dict.dictLabel, let value = dict.dictValue else { continue }
                    
                    // 匹配当前账号类型：如果是 PERSON 只能看 PERSON；如果是 BUSINESS 则看 BUSINESS 相关的
                    if userType == "PERSON" && value != "PERSON" { continue }
                    if userType == "BUSINESS" && !value.hasPrefix("BUSINESS") { continue }
                    
                    let desc = dict.remark ?? "专属套餐"
                    dictCategories.append(PackageCategory(id: value, name: label, desc: desc, packages: [], benefits: []))
                }
            case .failure(let error):
                print("获取套餐分类字典失败: \(error)")
            }
            
            if dictCategories.isEmpty {
                // 如果字典为空或者过滤后为空，塞一个默认的
                dictCategories.append(PackageCategory(id: "APP", name: "APP套餐", desc: "所有套餐", packages: [], benefits: []))
            }
            
            self.categories = dictCategories
            DispatchQueue.main.async {
                self.setupCategoryButtons()
                self.loadPackagesForCurrentCategory()
            }
        }
    }
    
    private func loadPackagesForCurrentCategory() {
        guard !categories.isEmpty, currentCategoryIndex < categories.count else { return }
        
        let currentCat = categories[currentCategoryIndex]
        // 如果已经加载过了，就不重复加载
        if !currentCat.packages.isEmpty {
            self.updateUIForCurrentSelection()
            return
        }
        
        let dictValue = currentCat.id
        
        OrderAPI.getMenuList(dictValue: dictValue) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                let list = response.voList ?? []
                var pkgs: [PackageItem] = []
                
                for vo in list {
                    var days = 365
                    if let type = vo.timeType?.value, type == "DAY", let yearStr = vo.setMenuYear?.value, let dayCount = Int(yearStr) {
                        days = dayCount
                    } else if let yearStr = vo.setMenuYear?.value, let yearCount = Int(yearStr) {
                        days = yearCount * 365
                    }
                    
                    let actCount = Int(vo.activationCodeNumber?.value ?? "1") ?? 1
                    let isTrial = (vo.setMenuName?.value.contains("试用") == true)
                    let benefitsList = vo.content?.value.components(separatedBy: .newlines).filter { !$0.isEmpty } ?? []
                    
                    let item = PackageItem(id: vo.setMenuId?.value ?? "0",
                                           name: vo.setMenuName?.value ?? "未知套餐",
                                           price: Double(vo.nowPrice?.value ?? "0") ?? 0,
                                           originalPrice: Double(vo.originPrice?.value ?? "0") ?? 0,
                                           durationInDays: days,
                                           isTrial: isTrial,
                                           activationCodeCount: actCount,
                                           benefits: benefitsList,
                                           customerDesc: vo.customerDescription?.value ?? "")
                    
                    pkgs.append(item)
                }
                
                self.categories[self.currentCategoryIndex].packages = pkgs
                self.currentPackageIndex = 0
                
                DispatchQueue.main.async {
                    self.updateUIForCurrentSelection()
                }
                
            case .failure(let error):
                print("获取套餐列表失败: \(error)")
                self.categories[self.currentCategoryIndex].packages = []
                self.currentPackageIndex = 0
                DispatchQueue.main.async {
                    self.updateUIForCurrentSelection()
                }
            }
        }
    }
    
    private func setupCategoryButtons() {
        // 清空原有的按钮
        categoryButtons.forEach { $0.removeFromSuperview() }
        categoryButtons.removeAll()
        
        for (index, cat) in categories.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(cat.name, for: .normal)
            btn.tag = index
            btn.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
            categoryButtons.append(btn)
            categoryStackView.addArrangedSubview(btn)
        }
        
        if !categories.isEmpty {
            DispatchQueue.main.async {
                self.updateIndicatorPosition()
            }
        }
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }
        
        setupTopCard()
        setupBottomCard()
        
        contentView.snp.makeConstraints { make in
            make.bottom.equalTo(bottomCardView.snp.bottom).offset(30)
        }
    }
    
    private func setupTopCard() {
        topCardView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        topCardView.layer.cornerRadius = 16
        contentView.addSubview(topCardView)
        
        topCardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview().inset(15)
        }
        
        categoryStackView.axis = .horizontal
        categoryStackView.spacing = 20
        topCardView.addSubview(categoryStackView)
        
        for (index, cat) in categories.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(cat.name, for: .normal)
            btn.tag = index
            btn.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
            categoryButtons.append(btn)
            categoryStackView.addArrangedSubview(btn)
        }
        
        categoryStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(20)
            make.height.equalTo(30)
        }
        
        categoryIndicator.backgroundColor = UIColor(hex: "#16E0BF")
        topCardView.addSubview(categoryIndicator)
        
        descLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        descLabel.font = .systemFont(ofSize: 12)
        descLabel.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        descLabel.layer.cornerRadius = 6
        descLabel.clipsToBounds = true
        topCardView.addSubview(descLabel)
        
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(categoryStackView.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(36)
        }
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 130)
        layout.minimumInteritemSpacing = 15
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PackageItemCell.self, forCellWithReuseIdentifier: "PackageItemCell")
        topCardView.addSubview(collectionView)
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(130)
        }
        
        wechatPayView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        wechatPayView.layer.cornerRadius = 8
        topCardView.addSubview(wechatPayView)
        
        let wxIcon = UIImageView(image: UIImage(named: "wechat_pay_logo"))
        wxIcon.contentMode = .scaleAspectFit
        wechatPayView.addSubview(wxIcon)
        
        let wxLabel = UILabel()
        wxLabel.text = "微信支付"
        wxLabel.textColor = .white
        wechatPayView.addSubview(wxLabel)
        
        let checkIcon = UIImageView(image: UIImage(systemName: "circle.circle.fill"))
        checkIcon.tintColor = UIColor(hex: "#16E0BF")
        wechatPayView.addSubview(checkIcon)
        
        wechatPayView.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }
        wxIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24) // 限制下微信logo的尺寸
        }
        wxLabel.snp.makeConstraints { make in
            make.left.equalTo(wxIcon.snp.right).offset(10)
            make.centerY.equalToSuperview()
        }
        checkIcon.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-15)
            make.centerY.equalToSuperview()
        }
        
        topCardView.addSubview(agreementView)
        agreementView.snp.makeConstraints { make in
            make.top.equalTo(wechatPayView.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
        }
        
        payButton.addTarget(self, action: #selector(handlePay), for: .touchUpInside)
        topCardView.addSubview(payButton)
        payButton.snp.makeConstraints { make in
            make.top.equalTo(agreementView.snp.bottom).offset(15)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    private func setupBottomCard() {
        bottomCardView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        bottomCardView.layer.cornerRadius = 16
        contentView.addSubview(bottomCardView)
        
        bottomCardView.snp.makeConstraints { make in
            make.top.equalTo(topCardView.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(15)
        }
        
        let titleLabel = UILabel()
        titleLabel.text = "套餐包含"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        bottomCardView.addSubview(titleLabel)
        
        let line = UIView()
        line.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        bottomCardView.addSubview(line)
        
        benefitsStackView.axis = .vertical
        benefitsStackView.spacing = 15
        bottomCardView.addSubview(benefitsStackView)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(15)
            make.left.equalToSuperview().offset(20)
        }
        
        line.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(1)
        }
        
        benefitsStackView.snp.makeConstraints { make in
            make.top.equalTo(line.snp.bottom).offset(15)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    private func updateIndicatorPosition() {
        guard !categoryButtons.isEmpty, currentCategoryIndex < categoryButtons.count else { return }
        guard categoryIndicator.superview != nil else { return } // 保护
        
        categoryIndicator.snp.remakeConstraints { make in
            make.top.equalTo(categoryStackView.snp.bottom).offset(5)
            make.height.equalTo(2)
            make.width.equalTo(30)
            make.centerX.equalTo(categoryButtons[currentCategoryIndex])
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func categoryTapped(_ sender: UIButton) {
        currentCategoryIndex = sender.tag
        currentPackageIndex = 0
        loadPackagesForCurrentCategory()
    }
    
    private func updateUIForCurrentSelection() {
        guard !categories.isEmpty, currentCategoryIndex < categories.count else { return }
        
        let category = categories[currentCategoryIndex]
        
        for (i, btn) in categoryButtons.enumerated() {
            let isSelected = (i == currentCategoryIndex)
            btn.setTitleColor(isSelected ? .white : UIColor.white.withAlphaComponent(0.6), for: .normal)
            btn.titleLabel?.font = isSelected ? .systemFont(ofSize: 22, weight: .bold) : .systemFont(ofSize: 16, weight: .regular)
        }
        
        if categoryIndicator.superview != nil {
            categoryIndicator.snp.remakeConstraints { make in
                make.top.equalTo(categoryStackView.snp.bottom).offset(5)
                make.height.equalTo(2)
                make.width.equalTo(30)
                make.centerX.equalTo(categoryButtons[currentCategoryIndex])
            }
        }
        
        collectionView.reloadData()
        if !category.packages.isEmpty {
            let indexPath = IndexPath(item: currentPackageIndex, section: 0)
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
        }
        
        updatePayButtonPrice()
    }
    
    private func updatePayButtonPrice() {
        guard !categories.isEmpty, currentCategoryIndex < categories.count else {
            payButton.setTitle("加载中...", for: .normal)
            payButton.isEnabled = false
            return
        }
        
        let category = categories[currentCategoryIndex]
        if category.packages.isEmpty {
            payButton.setTitle("暂无套餐", for: .normal)
            payButton.isEnabled = false
            descLabel.text = "   " + category.desc
            descLabel.isHidden = false
            benefitsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            return
        }
        
        let package = category.packages[currentPackageIndex]
        
        // 动态更新客户说明
        if let desc = package.customerDesc, !desc.isEmpty {
            descLabel.text = "   " + desc
            descLabel.isHidden = false
        } else {
            descLabel.text = "   " + category.desc
            descLabel.isHidden = false
        }
        
        // 动态更新特权
        benefitsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let currentBenefits = package.benefits.isEmpty ? category.benefits : package.benefits.map { PackageBenefit(name: $0, desc: nil, price: nil) }
        for benefit in currentBenefits {
            benefitsStackView.addArrangedSubview(BenefitRowView(benefit: benefit))
        }
        
        payButton.setTitle("确认协议并以 ¥\(package.price) 开通", for: .normal)
        payButton.isEnabled = true
    }
    
    @objc private func handlePay() {
        guard agreementView.isChecked else {
            showAlert(message: "请先阅读并同意《会员服务协议》和《自动续费服务协议》")
            return
        }
        
        guard currentCategoryIndex < categories.count else { return }
        let category = categories[currentCategoryIndex]
        guard currentPackageIndex < category.packages.count else { return }
        
        let pkg = category.packages[currentPackageIndex]
        
        // C1、试用套餐重复购买拦截校验
        if pkg.isTrial {
            // TODO: 这里应根据后台接口或订单列表校验，暂用 UserDefaults 模拟本地已购记录
            let trialPurchasedKey = "HasPurchasedTrial_\(pkg.id)"
            if UserDefaults.standard.bool(forKey: trialPurchasedKey) {
                showAlert(message: "试用套餐每个账号只能购买一次，请购买其他的套餐，谢谢")
                return
            }
            UserDefaults.standard.set(true, forKey: trialPurchasedKey)
        }
        
        // C2、发起支付前先调后台下单接口
        guard let setMenuId = Int(pkg.id) else { return }
        
        let loadingAlert = UIAlertController(title: "正在创建订单...", message: nil, preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        OrderAPI.placeAppOrder(setMenuId: setMenuId) { [weak self] result in
            guard let self = self else { return }
            loadingAlert.dismiss(animated: true) {
                switch result {
                case .success(let orderInfo):
                    // 下单成功后，这里应该是唤起微信支付 SDK
                    // 模拟支付成功流程 (D7: 跳转下单成功页)
                    let orderNo = orderInfo ?? "WX_PAY_MOCK_ORDER"
                    print("后台订单创建成功，准备唤起微信支付: \(orderNo)")
                    self.simulateWechatPaySuccess(orderNo: orderNo)
                case .failure(let error):
                    self.showAlert(message: "创建订单失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func simulateWechatPaySuccess(orderNo: String) {
        // 模拟微信支付成功后的回调，直接跳转成功页 (D7)
        // 注意：D1~D6 (延长有效期、生成激活码、联通续费等) 是由后台在收到微信支付回调后处理的
        DispatchQueue.main.async {
            self.showSuccessPopup(orderNo: orderNo)
        }
    }
    
    private func showSuccessPopup(orderNo: String) {
        let popup = OrderSuccessPopupView()
        popup.configure(orderNo: orderNo)
        popup.show(in: self.navigationController?.view ?? self.view)
        
        popup.onHomeTapped = { [weak self] in
            self?.navigationController?.popToRootViewController(animated: true)
            if let tabBarController = self?.view.window?.rootViewController as? UITabBarController {
                tabBarController.selectedIndex = 0
            }
        }
        
        popup.onReceiveCodeTapped = { [weak self] in
            print("跳转到我的订单页面")
            let orderVC = OrderListViewController()
            self?.navigationController?.pushViewController(orderVC, animated: true)
        }
    }
}

extension PurchaseViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard !categories.isEmpty, currentCategoryIndex < categories.count else { return 0 }
        return categories[currentCategoryIndex].packages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PackageItemCell", for: indexPath) as! PackageItemCell
        if !categories.isEmpty, currentCategoryIndex < categories.count, indexPath.row < categories[currentCategoryIndex].packages.count {
            let package = categories[currentCategoryIndex].packages[indexPath.row]
            cell.configure(with: package)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        currentPackageIndex = indexPath.row
        updatePayButtonPrice()
    }
}
