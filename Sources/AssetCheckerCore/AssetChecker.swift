import Foundation

public final class AssetChecker {
    let sourcePath: String
    let assetCatalogPath: String
    let assetWhiteList: [String]

    public init(sourcePath: String, assetCatalogPath: String, assetWhiteList: [String] = []) {
        self.sourcePath = sourcePath
        self.assetCatalogPath = assetCatalogPath
        self.assetWhiteList = assetWhiteList
    }

    // MARK: - End Of Configurable Section

    private func elementsInEnumerator(_ enumerator: FileManager.DirectoryEnumerator?) -> [String] {
        var elements = [String]()

        while let e = enumerator?.nextObject() as? String {
            elements.append(e)
        }
        return elements
    }

    // MARK: - List Assets

    private func listAssets() -> [String] {
        let extensionName = "imageset"
        let enumerator = FileManager.default.enumerator(atPath: assetCatalogPath)
        return elementsInEnumerator(enumerator)
            .filter { $0.hasSuffix(extensionName) } // Is Asset
            .map { $0.replacingOccurrences(of: ".\(extensionName)", with: "") } // Remove extension
            .map { $0.components(separatedBy: "/").last ?? $0 } // Remove folder path
    }

    // MARK: - List Used Assets in the codebase

    typealias AssetUsedInfo = (assetName: String, fileName: String, lineNumber: Int)

    private func listUsedAssetLiteralsIn(_ file: String) -> [AssetUsedInfo] {
        guard let content = try? String(contentsOfFile: file, encoding: .utf8) else { return [] }

        var localizedStrings = [AssetUsedInfo]()
        let namePattern = "([\\w-]+)"
        let patterns = [
            "#imageLiteral\\(resourceName: \"\(namePattern)\"\\)", // Image Literal
            "UIImage\\(named:\\s*\"\(namePattern)\"\\)", // Default UIImage call (Swift)
            "UIImage imageNamed:\\s*\\@\"\(namePattern)\"", // Default UIImage call
            "\\<image name=\"\(namePattern)\".*", // Storyboard resources
            "R.image.\(namePattern)\\(\\)" // R.swift support
        ]

        let group = DispatchGroup()
        for pattern in patterns {
            let queue = DispatchQueue(label: "", qos: .userInteractive, attributes: .concurrent)
            queue.async(group: group) {
                guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
                let range = NSRange(location: 0, length: content.count)
                regex.enumerateMatches(in: content, options: [], range: range, using: { result, _, _ in
                    if let result = result {
                        let value = (content as NSString).substring(with: result.range(at: 1))

                        var lineNumber = 0
                        let firstRange = result.range
                        if firstRange.location < content.count {
                            let subContent = (content as NSString).substring(with: NSRange(location: 0, length: firstRange.location))
                            let subContents = subContent.components(separatedBy: .newlines)
                            lineNumber = subContents.count
                        }

                        localizedStrings.append(AssetUsedInfo(assetName: value, fileName: file, lineNumber: lineNumber))
                    }
                })
            }
        }
        group.wait()

        return localizedStrings
    }

    private func listUsedAssetLiterals() -> [AssetUsedInfo] {
        let enumerator = FileManager.default.enumerator(atPath: sourcePath)
        print(sourcePath)

        let assetInfos = elementsInEnumerator(enumerator)
            .filter { $0.hasSuffix(".m") || $0.hasSuffix(".swift") || $0.hasSuffix(".xib") || $0.hasSuffix(".storyboard") } // Only Swift and Obj-C files
            .map { "\(sourcePath)/\($0)" }
            .flatMap(listUsedAssetLiteralsIn)
        return assetInfos
    }

    public func check() {
        let assets = Set(listAssets())
        let used = Set(listUsedAssetLiterals().compactMap { $0.assetName } + assetWhiteList)

        // Generate Warnings for Unused Assets
        let unused = assets.subtracting(used)
        unused.forEach { print("\(assetCatalogPath): warning: [Asset 未使用] \($0)") }
        if !unused.isEmpty {
            print(":: warning: 如果确定Asset已使用，请将其添加到白名单中")
        }

        // Generate Error for broken Assets
        let broken = listUsedAssetLiterals().filter { !assets.contains($0.assetName) }
        broken.forEach { print("\($0.fileName):\($0.lineNumber): error: [Asset 缺失] \($0.assetName)") }

        if !broken.isEmpty {
            exit(1)
        }
    }
}
