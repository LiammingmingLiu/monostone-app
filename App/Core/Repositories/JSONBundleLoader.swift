import Foundation

/// 从 app bundle 里加载 JSON 资源文件并 decode 成 `Codable` 类型的小 helper.
///
/// 所有 `Bundle*Repository` 实现都通过这个 helper 加载 mock 数据,
/// 这样 JSON 读取 + decoding 的错误处理只写一处.
///
/// 使用方式:
/// ```swift
/// let feed: HomeFeed = try await JSONBundleLoader.load("home")
/// ```
///
/// 一旦后端上线, 对应 Repository 换掉实现用 URLSession 就行, 接口不变.
enum JSONBundleLoader {
    enum LoadError: Error, LocalizedError {
        case resourceNotFound(String)
        case decodingFailed(String, underlying: Error)

        var errorDescription: String? {
            switch self {
            case .resourceNotFound(let name):
                "Mock JSON 资源 \"\(name).json\" 未在 bundle 中找到"
            case .decodingFailed(let name, let err):
                "Mock JSON \"\(name).json\" 解码失败: \(err.localizedDescription)"
            }
        }
    }

    /// 从 main bundle 里读取 `<name>.json` 并 decode 成 `T`.
    static func load<T: Decodable>(
        _ name: String,
        as type: T.Type = T.self,
        bundle: Bundle = .main,
        decoder: JSONDecoder = defaultDecoder()
    ) async throws -> T {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw LoadError.resourceNotFound(name)
        }
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(T.self, from: data)
        } catch {
            throw LoadError.decodingFailed(name, underlying: error)
        }
    }

    /// 默认 decoder: snake_case → camelCase. 和后端 Python / Node 输出对齐.
    static func defaultDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
