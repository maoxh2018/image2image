import Foundation
import UIKit
import Combine

enum ImageGenerationError: Error, LocalizedError, CustomStringConvertible {
    case invalidURL
    case requestFailed(Error)
    case noData
    case responseParseFailed(Error)
    case imageDownloadFailed
    case imageConversionFailed
    case fileNotFound
    case fileReadFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 API 地址"
        case .requestFailed(let error):
            // 如果是我们自己包的 NSError，优先取其 localizedDescription
            if let nsError = error as NSError?, nsError.domain == "HTTP" || nsError.domain == "API" {
                return nsError.localizedDescription
            }
            return "网络请求失败: \(error.localizedDescription)"
        case .noData:
            return "服务器没有返回数据"
        case .responseParseFailed(let error):
            return "解析服务器响应失败: \(error.localizedDescription)"
        case .imageDownloadFailed:
            return "图片下载失败"
        case .imageConversionFailed:
            return "图片格式转换失败"
        case .fileNotFound:
            return "找不到本地图片文件"
        case .fileReadFailed(let error):
            return "读取本地图片失败: \(error.localizedDescription)"
        }
    }

    var description: String { errorDescription ?? String(describing: self) }
}

protocol ImageGenerationServiceProtocol {
    func generateImage(request: GenerationRequest, filePath: String?) -> AnyPublisher<GenerationResult, Error>
    func downloadImage(urlString: String) async throws -> UIImage
}

struct ImageGenerationResponse: Codable {
    let id: String?
    let data: ImageData?
    let metadata: ResponseMetadata?
    let baseResp: BaseResp?

    struct ImageData: Codable {
        let imageUrls: [String]?

        enum CodingKeys: String, CodingKey {
            case imageUrls = "image_urls"
        }
    }

    struct ResponseMetadata: Codable {
        let failedCount: String?
        let successCount: String?

        enum CodingKeys: String, CodingKey {
            case failedCount = "failed_count"
            case successCount = "success_count"
        }
    }

    struct BaseResp: Codable {
        let statusCode: Int?
        let statusMsg: String?

        enum CodingKeys: String, CodingKey {
            case statusCode = "status_code"
            case statusMsg = "status_msg"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case data
        case metadata
        case baseResp = "base_resp"
    }

    var firstImageUrl: String? {
        if let imageUrls = data?.imageUrls, let firstUrl = imageUrls.first {
            return firstUrl
        }
        return nil
    }
}

class ImageGenerationService: ImageGenerationServiceProtocol {

    static let shared = ImageGenerationService()

    init() {}

    // MARK: - ImageGenerationServiceProtocol

