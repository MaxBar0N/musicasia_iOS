import Foundation

func test<T>(_ type: T.Type) {
    if let emptyType = T.self as? ExpressibleByNilLiteral.Type {
        let value = emptyType.init(nilLiteral: ()) as! T
        print("Success for \(type), value is \(String(describing: value))")
    } else {
        print("Failed for \(type)")
    }
}

test(String?.self)
test(String.self)
