import UIKit

public extension UIImageView {
    var kf: KingfisherWrapper<UIImageView> { KingfisherWrapper(self) }
}

public struct KingfisherWrapper<Base: UIImageView> {
    let base: Base
    public init(_ base: Base) { self.base = base }
    
    public func setImage(with url: URL?) {
        guard let url = url else {
            DispatchQueue.main.async {
                self.base.image = nil
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak base] data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                return
            }
            DispatchQueue.main.async {
                base?.image = image
            }
        }.resume()
    }
}