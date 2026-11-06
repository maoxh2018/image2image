import Foundation

struct GenerationRequest: Codable {
    let model: String
    let prompt: String
    let aspectRatio: String
    let subjectReference: [SubjectReference]
    let style: StyleOption?
    
    init(model: String, prompt: String, aspectRatio: String, subjectReference: [SubjectReference], style: StyleOption? = nil) {
        self.model = model
        self.prompt = prompt
        self.aspectRatio = aspectRatio
        self.subjectReference = subjectReference
        self.style = style
    }
    
    enum CodingKeys: String, CodingKey {
        case model
        case prompt
        case aspectRatio = "aspect_ratio"
        case subjectReference = "subject_reference"
        case style
    }
}

struct StyleOption: Codable {
    let styleType: String
    let styleWeight: Double
    
    init(styleType: String, styleWeight: Double = 0.8) {
        self.styleType = styleType
        self.styleWeight = styleWeight
    }
    
    enum CodingKeys: String, CodingKey {
        case styleType = "style_type"
        case styleWeight = "style_weight"
    }
}

struct SubjectReference: Codable {
    let type: String
    let imageFile: String?
    let imageFilePath: String?
    
    init(type: String, imageFile: String? = nil, imageFilePath: String? = nil) {
        self.type = type
        self.imageFile = imageFile
        self.imageFilePath = imageFilePath
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case imageFile = "image_file"
        case imageFilePath = "image_file_path"
    }
}

struct GenerationResult: Codable {
    let id: String?
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let content: String
        }
    }
    
    var imageUrl: String {
        return choices.first?.message.content ?? ""
    }
}

enum GenerationStatus {
    case pending
    case generating
    case completed
    case failed
}
