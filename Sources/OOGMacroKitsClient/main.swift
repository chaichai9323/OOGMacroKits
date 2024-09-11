import Foundation
import TestMacro
import MoyaMacro

let a = 17
let b = 25

let (result, code) = #stringify(a + b)

print("The value \(result) was produced by the code \"\(code)\"")

let str = "https://www.abc.com/api"
if let u = #URL(str) {
    print("scheme: " + (u.scheme ?? ""))
    print("host: " + (u.host ?? ""))
    print("path: " + u.path)
}

let path = "http://www.abc.com" + "/og"
@MoyaConfig(
    baseURL: path,
    timeout: 15.0
)
enum API {
    
    @MoyaPath("oog104/detail/%d", "page")
    case detail(page: Int)
}

Task {
    do {
        let res = try await API.detail(page: 0).requestModel(String.self)
        print(res)
    } catch {
        print(error.localizedDescription)
    }
}
