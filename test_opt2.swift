import Foundation

func test<T>(_ type: T.Type) {
    if let emptyData = Optional<Any>.none as? T {
        print("Success for \(type), value is \(String(describing: emptyData))")
    } else {
        print("Failed for \(type)")
    }
}

test(String?.self)
