import UIKit
import WebKit
import SnapKit

class AgreementViewController: BaseViewController {
    
    var agreementTitle: String = "协议"
    var urlString: String = ""
    
    private var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = agreementTitle
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupUI() {
        // 显示加载指示器，避免 WebView 初始化阻塞页面跳转动画
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = .white
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let config = WKWebViewConfiguration()
            self.webView = WKWebView(frame: .zero, configuration: config)
            self.webView.backgroundColor = .clear
            self.webView.isOpaque = false // 适配可能存在的深色背景
            
            self.view.addSubview(self.webView)
            self.webView.snp.makeConstraints { make in
                make.edges.equalTo(self.view.safeAreaLayoutGuide)
            }
            
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
            
            self.loadURL()
        }
    }
    
    private func loadURL() {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}
