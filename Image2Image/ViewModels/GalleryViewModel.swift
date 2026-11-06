import Foundation
import Combine

class GalleryViewModel: ObservableObject {
    @Published var artworks: [Artwork] = []
    @Published var searchText: String = ""
    @Published var selectedStyle: ArtStyle?
    @Published var isLoading: Bool = false
    @Published var showFavoritesOnly: Bool = false
    
    private let authService: AuthServiceProtocol
    private let artworkService: ArtworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        authService: AuthServiceProtocol = AuthService(),
        artworkService: ArtworkServiceProtocol = ArtworkService.shared
    ) {
        self.authService = authService
        self.artworkService = artworkService
        loadArtworks()
        setupNotifications()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .artworkDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadArtworks()
        }
    }
    
    var filteredArtworks: [Artwork] {
        var result = artworks

        if showFavoritesOnly {
            result = result.filter { $0.isFavorite }
        }

        if let style = selectedStyle {
            result = result.filter { $0.style == style }
        }

        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            result = result.filter { $0.prompt.lowercased().contains(searchLower) }
        }

        return result
    }
    
    func loadArtworks() {
        isLoading = true
        let userId = authService.getUser()?.id ?? "guest"
        
        artworkService.getArtworks(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
            } receiveValue: { [weak self] artworks in
                self?.artworks = artworks
            }
            .store(in: &cancellables)
    }

    func reloadArtworks() {
        loadArtworks()
    }
    
    func toggleFavorite(id: String) {
        let userId = authService.getUser()?.id ?? "guest"
        
        artworkService.toggleFavorite(id: id, userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] updatedArtwork in
                if let index = self?.artworks.firstIndex(where: { $0.id == updatedArtwork.id }) {
                    self?.artworks[index] = updatedArtwork
                }
            }
            .store(in: &cancellables)
    }
    
    func deleteArtwork(id: String) {
        artworkService.deleteArtwork(id: id)
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] _ in
                self?.artworks.removeAll { $0.id == id }
            }
            .store(in: &cancellables)
    }
}