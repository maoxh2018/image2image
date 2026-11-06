import Foundation

nonisolated struct User: Codable, Identifiable {
    let id: String
    let phone: String
    let nickname: String
    let avatar: String?
    let createdAt: Date
    let lastLoginAt: Date
    
    var maskedPhone: String {
        guard phone.count >= 11 else { return phone }
        let start = phone.prefix(3)
        let end = phone.suffix(4)
        return "\(start)****\(end)"
    }
}