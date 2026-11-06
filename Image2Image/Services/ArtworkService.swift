import Foundation
import Combine
import UIKit

protocol ArtworkServiceProtocol {
    func getArtworks(userId: String) -> AnyPublisher<[Artwork], Error>
    func getArtwork(id: String) -> AnyPublisher<Artwork, Error>
    func createArtwork(artwork: Artwork) -> AnyPublisher<Artwork, Error>
    func updateArtwork(id: String, artwork: Artwork) -> AnyPublisher<Artwork, Error>
    func deleteArtwork(id: String) -> AnyPublisher<Void, Error>
    func toggleFavorite(id: String, userId: String) -> AnyPublisher<Artwork, Error>
    func saveImageLocally(_ image: UIImage, artworkId: String) -> String?
    func loadImageLocally(imagePath: String) -> UIImage?
}

class ArtworkService: ArtworkServiceProtocol {
    static let shared = ArtworkService()

    private let userDefaults = UserDefaults.standard
    private let artworksKey = "Image2Image_Artworks"
    private let fileManager = FileManager.default

    private init() {}

    private var imagesDirectory: URL {
        let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("ArtworkImages", isDirectory: true)
    }

    private func ensureImagesDirectory() {
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            try? fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Public API

    func saveImageLocally(_ image: UIImage, artworkId: String) -> String? {
        ensureImagesDirectory()

        guard let data = image.pngData() else { return nil }
        let fileName = "\(artworkId).png"
        let filePath = imagesDirectory.appendingPathComponent(fileName).path

        do {
            try data.write(to: URL(fileURLWithPath: filePath))
            return filePath
        } catch {
            print("[ArtworkService] 保存图片失败: \(error)")
            return nil
        }
    }

    func loadImageLocally(imagePath: String) -> UIImage? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: imagePath)) else { return nil }
        return UIImage(data: data)
    }

    func deleteImageLocally(imagePath: String) {
        try? fileManager.removeItem(atPath: imagePath)
    }

    // MARK: - ArtworkServiceProtocol

    func getArtworks(userId: String) -> AnyPublisher<[Artwork], Error> {
        return Future { promise in
            DispatchQueue.global().async {
                let artworks = self.loadAllArtworks().filter { $0.userId == userId }
                promise(.success(artworks))
            }
        }.eraseToAnyPublisher()
    }

    func getArtwork(id: String) -> AnyPublisher<Artwork, Error> {
        return Future { promise in
            DispatchQueue.global().async {
                let allArtworks = self.loadAllArtworks()
                if let artwork = allArtworks.first(where: { $0.id == id }) {
                    promise(.success(artwork))
                } else {
                    promise(.failure(NSError(domain: "ArtworkService", code: -1, userInfo: [NSLocalizedDescriptionKey: "作品不存在"])))
                }
            }
        }.eraseToAnyPublisher()
    }

    func createArtwork(artwork: Artwork) -> AnyPublisher<Artwork, Error> {
        return Future { promise in
            DispatchQueue.global().async {
                var allArtworks = self.loadAllArtworks()
                allArtworks.insert(artwork, at: 0)
                self.saveArtworks(allArtworks)

                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .artworkDidChange, object: nil)
                }

                promise(.success(artwork))
            }
        }.eraseToAnyPublisher()
    }

    func updateArtwork(id: String, artwork: Artwork) -> AnyPublisher<Artwork, Error> {
        return Future { promise in
            DispatchQueue.global().async {
                var allArtworks = self.loadAllArtworks()
                if let index = allArtworks.firstIndex(where: { $0.id == id }) {
                    allArtworks[index] = artwork
                    self.saveArtworks(allArtworks)
                    promise(.success(artwork))
                } else {
                    promise(.failure(NSError(domain: "ArtworkService", code: -1, userInfo: [NSLocalizedDescriptionKey: "作品不存在"])))
                }
            }
        }.eraseToAnyPublisher()
    }

    func deleteArtwork(id: String) -> AnyPublisher<Void, Error> {
        return Future { promise in
            DispatchQueue.global().async {
                var allArtworks = self.loadAllArtworks()
                if let artwork = allArtworks.first(where: { $0.id == id }) {
                    if let imagePath = artwork.imagePath {
                        self.deleteImageLocally(imagePath: imagePath)
                    }
                }
                allArtworks.removeAll { $0.id == id }
                self.saveArtworks(allArtworks)
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    func toggleFavorite(id: String, userId: String) -> AnyPublisher<Artwork, Error> {
        return Future { promise in
            DispatchQueue.global().async {
                var allArtworks = self.loadAllArtworks()
                if let index = allArtworks.firstIndex(where: { $0.id == id }) {
                    allArtworks[index].isFavorite.toggle()
                    self.saveArtworks(allArtworks)
                    promise(.success(allArtworks[index]))
                } else {
                    promise(.failure(NSError(domain: "ArtworkService", code: -1, userInfo: [NSLocalizedDescriptionKey: "作品不存在"])))
                }
            }
        }.eraseToAnyPublisher()
    }

    // MARK: - Persistence

    private func loadAllArtworks() -> [Artwork] {
        guard let data = userDefaults.data(forKey: artworksKey) else { return [] }
        return (try? JSONDecoder().decode([Artwork].self, from: data)) ?? []
    }

    private func saveArtworks(_ artworks: [Artwork]) {
        if let data = try? JSONEncoder().encode(artworks) {
            userDefaults.set(data, forKey: artworksKey)
        }
    }
}
