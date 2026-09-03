import Foundation

/// 全局服务端配置：统一管理域名与基础 URL，避免在多处硬编码
enum APIConfig {
    /// API 基础地址（RuoYi 框架的 /prod-api 上下文路径）
    static let baseURL = "https://www.musicasia.cn/prod-api"

    /// 服务端主机名（用于 SSL 证书校验豁免）
    static let host = "www.musicasia.cn"

    /// 网页 / 静态资源域名（图片、协议页等）
    static let webBaseURL = "https://www.musicasia.cn"

    /// 微信支付 Referer 校验值（带尾斜杠）
    static let payReferer = webBaseURL + "/"

    /// 微信支付回调重定向 scheme
    static let payRedirectScheme = "www.musicasia.cn://"

    /// 用户服务协议页
    static let agreementURL = webBaseURL + "/agreement"

    /// 隐私协议页
    static let privacyURL = webBaseURL + "/privacy"
}
