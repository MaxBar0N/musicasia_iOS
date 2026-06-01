import Foundation

func test<T>(_ type: T.Type) {
    if let emptyData = Optional<Any>.none as? T {
        print("Success for \(type)")
    } else {
        print("Failed for \(type)")
    }
}

test(String?.self)
test(String.self)
