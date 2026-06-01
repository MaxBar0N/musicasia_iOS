import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupViewControllers()
    }
    
    private func setupUI() {
        // 自定义 TabBar 样式以适配深色背景
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundImage = createGradientImage()
        
        let normalAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.white.withAlphaComponent(0.5)]
        let selectedAttrs: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor(hex: "#16E0BF")]
        
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttrs
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.5)
        
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttrs
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(hex: "#16E0BF")
        
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        tabBar.isTranslucent = true
    }
    
    private func createGradientImage() -> UIImage {
        let height: CGFloat = 120 // 足够高以覆盖 tab bar 和 bottom safe area
        let bounds = CGRect(x: 0, y: 0, width: 1, height: height)
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = [
            UIColor(hex: "#091227").withAlphaComponent(0.0).cgColor,
            UIColor(hex: "#091227").withAlphaComponent(0.8).cgColor,
            UIColor(hex: "#091227").withAlphaComponent(1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        if let context = UIGraphicsGetCurrentContext() {
            gradientLayer.render(in: context)
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image?.resizableImage(withCapInsets: .zero, resizingMode: .stretch) ?? UIImage()
    }
    
    private func setupViewControllers() {
        let homeVC = HomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(title: "首页", image: UIImage(systemName: "music.note"), tag: 0)
        
        let albumVC = AlbumViewController()
        let albumNav = UINavigationController(rootViewController: albumVC)
        albumNav.tabBarItem = UITabBarItem(title: "专辑", image: UIImage(systemName: "play.circle"), tag: 1)
        
        let songVC = SongViewController()
        let songNav = UINavigationController(rootViewController: songVC)
        songNav.tabBarItem = UITabBarItem(title: "歌曲", image: UIImage(systemName: "headphones"), tag: 2)
        
        let profileVC = ProfileViewController()
        let profileNav = UINavigationController(rootViewController: profileVC)
        profileNav.tabBarItem = UITabBarItem(title: "我的", image: UIImage(systemName: "person"), tag: 3)
        
        viewControllers = [homeNav, albumNav, songNav, profileNav]
    }
}
