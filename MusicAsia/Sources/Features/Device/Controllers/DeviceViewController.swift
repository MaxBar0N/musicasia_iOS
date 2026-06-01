import UIKit
import SnapKit

class DeviceViewController: BaseViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let listStack = UIStackView()
    private var emptyView: DeviceEmptyView?
    private var popup: BindDevicePopupView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "设备"
        
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        loadData()
    }
    
    private func setupUI() {
        // Navigation Bar Add Button
        let addBtn = UIBarButtonItem(image: UIImage(systemName: "plus.square"), style: .plain, target: self, action: #selector(showAddPopup))
        addBtn.tintColor = .white
        navigationItem.rightBarButtonItem = addBtn
        
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
            // 确保 contentView 至少有一点高度来让 StackView 能够展开
            make.height.greaterThanOrEqualTo(view.safeAreaLayoutGuide).priority(.low)
        }
        
        listStack.axis = .vertical
        listStack.spacing = 15
        contentView.addSubview(listStack)
        
        listStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalToSuperview().offset(-30)
        }
    }
    
    private func loadData() {
        self.listStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        self.emptyView?.removeFromSuperview()
        self.emptyView = nil
        
        let devices = DeviceDataManager.shared.userDevices
        
        if devices.isEmpty {
            self.showEmptyState()
        } else {
            for device in devices {
                let row = DeviceRowView()
                row.configure(device: device)
                
                row.onDeleteTapped = { [weak self] in
                    self?.handleDelete(device: device)
                }
                
                self.listStack.addArrangedSubview(row)
                row.snp.makeConstraints { make in make.height.equalTo(60) }
            }
            
            // 强制刷新布局，确保 UIStackView 能够正确渲染子视图
            DispatchQueue.main.async {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func showEmptyState() {
        if emptyView == nil {
            emptyView = DeviceEmptyView()
            emptyView?.onAddTapped = { [weak self] in
                print("触发 onAddTapped 回调")
                self?.showAddPopup()
            }
        }
        
        view.addSubview(emptyView!)
        emptyView?.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(100)
            make.left.right.equalToSuperview()
            make.height.equalTo(300)
        }
    }
    
    // MARK: - Actions
    @objc private func showAddPopup() {
        if popup == nil {
            popup = BindDevicePopupView()
            popup?.onBind = { [weak self] serialNo in
                self?.handleBind(serialNo: serialNo)
            }
            popup?.onScanTapped = { [weak self] in
                self?.handleScan()
            }
        }
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
        popup?.show(in: window)
    }
    
    private func handleScan() {
        popup?.hide()
        let scannerVC = ScannerViewController()
        scannerVC.onScanSuccess = { [weak self] code in
            // 扫码成功后自动填入并绑定，或者弹出弹窗
            self?.handleBind(serialNo: code)
        }
        navigationController?.pushViewController(scannerVC, animated: true)
    }
    
    private func handleBind(serialNo: String) {
        DeviceDataManager.shared.addDevice(serialNo: serialNo) { [weak self] result in
            switch result {
            case .success:
                self?.showAlert(message: "设备绑定成功") {
                    self?.popup?.hide()
                    self?.popup = nil
                    self?.loadData()
                }
            case .failure(let error):
                self?.showAlert(message: error.localizedDescription)
            }
        }
    }
    
    private func handleDelete(device: DeviceModel) {
        let alert = UIAlertController(title: "提示", message: "确定要删除此设备吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            DeviceDataManager.shared.userDevices.removeAll { $0.id == device.id }
            self.loadData()
        })
        present(alert, animated: true)
    }
}
