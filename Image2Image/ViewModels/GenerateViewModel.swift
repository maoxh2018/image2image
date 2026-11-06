import Foundation
import Combine
import UIKit

class GenerateViewModel: ObservableObject {
    @Published var status: GenerationStatus = .pending
    @Published var progress: Int = 0
    @Published var imageUrl: String = ""
    @Published var errorMessage: String = ""
    @Published var showSaveSuccess: Bool = false
    
    private let imageGenerationService: ImageGenerationServiceProtocol
    private let artworkService: ArtworkServiceProtocol
    private let authService: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        imageGenerationService: ImageGenerationServiceProtocol = ImageGenerationService(),
        artworkService: ArtworkServiceProtocol = ArtworkService.shared,
        authService: AuthServiceProtocol = AuthService()
    ) {
        self.imageGenerationService = imageGenerationService
        self.artworkService = artworkService
        self.authService = authService
    }
    
    func startGeneration(request: GenerationRequest) {
        status = .generating
        progress = 0
        imageUrl = ""
        errorMessage = ""
        
        imageGenerationService.generateImage(request: request, filePath: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.status = .failed
                    self?.errorMessage = error.localizedDescription
                case .finished:
                    break
                }
            } receiveValue: { [weak self] result in
                self?.status = .completed
                self?.progress = 100
                self?.imageUrl = result.imageUrl
                
                if !result.imageUrl.isEmpty {
                    self?.saveArtwork(result: result, request: request)
                }
            }
            .store(in: &cancellables)
    }
    
    func regenerate(request: GenerationRequest) {
        startGeneration(request: request)
    }
    
    func saveToGallery() {
        guard let url = URL(string: imageUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else { return }
            
            DispatchQueue.main.async {
                if let image = UIImage(data: data) {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    self?.showSaveSuccess = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.showSaveSuccess = false
                    }
                }
            }
        }.resume()
    }
    
    private func saveArtwork(result: GenerationResult, request: GenerationRequest) {
        let userId = authService.getUser()?.id ?? "guest"

        let artworkId = result.id ?? UUID().uuidString
        let remoteUrl = result.imageUrl

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
                style: ArtStyle.realistic,
                aspectRatio: AspectRatio.square,
                isFavorite: false,
                createdAt: Date(),
                userId: userId
            )

            artworkService.createArtwork(artwork: artwork)
                .sink { _ in } receiveValue: { _ in }
                .store(in: &cancellables)
        }
    }
}