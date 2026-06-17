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
        loadURL()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupUI() {
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .clear
        webView.isOpaque = false // 适配可能存在的深色背景
        
        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func loadURL() {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}
