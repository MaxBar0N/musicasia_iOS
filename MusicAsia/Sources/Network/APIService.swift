import Foundation
import Alamofire

/// 所有后端接口的定义
struct APIService {
    
    struct Auth {
        static let login = "/phone/login"
        static let register = "/phone/register"
        static let sendCodeLogin = "/sendCodeLogin"
        static let sendCodeRegister = "/sendCodeRegister"
        static let getInfo = "/getInfo"
        static let getArea = "/phone/getAreaBySalesmanCode"
        static let logout = "/phone/logout"
    }
    
    struct Home {
        static let index = "/phone/index"
    }
    
    struct Collection {
        static let page = "/music/collection/page"
    }
    
    struct Song {
        static let guessLike = "/phone/songs/guessLike"
        static let pageCollection = "/phone/songs/pageCollection"
        static let pageMusic = "/phone/songs/pageMusic"
        static let collect = "/phone/songs/collect"
        static let disCollect = "/phone/songs/disCollect"
        static let getSongUrl = "/phone/getSongUrl"
        static let getCollectUnDownload = "/phone/getCollectUnDownload" // 新增: 获取未下载
        static let setCollectDownloaded = "/phone/setCollectDownloaded" // 新增: 同步已下载
    }
    
    struct User {
        static let me = "/phone/me"
        static let bindingRechargeCode = "/phone/me/binding"
        static let changePassword = "/phone/me/changePass"
        static let collectPage = "/user/collect/page"
        
        static let bluetoothList = "/phone/user/bluetooth/list"
        static let checkBluetooth = "/phone/user/bluetooth/checkBluetooth"
        
        static let deviceList = "/phone/user/device/list"
        static let bindingDevice = "/phone/user/device/binding"
        static let checkUserEndTime = "/phone/checkUserEndTime" // 新增: 判断用户是否过期
    }
    
    struct Order {
        static let menuList = "/order/menu/list"
        static let page = "/phone/order/page"
        static let payApp = "/phone/order/pay/app"
        static let checkPayment = "/phone/order/checkPayment"
    }
    
    struct System {
        static let dictData = "/system/dict/data/type"
    }
}
