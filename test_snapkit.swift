import UIKit
import SnapKit
class TestView: UIView {
    func test() {
        let v = UIView()
        addSubview(v)
        v.snp.makeConstraints { make in
            make.height.equalTo(100)
        }
    }
}
