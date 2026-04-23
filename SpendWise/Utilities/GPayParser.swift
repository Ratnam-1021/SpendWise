import Foundation
import PDFKit

struct GPayTransaction: Identifiable {
    let id = UUID()
    let date: Date
    let title: String
    let amount: Double
    let transactionID: String
    let isDebit: Bool
}

class GPayParser {
    static let shared = GPayParser()
    
    func parsePDF(at url: URL) -> [GPayTransaction] {
        guard let document = PDFDocument(url: url) else { return [] }
        var fullText = ""
        
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                fullText += page.string ?? ""
                fullText += "\n"
            }
        }
        
        return parseText(fullText)
    }
    
    private func parseText(_ text: String) -> [GPayTransaction] {
        var transactions: [GPayTransaction] = []
        
        // Regex patterns based on GPay statement format
        let datePattern = #"\d{1,2}\s(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec),\s\d{4}"#
        let amountPattern = #"₹([\d,.]+)"#
        let txIdPattern = #"UPI Transaction ID: (\d+)"#
        // Super Greedy Title pattern
        let titlePattern = #"(Paid to|Received from)\s+(.*?)(?=\n|UPI Transaction ID|$)"#
        
        let nsText = text as NSString
        let txIdRegex = try? NSRegularExpression(pattern: txIdPattern)
        let amountRegex = try? NSRegularExpression(pattern: amountPattern)
        let titleRegex = try? NSRegularExpression(pattern: titlePattern)
        let dateRegex = try? NSRegularExpression(pattern: datePattern)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM, yyyy"
        
        let txMatches = txIdRegex?.matches(in: text, range: NSRange(location: 0, length: nsText.length)) ?? []
        
        for match in txMatches {
            let txRange = match.range
            let txID = nsText.substring(with: match.range(at: 1))
            
            let start = max(0, txRange.location - 400)
            let end = min(nsText.length, txRange.location + 400)
            let searchRange = NSRange(location: start, length: end - start)
            let localText = nsText.substring(with: searchRange) as NSString
            
            print("--- GPay Block ---")
            print(localText)
            print("------------------")
            
            var title = "Unknown"
            var isDebit = true
            var amount = 0.0
            var date = Date()
            
            let flexibleTitlePattern = #"(?i)(id to|ed from|Paid to|Received from)\s+([\s\S]+?)(?=\s*(?:\n|UPI Transaction ID|$))"#
            let flexibleTitleRegex = try? NSRegularExpression(pattern: flexibleTitlePattern)
            
            if let titleMatch = flexibleTitleRegex?.firstMatch(in: localText as String, range: NSRange(location: 0, length: localText.length)) {
                let type = localText.substring(with: titleMatch.range(at: 1)).lowercased()
                let rawTitle = localText.substring(with: titleMatch.range(at: 2))
                
                // Re-assemble shattered words
                title = rawTitle.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\r", with: "").trimmingCharacters(in: .whitespaces)
                
                isDebit = type.contains("to")
                print("🎯 Found Title (GPay): \(title)")
            } else {
                print("❌ Could not find Title (GPay)")
            }
            
            if let amountMatch = amountRegex?.firstMatch(in: localText as String, range: NSRange(location: 0, length: localText.length)) {
                let amountStr = localText.substring(with: amountMatch.range(at: 1)).replacingOccurrences(of: ",", with: "")
                amount = Double(amountStr) ?? 0.0
            }
            
            if let dateMatch = dateRegex?.firstMatch(in: localText as String, range: NSRange(location: 0, length: localText.length)) {
                let dateStr = localText.substring(with: dateMatch.range)
                date = dateFormatter.date(from: dateStr) ?? Date()
            }
            
            transactions.append(GPayTransaction(
                date: date,
                title: title,
                amount: amount,
                transactionID: txID,
                isDebit: isDebit
            ))
        }
        
        var uniqueTransactions: [GPayTransaction] = []
        var seenIDs = Set<String>()
        for tx in transactions {
            if !seenIDs.contains(tx.transactionID) {
                uniqueTransactions.append(tx)
                seenIDs.insert(tx.transactionID)
            }
        }
        
        return uniqueTransactions
    }
}