    func generateImage(request: GenerationRequest, filePath: String?) -> AnyPublisher<GenerationResult, Error> {
        Future { promise in
            Task {
                do {
                    let result = try await self.generateImage(request: request, filePath: filePath)
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Private implementation

    private func generateImage(request: GenerationRequest, filePath: String? = nil) async throws -> GenerationResult {
        var parameters: [String: Any] = [
            "model": request.model,
            "prompt": request.prompt,
            "aspect_ratio": request.aspectRatio,
            "response_format": "url",
            "n": 1,
            "prompt_optimizer": true
        ]

        if let style = request.style {
            parameters["style"] = [
                "style_type": style.styleType,
                "style_weight": style.styleWeight
            ]
        }

        if let filePath = filePath {
            let base64Image = try localImgToBase64(filePath: filePath)
            parameters["subject_reference"] = [
                [
                    "type": "character",
                    "image_file": base64Image
                ]
            ]
        } else if !request.subjectReference.isEmpty {
            let subjectRefs = try request.subjectReference.map { ref -> [String: Any] in
                let imageFile: String
                if let refFilePath = ref.imageFilePath {
                    imageFile = try self.localImgToBase64(filePath: refFilePath)
                } else if let base64 = ref.imageFile {
                    imageFile = base64
                } else {
                    imageFile = ""
                }
                return [
                    "type": ref.type,
                    "image_file": imageFile
                ]
            }
            parameters["subject_reference"] = subjectRefs
        }

        let imageUrl = try await performRequest(parameters: parameters)

        return GenerationResult(
            id: UUID().uuidString,
            choices: [
                GenerationResult.Choice(
                    message: GenerationResult.Choice.Message(content: imageUrl)
                )
            ]
        )
    }

    private func performRequest(parameters: [String: Any]) async throws -> String {
        guard let url = URL(string: Config.minimaxAPIURL) else {
            throw ImageGenerationError.invalidURL
        }

        let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Config.minimaxAPIKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("[Debug] ImageGenerationService: HTTP状态码: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                var errorMessage = "请求失败（HTTP \(httpResponse.statusCode)）"
                if let responseString = String(data: data, encoding: .utf8) {
                    print("[Debug] ImageGenerationService: 错误响应: \(responseString)")
                    if let errorData = try? JSONSerialization.jsonObject(with: Data(responseString.utf8)) as? [String: Any] {
                        if let msg = errorData["message"] as? String {
                            errorMessage = msg
                        } else if let msg = errorData["error"] as? String {
                            errorMessage = msg
                        } else if let errorObj = errorData["error"] as? [String: Any], let msg = errorObj["message"] as? String {
                            errorMessage = msg
                        }
                        if let baseResp = errorData["base_resp"] as? [String: Any], let msg = baseResp["status_msg"] as? String {
                            errorMessage = msg
                        }
                    }
                }
                throw ImageGenerationError.requestFailed(
                    NSError(domain: "HTTP", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                )
            }
        }

        if let responseString = String(data: data, encoding: .utf8) {
            print("[Debug] ImageGenerationService: 原始响应: \(responseString)")
        }

        do {
            let response = try JSONDecoder().decode(ImageGenerationResponse.self, from: data)

            if let statusCode = response.baseResp?.statusCode, statusCode != 0 {
                let statusMsg = response.baseResp?.statusMsg ?? "未知错误"
                throw ImageGenerationError.requestFailed(
                    NSError(domain: "API", code: statusCode, userInfo: [NSLocalizedDescriptionKey: statusMsg])
                )
            }

            guard let imageUrl = response.firstImageUrl else {
                throw ImageGenerationError.responseParseFailed(
                    NSError(domain: "Parse", code: 0, userInfo: [NSLocalizedDescriptionKey: "No image URLs found in response"])
                )
            }
            return imageUrl
        } catch {
            throw ImageGenerationError.responseParseFailed(error)
        }
    }

    // MARK: - Public utilities

    func generateImage(prompt: String, filePath: String? = nil) async throws -> String {
        var parameters: [String: Any] = [
            "model": "image-01",
            "prompt": prompt,
            "aspect_ratio": "16:9",
            "response_format": "url",
            "n": 1,
            "prompt_optimizer": true
        ]

        if let filePath = filePath {
            let base64Image = try localImgToBase64(filePath: filePath)
            parameters["subject_reference"] = [
                [
                    "type": "character",
                    "image_file": base64Image
                ]
            ]
        }

        return try await performRequest(parameters: parameters)
    }

    func downloadImage(urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw ImageGenerationError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        guard let image = UIImage(data: data) else {
            throw ImageGenerationError.imageConversionFailed
        }

        return image
    }

    func localImgToBase64(filePath: String) throws -> String {
        let fileURL = URL(fileURLWithPath: filePath)

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw ImageGenerationError.fileReadFailed(error)
        }

        let ext = fileURL.pathExtension.lowercased()
        let mimeType: String
        switch ext {
        case "png":
            mimeType = "image/png"
        case "jpg", "jpeg":
            mimeType = "image/jpeg"
        case "webp":
            mimeType = "image/webp"
        case "gif":
            mimeType = "image/gif"
        default:
            mimeType = "image/jpeg"
        }

        let b64Str = data.base64EncodedString()
        return "data:\(mimeType);base64,\(b64Str)"
    }
}
