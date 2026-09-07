import UIKit

/// 设备支持检测：本应用仅面向 iPhone
enum DeviceSupport {
    /// 当前设备是否受支持（仅 iPhone）
    static var isSupported: Bool {
        // iPad（含 iPhone 应用以兼容模式在 iPad 上运行）
        if UIDevice.current.userInterfaceIdiom == .pad {
            return false
        }
        // 运行在 Apple Silicon Mac 上的 iOS 应用
        if ProcessInfo.processInfo.isiOSAppOnMac {
            return false
        }
        // Mac Catalyst（兜底，本项目未启用）
        if ProcessInfo.processInfo.isMacCatalystApp {
            return false
        }
        return true
    }
}
