import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var artworkCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var isSubscribed: Bool = false
    @Published var remainingCount: Int = 0
    @Published var isLoggedIn: Bool = false

    private let authService: AuthService
    private let artworkService: ArtworkServiceProtocol
    private let subscriptionManager = SubscriptionManager.shared
    private var cancellables = Set<AnyCancellable>()

    init(
        authService: AuthService = .shared,
        artworkService: ArtworkServiceProtocol = ArtworkService.shared
    ) {
        self.authService = authService
        self.artworkService = artworkService
        setupBindings()
        loadUser()
        syncSubscriptionStatus()
    }

    private func setupBindings() {
        subscriptionManager.setupStoreKitListener()

        subscriptionManager.$isSubscribed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.isSubscribed = value
            }
            .store(in: &cancellables)

        subscriptionManager.$remainingCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.remainingCount = value
            }
            .store(in: &cancellables)

        authService.$isLoggedIn
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadUser()
            }
            .store(in: &cancellables)

        authService.$phoneNumber
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadUser()
            }
            .store(in: &cancellables)
    }

    func loadUser() {
        user = authService.getUser()
        isLoggedIn = authService.isLoggedIn
        loadArtworkCount()
    }

    func loadArtworkCount() {
        isLoading = true
        let userId = authService.getUser()?.id ?? "guest"

        artworkService.getArtworks(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
            } receiveValue: { [weak self] artworks in
                self?.artworkCount = artworks.count
            }
            .store(in: &cancellables)
    }

    func logout() {
        authService.logout()
    }

    // MARK: - Subscription

    func syncSubscriptionStatus() {
        isSubscribed = subscriptionManager.isSubscribed
        remainingCount = subscriptionManager.remainingCount
    }
}
