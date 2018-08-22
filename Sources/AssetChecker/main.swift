import Foundation
import AssetCheckerCore

let arguments = CommandLine.arguments

print("⚠️ arguments: \(arguments)")

var assetWhiteList: [String] = []

if arguments.count < 4 {
    print(":: error: 参数: [源码路径] [Image.xcassets] [Asset白名单数组]")
    exit(1)
}

let assetWhiteListString = arguments[3]

let sourcePath = arguments[1]
let assetCatalogPath = arguments[2]

guard FileManager.default.fileExists(atPath: sourcePath) else {
    print(":: error: 请检查第一个参数：要检查的源代码路径是否存在！")
    exit(1)
}

guard FileManager.default.fileExists(atPath: assetCatalogPath) else {
    print(":: error: 请检查第二个参数：Images.xcassets路径是否存在！")
    exit(1)
}

guard let data = assetWhiteListString.data(using: .utf8), let whiteList = try JSONSerialization.jsonObject(with: data, options: []) as? [String] else {
    print(":: error: assetWhiteList参数必须为String数组!")
    exit(1)
}
assetWhiteList = whiteList

 let checker = AssetChecker(sourcePath: sourcePath, assetCatalogPath: assetCatalogPath, assetWhiteList: assetWhiteList)
 checker.check()
