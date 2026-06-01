import UIKit
import SnapKit

class OrderListViewController: BaseViewController {
    
    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let ordersStack = UIStackView()
    
    private let footerView = UIView()
    private let loadMoreLabel = UILabel()
    private let arrowIcon = UIImageView(image: UIImage(systemName: "chevron.up.chevron.up"))
    
    // MARK: - Data
    private var displayOrders: [OrderModel] = []
    
    private var currentPage = 1
    private let pageSize = 10
    private var isLoading = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "我的订单"
        setupUI()
        loadInitialData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.delegate = self
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }
        
        ordersStack.axis = .vertical
        ordersStack.spacing = 15
        contentView.addSubview(ordersStack)
        
        ordersStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview().inset(15)
        }
        
        // Footer
        loadMoreLabel.text = "上滑加载更多"
        loadMoreLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        loadMoreLabel.font = .systemFont(ofSize: 12)
        arrowIcon.tintColor = UIColor.white.withAlphaComponent(0.6)
        
        footerView.addSubview(arrowIcon)
        footerView.addSubview(loadMoreLabel)
        
        arrowIcon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(10)
            make.width.height.equalTo(16)
        }
        loadMoreLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(arrowIcon.snp.bottom).offset(5)
        }
        contentView.addSubview(footerView)
        footerView.snp.makeConstraints { make in
            make.top.equalTo(ordersStack.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
            make.height.equalTo(60)
        }
    }
    
    // MARK: - Data Logic
    private func loadInitialData() {
        currentPage = 1
        displayOrders.removeAll()
        loadPageData()
    }
    
    private func loadPageData() {
        if isLoading { return }
        isLoading = true
        print("OrderListViewController: loadPageData() page \(currentPage)")
        
        OrderAPI.getOrders(pageNum: currentPage, pageSize: pageSize) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success(let pageResponse):
                let orders = pageResponse.data?.voList ?? []
                let uiOrders = orders.map { orderVO in
                    // 将 codeVOS (包含联通和唱吧码) 转为单个数组
                    var codes: [String] = []
                    orderVO.codeVOS?.forEach { codeObj in
                        if let cb = codeObj.changBaCode, !cb.isEmpty { codes.append("唱吧:\(cb)") }
                        if let lt = codeObj.lianTongCode, !lt.isEmpty { codes.append("联通:\(lt)") }
                    }
                    
                    return OrderModel(
                        id: "\(orderVO.orderId ?? 0)",
                        title: orderVO.setMenuName ?? "未知套餐",
                        orderNo: orderVO.orderCode ?? "未知订单号",
                        createTime: orderVO.createTime ?? "",
                        status: "已支付", // 默认显示已支付
                        activationCodes: codes
                    )
                }
                
                if self.currentPage == 1 {
                    self.displayOrders = uiOrders
                    self.ordersStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
                } else {
                    self.displayOrders.append(contentsOf: uiOrders)
                }
                
                for order in uiOrders {
                    let row = OrderRowView()
                    row.configure(with: order)
                    
                    row.onViewCodeTapped = { [weak self] in
                        self?.handleViewCode(for: order)
                    }
                    
                    self.ordersStack.addArrangedSubview(row)
                    // 由于内部使用 bgView 进行高度支撑，这里直接去除 height 约束以自适应
                }
                self.updateFooterPosition()
                
            case .failure(let error):
                print("获取订单失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateFooterPosition() {
        // Just empty method for old reference if any
        DispatchQueue.main.async {
            self.contentView.snp.remakeConstraints { make in
                make.edges.width.equalToSuperview()
                make.bottom.equalTo(self.ordersStack.snp.bottom).offset(30)
            }
        }
    }
    
    // MARK: - Actions
    private func handleViewCode(for order: OrderModel) {
        let codeVC = ActivationCodeViewController()
        codeVC.order = order
        navigationController?.pushViewController(codeVC, animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension OrderListViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        // 滑动到底部触发加载更多
        if offsetY > contentHeight - height + 20 {
            // 如果当前展示数量是 pageSize 的整数倍，说明可能还有下一页
            if !isLoading && displayOrders.count > 0 && displayOrders.count % pageSize == 0 {
                currentPage += 1
                loadPageData()
            }
        }
    }
}
