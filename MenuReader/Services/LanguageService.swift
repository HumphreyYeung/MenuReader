//
//  LanguageService.swift
//  MenuReader
//
//  Created by Humphrey Yeung on 6/20/25.
//

import Foundation

/// 语言检测和翻译决策服务
@MainActor
class LanguageService {
    static let shared = LanguageService()
    
    private let storageService = StorageService.shared
    
    private init() {}
    
    /// 检测文本的主要语言
    func detectLanguage(from text: String) -> String {
        // 使用NSLinguisticTagger进行语言检测
        let tagger = NSLinguisticTagger(tagSchemes: [.language], options: 0)
        tagger.string = text
        
        let _ = NSRange(location: 0, length: text.utf16.count)
        let detectedLanguage = tagger.dominantLanguage
        
        // 映射检测结果到我们支持的语言代码
        guard let detected = detectedLanguage else {
            return "unknown"
        }
        
        // 标准化语言代码
        switch detected {
        case "zh-Hans", "zh-Hant", "zh":
            return "zh"
        case "en":
            return "en"
        case "ja":
            return "ja"
        case "ko":
            return "ko"
        case "fr":
            return "fr"
        case "de":
            return "de"
        case "it":
            return "it"
        case "es":
            return "es"
        default:
            return detected
        }
    }
    
    /// 判断是否需要翻译
    /// - Parameters:
    ///   - detectedLanguage: OCR检测到的语言
    ///   - targetLanguage: 用户设置的目标语言
    /// - Returns: 是否需要翻译
    func shouldTranslate(detectedLanguage: String, targetLanguage: String) -> Bool {
        // 标准化语言代码进行比较
        let normalizedDetected = normalizeLanguageCode(detectedLanguage)
        let normalizedTarget = normalizeLanguageCode(targetLanguage)
        
        print("🌍 [LanguageService] 语言比较:")
        print("   检测语言: \(detectedLanguage) -> \(normalizedDetected)")
        print("   目标语言: \(targetLanguage) -> \(normalizedTarget)")
        print("   需要翻译: \(normalizedDetected != normalizedTarget)")
        
        return normalizedDetected != normalizedTarget
    }
    
    /// 获取用户当前的目标语言设置
    func getUserTargetLanguage() -> String {
        let userProfile = storageService.loadUserProfile()
        return userProfile.targetLanguage
    }
    
    /// 标准化语言代码
    private func normalizeLanguageCode(_ code: String) -> String {
        let lowercased = code.lowercased()
        
        switch lowercased {
        case "zh", "zh-hans", "zh-hant", "chinese":
            return "zh"
        case "en", "english":
            return "en"
        case "ja", "japanese":
            return "ja"
        case "ko", "korean":
            return "ko"
        case "fr", "french":
            return "fr"
        case "de", "german":
            return "de"
        case "it", "italian":
            return "it"
        case "es", "spanish":
            return "es"
        default:
            return lowercased
        }
    }
    
    /// 从文本内容推断语言（作为备用方法）
    func inferLanguageFromContent(_ text: String) -> String {
        let chineseCharacterSet = CharacterSet(charactersIn: "\u{4e00}"..."\u{9fff}")
        let japaneseHiraganaSet = CharacterSet(charactersIn: "\u{3040}"..."\u{309f}")
        let japaneseKatakanaSet = CharacterSet(charactersIn: "\u{30a0}"..."\u{30ff}")
        let koreanSet = CharacterSet(charactersIn: "\u{ac00}"..."\u{d7af}")
        
        let textLength = text.count
        guard textLength > 0 else { return "unknown" }
        
        var chineseCount = 0
        var japaneseCount = 0
        var koreanCount = 0
        
        for char in text {
            let scalar = char.unicodeScalars.first!
            
            if chineseCharacterSet.contains(scalar) {
                chineseCount += 1
            } else if japaneseHiraganaSet.contains(scalar) || japaneseKatakanaSet.contains(scalar) {
                japaneseCount += 1
            } else if koreanSet.contains(scalar) {
                koreanCount += 1
            }
        }
        
        let chineseRatio = Double(chineseCount) / Double(textLength)
        let japaneseRatio = Double(japaneseCount) / Double(textLength)
        let koreanRatio = Double(koreanCount) / Double(textLength)
        
        // 如果中日韩字符比例都很低，可能是英文或其他语言
        if chineseRatio < 0.1 && japaneseRatio < 0.1 && koreanRatio < 0.1 {
            return "en" // 默认为英文
        }
        
        // 返回比例最高的语言
        if chineseRatio >= japaneseRatio && chineseRatio >= koreanRatio {
            return "zh"
        } else if japaneseRatio >= koreanRatio {
            return "ja"
        } else {
            return "ko"
        }
    }
}
