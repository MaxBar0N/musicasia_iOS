import Foundation
import UIKit

class CommonAPI {
    
    // MARK: - 图片上传
    static func uploadImage(image: UIImage, completion: @escaping (Result<String, NetworkError>) -> Void) {
        NetworkManager.shared.uploadImage(image, endpoint: APIService.Common.upload, completion: completion)
    }
}
