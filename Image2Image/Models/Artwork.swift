import Foundation
import CoreGraphics

struct Artwork: Codable, Identifiable {
    let id: String
    let imageUrl: String
    var imagePath: String?
    let prompt: String
    let style: ArtStyle
    let aspectRatio: AspectRatio
    var isFavorite: Bool
    let createdAt: Date
    let userId: String
}

enum ArtStyle: String, Codable, CaseIterable {
    case realistic = "写实"
    case oilPainting = "油画"
    case anime = "动漫"
    case cyberpunk = "赛博朋克"
    case watercolor = "水彩"
    case sketch = "素描"
    case cartoon = "卡通"
    case abstract = "抽象"
    case fantasy = "奇幻"
    case minimalism = "极简"
    
    var apiValue: String {
        switch self {
        case .realistic: return "realistic"
        case .oilPainting: return "oil_painting"
        case .anime: return "anime"
        case .cyberpunk: return "cyberpunk"
        case .watercolor: return "watercolor"
        case .sketch: return "sketch"
        case .cartoon: return "cartoon"
        case .abstract: return "abstract"
        case .fantasy: return "fantasy"
        case .minimalism: return "minimalism"
        }
    }
    
    static func fromApiValue(_ value: String) -> ArtStyle {
        switch value {
        case "realistic": return .realistic
        case "oil_painting": return .oilPainting
        case "anime": return .anime
        case "cyberpunk": return .cyberpunk
        case "watercolor": return .watercolor
        case "sketch": return .sketch
        case "cartoon": return .cartoon
        case "abstract": return .abstract
        case "fantasy": return .fantasy
        case "minimalism": return .minimalism
        default: return .realistic
        }
    }
    
    var icon: String {
        switch self {
        case .realistic: return "🎨"
        case .oilPainting: return "🖼️"
        case .anime: return "✨"
        case .cyberpunk: return "🌃"
        case .watercolor: return "💧"
        case .sketch: return "✏️"
        case .cartoon: return "🎭"
        case .abstract: return "🔷"
        case .fantasy: return "🐉"
        case .minimalism: return "⬜"
        }
    }
}

enum ImageStyle: String, Codable, CaseIterable {
    case manhua = "漫画"
    case yuanqi = "元气"
    case medieval = "中世纪"
    case watercolor = "水彩"
}

enum ImageModel: String, Codable, CaseIterable {
    case standard = "image-01"
    case enhanced = "image-01-live"
    
    var displayName: String {
        switch self {
        case .standard: return "标准版"
        case .enhanced: return "增强版"
        }
    }
    
    var apiValue: String {
        return rawValue
    }
    
    static func fromApiValue(_ value: String) -> ImageModel {
        switch value {
        case "image-01-live": return .enhanced
        default: return .standard
        }
    }
}

enum AspectRatio: String, Codable, CaseIterable {
    case square = "1:1"
    case landscape43 = "4:3"
    case landscape169 = "16:9"
    case portrait916 = "9:16"
    
    var apiValue: String {
        switch self {
        case .square: return "1:1"
        case .landscape43: return "4:3"
        case .landscape169: return "16:9"
        case .portrait916: return "9:16"
        }
    }
    
    static func fromApiValue(_ value: String) -> AspectRatio {
        switch value {
        case "1:1": return .square
        case "4:3": return .landscape43
        case "16:9": return .landscape169
        case "9:16": return .portrait916
        default: return .square
        }
    }
    
    var value: CGSize {
        switch self {
        case .square: return CGSize(width: 1, height: 1)
        case .landscape43: return CGSize(width: 4, height: 3)
        case .landscape169: return CGSize(width: 16, height: 9)
        case .portrait916: return CGSize(width: 9, height: 16)
        }
    }
    
    var displayName: String {
        switch self {
        case .square: return "正方形"
        case .landscape43: return "横版"
        case .landscape169: return "宽屏"
        case .portrait916: return "竖版"
        }
    }
}