import Foundation
import AppKit

/// Classifies string and pasteboard data into rich semantic types.
public struct ContentTypeClassifier {
    
    public struct ClassificationResult {
        public let type: ClipType
        public let language: String?
        public let hexColor: String?
    }
    
    /// Regular expressions for type matching
    private static let hexColorRegex = try? NSRegularExpression(
        pattern: "^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$",
        options: []
    )
    
    private static let rgbColorRegex = try? NSRegularExpression(
        pattern: "^(?:rgb|hsl)a?\\([^)]+\\)$",
        options: [.caseInsensitive]
    )
    
    public static func classify(text: String) -> ClassificationResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return ClassificationResult(type: .text, language: nil, hexColor: nil)
        }
        
        // 1. Check for Hex / RGB Color
        if let hexMatch = matchRegex(regex: hexColorRegex, in: trimmed) {
            return ClassificationResult(type: .color, language: nil, hexColor: hexMatch)
        }
        if matchRegex(regex: rgbColorRegex, in: trimmed) != nil {
            return ClassificationResult(type: .color, language: nil, hexColor: trimmed)
        }
        
        // 2. Check for URL
        if isLikelyURL(trimmed) {
            return ClassificationResult(type: .url, language: nil, hexColor: nil)
        }
        
        // 3. Check for Code Snippet
        if let detectedLang = detectProgrammingLanguage(trimmed) {
            return ClassificationResult(type: .code, language: detectedLang, hexColor: nil)
        }
        
        // Default to Plain Text
        return ClassificationResult(type: .text, language: nil, hexColor: nil)
    }
    
    private static func matchRegex(regex: NSRegularExpression?, in string: String) -> String? {
        guard let regex = regex else { return nil }
        let range = NSRange(location: 0, length: string.utf16.count)
        if regex.firstMatch(in: string, options: [], range: range) != nil {
            return string
        }
        return nil
    }
    
    public static func isLikelyURL(_ text: String) -> Bool {
        if text.contains("\n") || text.contains("\r") || text.contains(" ") {
            return false
        }
        if let url = URL(string: text), let scheme = url.scheme?.lowercased() {
            if (scheme == "http" || scheme == "https" || scheme == "ftp") && url.host != nil {
                return true
            }
        }
        return false
    }
    
    public static func detectProgrammingLanguage(_ text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)
        
        // JSON detection
        if (text.hasPrefix("{") && text.hasSuffix("}")) || (text.hasPrefix("[") && text.hasSuffix("]")) {
            if (try? JSONSerialization.jsonObject(with: Data(text.utf8), options: [])) != nil {
                return "JSON"
            }
        }
        
        // HTML / XML
        if text.contains("<!DOCTYPE") || (text.contains("<html") && text.contains("</html>")) || (text.contains("<div") && text.contains("</div>")) || text.hasPrefix("<?xml") {
            return "HTML"
        }
        
        // Shell
        if text.hasPrefix("#!/usr/bin/env") || text.hasPrefix("#!/bin/bash") || text.hasPrefix("#!/bin/zsh") || text.hasPrefix("sudo ") || text.hasPrefix("npm install") || text.hasPrefix("brew install") || text.hasPrefix("git clone") {
            return "Shell"
        }
        
        // SQL
        let sqlKeywords = ["SELECT ", "FROM ", "WHERE ", "INSERT INTO ", "UPDATE ", "DELETE FROM ", "CREATE TABLE ", "ALTER TABLE "]
        let upper = text.uppercased()
        var sqlMatches = 0
        for kw in sqlKeywords {
            if upper.contains(kw) {
                sqlMatches += 1
            }
        }
        if sqlMatches >= 2 {
            return "SQL"
        }
        
        // Swift
        let swiftKeywords = ["import SwiftUI", "import AppKit", "import Foundation", "func ", "var ", "let ", "guard let", "if let", "struct ", "class ", "extension ", "enum "]
        var swiftMatches = 0
        for kw in swiftKeywords {
            if text.contains(kw) {
                swiftMatches += 1
            }
        }
        if swiftMatches >= 2 {
            return "Swift"
        }
        
        // Python
        let pythonKeywords = ["def ", "import ", "from ", "class ", "elif ", "print(", "__name__ == '__main__'"]
        var pythonMatches = 0
        for kw in pythonKeywords {
            if text.contains(kw) {
                pythonMatches += 1
            }
        }
        if pythonMatches >= 2 && text.contains(":") {
            return "Python"
        }
        
        // JavaScript / TypeScript
        let jsKeywords = ["const ", "function(", "console.log(", "=>", "import {", "export default", "async function", "await "]
        var jsMatches = 0
        for kw in jsKeywords {
            if text.contains(kw) {
                jsMatches += 1
            }
        }
        if jsMatches >= 2 {
            return "JavaScript"
        }
        
        // Heuristic: multiple lines with programming punctuation
        if lines.count > 3 {
            let codeChars = ["{", "}", ";", "(", ")", "=>", "==", "!="]
            var codeCharHits = 0
            for char in codeChars {
                if text.contains(char) {
                    codeCharHits += 1
                }
            }
            if codeCharHits >= 3 {
                return "Code"
            }
        }
        
        return nil
    }
}
