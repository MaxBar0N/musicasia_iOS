import UIKit
public struct ConstraintMaker {
    public var edges: ConstraintMaker { return self }
    public var width: ConstraintMaker { return self }
    public var height: ConstraintMaker { return self }
    public var top: ConstraintMaker { return self }
    public var bottom: ConstraintMaker { return self }
    public var left: ConstraintMaker { return self }
    public var right: ConstraintMaker { return self }
    public var centerX: ConstraintMaker { return self }
    public var center: ConstraintMaker { return self }
    public var centerY: ConstraintMaker { return self }
    public var leading: ConstraintMaker { return self }
    public var trailing: ConstraintMaker { return self }
    public func equalTo(_ other: Any) -> ConstraintMaker { return self }
    public func offset(_ amount: CGFloat) -> ConstraintMaker { return self }
    public func multipliedBy(_ amount: CGFloat) -> ConstraintMaker { return self }
    public func inset(_ amount: CGFloat) -> ConstraintMaker { return self }
    public func equalToSuperview() -> ConstraintMaker { return self }
    public func lessThanOrEqualToSuperview() -> ConstraintMaker { return self }
    public func lessThanOrEqualTo(_ other: Any) -> ConstraintMaker { return self }
    public func edgesToSuperview() -> ConstraintMaker { return self }
}
public extension UIView {
    var snp: ConstraintViewDSL { ConstraintViewDSL() }
}
public struct ConstraintViewDSL {
    public var top: Any { return self }
    public var bottom: Any { return self }
    public var left: Any { return self }
    public var right: Any { return self }
    public var centerX: Any { return self }
    public var centerY: Any { return self }
    public func makeConstraints(_ closure: (ConstraintMaker) -> Void) {}
    public func remakeConstraints(_ closure: (ConstraintMaker) -> Void) {}
    public func updateConstraints(_ closure: (ConstraintMaker) -> Void) {}
}