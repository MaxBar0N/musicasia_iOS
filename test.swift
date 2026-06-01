import Foundation
let emptyData = Optional<Any>.none as? String?
if emptyData != nil {
    print("Cast succeeded")
} else {
    print("Cast failed")
}
