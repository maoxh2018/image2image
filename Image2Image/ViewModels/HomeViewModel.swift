import Foundation
import Combine
import UIKit

class HomeViewModel: ObservableObject {
    @Published var prompt: String = ""
    @Published var selectedImage: UIImage?
    @Published var model: ImageModel = .standard
    @Published var aspectRatio: AspectRatio = .landscape169
    @Published var style: ImageStyle = .manhua
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?
    
    private let authService: AuthServiceProtocol
    private let artworkService: ArtworkServiceProtocol
    private let imageGenerationService: ImageGenerationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        authService: AuthServiceProtocol = AuthService(),
        artworkService: ArtworkServiceProtocol = ArtworkService.shared,
        imageGenerationService: ImageGenerationServiceProtocol = ImageGenerationService()
    ) {
        self.authService = authService
        self.artworkService = artworkService
        self.imageGenerationService = imageGenerationService
    }
    
    var canGenerate: Bool {
        selectedImage != nil && !prompt.trimmingCharacters(in: .whitespaces).isEmpty && !isGenerating
    }
    
    func generateImage(completion: @escaping (GenerationRequest?, GenerationResult?) -> Void) {
        guard canGenerate, let image = selectedImage else {
            completion(nil, nil)
            return
        }
        
        isGenerating = true
        errorMessage = nil
        
        let imageFilePath: String? = saveImageToTempFile(image)
        
        let request = GenerationRequest(
            model: model.apiValue,
            prompt: prompt.trimmingCharacters(in: .whitespaces),
            aspectRatio: aspectRatio.apiValue,
            subjectReference: [SubjectReference(type: "character")],
            style: model == .enhanced ? StyleOption(styleType: style.rawValue) : nil
        )
        
        imageGenerationService.generateImage(request: request, filePath: imageFilePath)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completionResult in
                self?.isGenerating = false
                switch completionResult {
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion(request, nil)
                case .finished:
                    break
                }
            } receiveValue: { [weak self] result in
                if !result.imageUrl.isEmpty {
                    self?.saveArtwork(result: result, request: request)
                }
                completion(request, result)
            }
            .store(in: &cancellables)
    }
    
    private func saveImageToTempFile(_ image: UIImage) -> String? {
        let scaledImage = resizeImageToFrameSize(image)
        guard let data = scaledImage.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".jpg"
        let filePath = tempDir.appendingPathComponent(fileName)
        
        do {
            try data.write(to: filePath)
            return filePath.path
        } catch {
            return nil
        }
    }
    
    private func imageToBase64(image: UIImage) -> String {
        let resizedImage = resizeImageToFrameSize(image)
        if let jpegData = resizedImage.jpegData(compressionQuality: 0.8) {
            let base64String = jpegData.base64EncodedString()
            return "data:image/jpeg;base64,\(base64String)"
        }
        return ""
    }
    
    /// 将图片缩放到最长边不超过 maxDimension，保持宽高比，保证 API 有足够分辨率提取图像特征
    private func resizeImageToFrameSize(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1024
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }

        let scaleRatio = maxDimension / maxSide
        let targetSize = CGSize(width: size.width * scaleRatio, height: size.height * scaleRatio)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    private func saveArtwork(result: GenerationResult, request: GenerationRequest) {
        let userId = authService.getUser()?.id ?? "guest"

        let artworkId = result.id ?? UUID().uuidString
        let remoteUrl = result.imageUrl
        let aspectRatio = AspectRatio.fromApiValue(request.aspectRatio)
        let artStyle = Self.mapImageStyleToArtStyle(styleType: request.style?.styleType)

        Task { @MainActor in
            var localPath: String? = nil

            if let image = try? await imageGenerationService.downloadImage(urlString: remoteUrl) {
                localPath = artworkService.saveImageLocally(image, artworkId: artworkId)
            }

            let artwork = Artwork(
                id: artworkId,
                imageUrl: remoteUrl,
                imagePath: localPath,
                prompt: request.prompt,
                style: artStyle,
                aspectRatio: aspectRatio,
                isFavorite: false,
                createdAt: Date(),
                userId: userId
            )

            artworkService.createArtwork(artwork: artwork)
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)
        }
    }
    
    func clearImage() {
        selectedImage = nil
    }

    /// 将 API 的 style_type 值映射到 ArtStyle 枚举
    private static func mapImageStyleToArtStyle(styleType: String?) -> ArtStyle {
        guard let styleType = styleType else { return .realistic }
        switch ImageStyle(rawValue: styleType) ?? .manhua {
        case .manhua:    return .cartoon
        case .yuanqi:    return .anime
        case .medieval:  return .fantasy
        case .watercolor: return .watercolor
        }
    }
}