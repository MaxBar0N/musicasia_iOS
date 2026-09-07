import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)

        // 限制仅 iPhone 使用：iPad / Mac 上直接展示不支持提示
        if !DeviceSupport.isSupported {
            window.rootViewController = UnsupportedDeviceViewController()
            self.window = window
            window.makeKeyAndVisible()
            return
        }

        // 全局配置导航栏样式 (透明背景、白色文字、白色返回按钮)
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor = .white
        
        // 检查登录状态：判断 UserDefaults 中是否存在 token 或用户标识
        let isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        
        if isLoggedIn {
            // 已登录，直接进入首页
            window.rootViewController = MainTabBarController()
        } else {
            // 未登录，进入登录页
            let viewController = LoginViewController()
            let nav = UINavigationController(rootViewController: viewController)
            window.rootViewController = nav
        }
        
        self.window = window
        window.makeKeyAndVisible()
    }
}
