import Foundation

/// 网络环境定义
enum APIEnvironment {
    case testing
    case production
    
    var host: String {
        switch self {
        case .testing:
            return "iosapi.musicasia.cn"
        case .production:
            return "www.musicasia.cn"
        }
    }
}

/// 全局服务端配置：统一管理域名与基础 URL，避免在多处硬编码
enum APIConfig {
    /// 💡 当前环境配置，切换环境只需修改此处
    static let currentEnvironment: APIEnvironment = .production

    /// 服务端主机名（核心域名配置，根据当前环境自动获取）
    static var host: String { currentEnvironment.host }

    /// 网页 / 静态资源域名（图片、协议页等）
    static var webBaseURL: String { "https://\(host)" }

    /// API 基础地址（RuoYi 框架的 /prod-api 上下文路径）
    static var baseURL: String { "\(webBaseURL)/prod-api" }

    /// 微信支付 Referer 校验值（带尾斜杠）
    static var payReferer: String { "\(webBaseURL)/" }

    /// 微信支付回调重定向 scheme
    static var payRedirectScheme: String { "\(host)://" }

    /// 用户服务协议页
    static var agreementURL: String { "\(webBaseURL)/agreement" }

    /// 隐私协议页
    static var privacyURL: String { "\(webBaseURL)/privacy" }
}
