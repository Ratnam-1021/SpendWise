import Foundation
import PDFKit

struct PhonePeTransaction: Identifiable {
    let id = UUID()
    let date: Date
    let title: String
    let amount: Double
    let transactionID: String
    let isDebit: Bool
}

class PhonePeParser {
    static let shared = PhonePeParser()
    
    func parsePDF(at url: URL) -> [PhonePeTransaction] {
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
    
    private func parseText(_ text: String) -> [PhonePeTransaction] {
        var transactions: [PhonePeTransaction] = []
        
        // Regex patterns based on PhonePe statement format
        // Date pattern: Apr 19, 2026
        let datePattern = #"(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s\d{1,2},\s\d{4}"#
        // Amount pattern: ₹20 (handle commas too)
        let amountPattern = #"₹([\d,]+)"#
        // Transaction ID pattern: T2604191357492265742534
        let txIdPattern = #"Transaction ID (T\d+)"#
        // Title pattern: Paid to OM ENTERPRISES or Received from...
        let titlePattern = #"(Paid to|Received from)\s+([^\n\r]+)"#
        
        let lines = text.components(separatedBy: .newlines)
        
        var currentDate: Date?
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        
        // This is a simplified parser. PhonePe PDFs are multi-line.
        // We look for the Transaction ID as the anchor for each transaction.
        
        let txIdRegex = try? NSRegularExpression(pattern: txIdPattern)
        let amountRegex = try? NSRegularExpression(pattern: amountPattern)
        let titleRegex = try? NSRegularExpression(pattern: titlePattern)
        let dateRegex = try? NSRegularExpression(pattern: datePattern)
        
        // We will scan for Transaction IDs and then look around them for other info
        let nsText = text as NSString
        let txMatches = txIdRegex?.matches(in: text, range: NSRange(location: 0, length: nsText.length)) ?? []
        
        for match in txMatches {
            let txRange = match.range
            let txID = nsText.substring(with: match.range(at: 1))
            
            // Look backwards for Title and Date, forwards for Amount
            // In PhonePe format, Title is usually above Transaction ID
            let searchRange = NSRange(location: max(0, txRange.location - 300), length: min(text.count, txRange.location + 300))
            let localText = nsText.substring(with: searchRange) as NSString
            
            var title = "Unknown"
            var isDebit = true
            var amount = 0.0
            var date = Date()
            
            if let titleMatch = titleRegex?.firstMatch(in: localText as String, range: NSRange(location: 0, length: localText.length)) {
                let type = localText.substring(with: titleMatch.range(at: 1))
                title = localText.substring(with: titleMatch.range(at: 2)).trimmingCharacters(in: .whitespaces)
                isDebit = type.contains("Paid")
            }
            
            if let amountMatch = amountRegex?.firstMatch(in: localText as String, range: NSRange(location: 0, length: localText.length)) {
                let amountStr = localText.substring(with: amountMatch.range(at: 1)).replacingOccurrences(of: ",", with: "")
                amount = Double(amountStr) ?? 0.0
            }
            
            if let dateMatch = dateRegex?.firstMatch(in: localText as String, range: NSRange(location: 0, length: localText.length)) {
                let dateStr = localText.substring(with: dateMatch.range)
                date = dateFormatter.date(from: dateStr) ?? Date()
            }
            
            transactions.append(PhonePeTransaction(
                date: date,
                title: title,
                amount: amount,
                transactionID: txID,
                isDebit: isDebit
            ))
        }
        
        // Deduplicate based on transactionID
        var uniqueTransactions: [PhonePeTransaction] = []
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
