import UIKit
import SnapKit

class ActivationCodeViewController: BaseViewController {
    
    var order: OrderModel?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "查看激活码"
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }
        
        // Header Banner
        let headerContainer = UIView()
        headerContainer.backgroundColor = UIColor(hex: "#1E3B70")
        headerContainer.layer.cornerRadius = 12
        headerContainer.clipsToBounds = true
        contentView.addSubview(headerContainer)
        
        let bannerImageView = UIImageView()
        bannerImageView.contentMode = .scaleAspectFill
        bannerImageView.image = UIImage(named: "activation_code_banner")
        headerContainer.addSubview(bannerImageView)
        
//        let gradientLayer = CAGradientLayer()
//        gradientLayer.colors = [
//            UIColor.clear.cgColor,
//            UIColor(hex: "#8C52FF").withAlphaComponent(0.6).cgColor
//        ]
//        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
//        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
//        let overlay = UIView()
//        overlay.layer.addSublayer(gradientLayer)
//        headerContainer.addSubview(overlay)
        
//        let titleLabel = UILabel()
//        titleLabel.text = "K歌激活码"
//        titleLabel.textColor = .white
//        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
//        headerContainer.addSubview(titleLabel)
        
        headerContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview().inset(15)
            make.height.equalTo(headerContainer.snp.width).multipliedBy(120.0 / 312.0)
        }
        
        bannerImageView.snp.makeConstraints { make in make.edges.equalToSuperview() }
//        overlay.snp.makeConstraints { make in make.edges.equalToSuperview() }
        
//        titleLabel.snp.makeConstraints { make in
//            make.left.equalToSuperview().offset(15)
//            make.bottom.equalToSuperview().offset(-10)
//        }
//        
//        DispatchQueue.main.async {
//            gradientLayer.frame = overlay.bounds
//        }
        
        // Codes List
        let codesStack = UIStackView()
        codesStack.axis = .vertical
        codesStack.spacing = 0 // 移除 spacing，因为 CodeRowView 内部已经定义了 height = 44
        contentView.addSubview(codesStack)
        
        codesStack.snp.makeConstraints { make in
            make.top.equalTo(headerContainer.snp.bottom).offset(15) // 缩小顶部间距
            make.left.right.equalToSuperview().inset(20)
        }
        
        guard let codes = order?.activationCodes else { return }
        for code in codes {
            let row = CodeRowView()
            row.configure(code: code)
            row.onCopyTapped = { [weak self] pureCode in
                self?.handleCopy(code: pureCode)
            }
            codesStack.addArrangedSubview(row)
        }
        
        let linksStack = UIStackView()
        linksStack.axis = .horizontal
        linksStack.spacing = 20
        linksStack.distribution = .fillEqually
        linksStack.isHidden = true 
        contentView.addSubview(linksStack)
        
        let changbaBtn = GradientButton()
        changbaBtn.setTitle("前往唱吧", for: .normal)
        changbaBtn.addTarget(self, action: #selector(openChangba), for: .touchUpInside)
        linksStack.addArrangedSubview(changbaBtn)
        
        let unicomBtn = GradientBorderButton()
        unicomBtn.setTitle("前往联通", for: .normal)
        unicomBtn.addTarget(self, action: #selector(openUnicom), for: .touchUpInside)
        linksStack.addArrangedSubview(unicomBtn)
        
        linksStack.snp.makeConstraints { make in
            make.top.equalTo(codesStack.snp.bottom).offset(50)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().offset(-30)
        }
    }
    
    // MARK: - Actions
    private func handleCopy(code: String) {
        UIPasteboard.general.string = code
        print("复制了激活码: \(code)")
        
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
        
        let popup = CopySuccessPopupView()
        popup.show(in: window)
    }
    
    @objc private func openChangba() {
        print("跳转外部链接：唱吧")
        if let url = URL(string: "changba://") {
            UIApplication.shared.open(url, options: [:]) { success in
                if !success {
                    print("未安装唱吧 App")
                }
            }
        }
    }
    
    @objc private func openUnicom() {
        print("跳转外部链接：联通")
        if let url = URL(string: "unicom://") {
            UIApplication.shared.open(url, options: [:]) { success in
                if !success {
                    print("未安装联通 App")
                }
            }
        }
    }
}
