import Foundation
import NaturalLanguage

/// Service for generating intelligent filenames from OCR text using NLP and heuristics
actor SmartFilenameService {
    
    /// Generates a smart filename from OCR text
    /// - Parameter text: Combined OCR text from all pages
    /// - Returns: Suggested filename without extension
    func generateFilename(from text: String) async -> String {
        // Try to extract meaningful information from full text
        // (each extraction method handles its own text windowing)
        if let smartName = extractSmartName(from: text) {
            return smartName
        }

        // Fallback to date-based name
        return generateDatePrefix()
    }
    
    // MARK: - Smart Name Extraction
    
    private func extractSmartName(from text: String) -> String? {
        var components: [String] = []

        // 1. Extract company/organization name first (most important)
        if let company = extractCompanyName(from: text) {
            components.append(company)
        }

        // 2. Detect document type
        let docType = detectDocumentType(from: text)
        if let docType = docType {
            components.append(docType)
        }

        // 3. Extract invoice/reference number (for invoices, receipts)
        if let refNumber = extractReferenceNumber(from: text, docType: docType) {
            components.append(refNumber)
        }

        // Build filename if we found meaningful info
        guard !components.isEmpty else {
            return nil
        }

        // Use document date if found, otherwise use today's date
        let datePrefix: String
        if let docDate = extractDocumentDate(from: text) {
            datePrefix = docDate
        } else {
            datePrefix = generateDatePrefix()
        }

        let name = components.joined(separator: " ")
        let filename = "\(datePrefix) \(sanitizeFilename(name))"
        return filename
    }
    
    // MARK: - Document Type Detection
    
    private func detectDocumentType(from text: String) -> String? {
        let lowercased = text.lowercased()

        // Document types with priority scoring (higher priority types checked first)
        let documentTypes: [(keywords: [String], label: String, priority: Int)] = [
            // Invoice (highest priority - very specific keywords)
            (["invoice #", "invoice no", "facture n°", "facture no", "invoice number",
              "numéro de facture", "bill to:", "invoice date", "amount due", "montant dû",
              "payment terms", "conditions de paiement", "total due"], "Invoice", 10),

            // Receipt (high priority)
            (["receipt #", "receipt no", "reçu n°", "transaction id", "purchase receipt",
              "thank you for your purchase", "merci pour votre achat", "paid in full",
              "payé intégralement"], "Receipt", 9),

            // Statement (high priority - bank/credit card)
            (["account statement", "relevé de compte", "credit card statement",
              "relevé de carte", "statement period", "période de relevé", "previous balance",
              "solde précédent", "current balance", "solde actuel", "account number",
              "numéro de compte"], "Statement", 8),

            // Contract/Agreement (medium-high priority)
            (["this agreement", "cet accord", "contract between", "contrat entre",
              "terms and conditions", "termes et conditions", "hereby agree",
              "par la présente accepte", "effective date", "date d'effet",
              "signature:", "signatures:"], "Contract", 7),

            // Certificate (medium priority)
            (["certificate of", "certificat de", "this certifies", "certifie que",
              "awarded to", "décerné à", "completion certificate", "certificat d'achèvement",
              "attestation"], "Certificate", 6),

            // Letter (medium priority - formal correspondence)
            (["dear sir", "dear madam", "cher monsieur", "chère madame", "madame, monsieur",
              "to whom it may concern", "à qui de droit", "sincerely yours", "cordialement",
              "yours faithfully", "veuillez agréer"], "Letter", 5),

            // Report (medium priority)
            (["executive summary", "résumé exécutif", "table of contents", "table des matières",
              "introduction", "conclusion", "findings", "résultats", "recommendations",
              "recommandations", "annual report", "rapport annuel"], "Report", 5),

            // Form (lower priority)
            (["please complete", "veuillez remplir", "application form", "formulaire de demande",
              "fill in", "remplir", "form #", "formulaire n°"], "Form", 4),

            // Memo (lower priority)
            (["memorandum to:", "mémo à:", "memo from:", "mémo de:", "subject:", "objet:",
              "re:", "ref:"], "Memo", 3),

            // Meeting Notes (lower priority)
            (["meeting minutes", "procès-verbal", "attendees:", "participants:",
              "action items:", "points d'action:", "next meeting:", "prochaine réunion:"], "Meeting Notes", 3),

            // Generic fallbacks (lowest priority - broader keywords)
            (["invoice", "facture"], "Invoice", 2),
            (["receipt", "reçu"], "Receipt", 2),
            (["statement", "relevé"], "Statement", 2),
            (["contract", "contrat"], "Contract", 2),
            (["monsieur", "madame"], "Letter", 1),
            (["carte de crédit", "credit card"], "Statement", 1)
        ]

        // Sort by priority (highest first) and find first match
        let sortedTypes = documentTypes.sorted { $0.priority > $1.priority }

        for (keywords, label, _) in sortedTypes {
            for keyword in keywords {
                if lowercased.contains(keyword) {
                    return label
                }
            }
        }

        return nil
    }
    
    // MARK: - Company Name Extraction

    private func extractCompanyName(from text: String) -> String? {
        // Try NL-based extraction first
        if let nlName = extractCompanyNameUsingNL(from: text) {
            return nlName
        }

        // Fallback to heuristic-based extraction
        return extractCompanyNameHeuristic(from: text)
    }

    private func extractCompanyNameUsingNL(from text: String) -> String? {
        // Search first 5000 chars where headers/company names typically appear
        let searchText = String(text.prefix(5000))

        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = searchText

        var organizations: [(String, Int)] = []

        tagger.enumerateTags(in: searchText.startIndex..<searchText.endIndex,
                            unit: .word,
                            scheme: .nameType) { tag, range in
            if tag == .organizationName {
                let org = String(searchText[range])
                let position = searchText.distance(from: searchText.startIndex, to: range.lowerBound)
                organizations.append((org, position))
            }
            return true
        }

        // Prioritize organizations found early in document (likely to be the issuer)
        // But still check up to 2000 chars to catch documents with headers/logos
        for (org, position) in organizations where position < 2000 {
            let name = org.trimmingCharacters(in: .whitespaces)
            if name.count >= 3 && name.count <= 50 {
                return name
            }
        }

        return nil
    }

    private func extractCompanyNameHeuristic(from text: String) -> String? {
        // Get first non-empty lines which often contain company/organization
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Common company suffixes to look for
        let companySuffixes = [
            "Inc", "Inc.", "LLC", "Ltd", "Ltd.", "Corporation", "Corp", "Corp.",
            "SA", "S.A.", "SARL", "GmbH", "AG", "Sàrl", "Srl", "SRL",
            "& Co", "& Cie", "et Cie", "Company", "Co."
        ]

        // Try first 8 lines to find a company name
        for (index, line) in lines.prefix(8).enumerated() {
            // Skip very short lines (less than 3 chars)
            guard line.count >= 3 else { continue }

            // Skip lines that look like addresses (contain numbers at start)
            if line.first?.isNumber == true { continue }

            // Strategy 1: Check for company legal suffixes
            for suffix in companySuffixes {
                if line.contains(suffix) {
                    // Extract up to the suffix
                    if let range = line.range(of: suffix) {
                        let companyName = String(line[..<range.upperBound]).trimmingCharacters(in: .whitespaces)
                        if companyName.count >= 3 && companyName.count <= 50 {
                            return companyName
                        }
                    }
                }
            }

            // Strategy 2: All-caps single or multi-word (likely logo/header)
            let uppercaseCount = line.filter { $0.isUppercase }.count
            let letterCount = line.filter { $0.isLetter }.count

            if letterCount > 0 {
                let uppercaseRatio = Double(uppercaseCount) / Double(letterCount)
                let words = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }

                // Accept if >70% uppercase and 3-30 chars (tight constraint for quality)
                if uppercaseRatio >= 0.7 && line.count >= 3 && line.count <= 30 && words.count <= 4 {
                    // Skip if it looks like a country/postal code
                    let commonNonCompanyWords = ["PRIORITY", "POST", "SUISSE", "SWITZERLAND", "FRANCE", "GERMANY"]
                    if !commonNonCompanyWords.contains(where: { line.uppercased().contains($0) }) {
                        return line
                    }
                }

                // Strategy 3: Single word, all caps, 4-20 chars (brand names)
                if words.count == 1 && line.count >= 4 && line.count <= 20 && uppercaseRatio > 0.85 {
                    // Check if it's not a common generic word
                    let genericWords = ["INVOICE", "RECEIPT", "STATEMENT", "BILL", "FORM", "DOCUMENT"]
                    if !genericWords.contains(line.uppercased()) {
                        return line
                    }
                }
            }

            // Strategy 4: Title case with 2-4 words in first 3 lines (often company names)
            if index < 3 {
                let words = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                if words.count >= 2 && words.count <= 4 && line.count >= 5 && line.count <= 40 {
                    // Check if each word starts with uppercase (Title Case)
                    let isTitleCase = words.allSatisfy { word in
                        guard let firstChar = word.first else { return false }
                        return firstChar.isUppercase
                    }

                    if isTitleCase {
                        // Skip address-like patterns
                        let hasNumbers = line.contains(where: { $0.isNumber })
                        if !hasNumbers {
                            return line
                        }
                    }
                }
            }
        }

        return nil
    }
    
    // MARK: - Document Date Extraction

    private func extractDocumentDate(from text: String) -> String? {
        // Try NL-based date extraction first (looks for contextual dates like "Invoice Date:", "Date:")
        if let nlDate = extractDateUsingNL(from: text) {
            return nlDate
        }

        // Fallback to regex-based extraction
        return extractDateUsingRegex(from: text)
    }

    private func extractDateUsingNL(from text: String) -> String? {
        // Search first 3000 chars where document metadata typically appears
        let searchText = String(text.prefix(3000))

        // Look for date-related labels first
        let dateLabelPatterns = [
            "invoice date:", "date:", "dated:", "issue date:", "document date:",
            "date de facture:", "date:", "daté:", "date d'émission:",
            "statement date:", "contract date:", "effective date:"
        ]

        let lowercased = searchText.lowercased()
        var searchRange: Range<String.Index>?

        // Find the most relevant section containing a date label
        for pattern in dateLabelPatterns {
            if let range = lowercased.range(of: pattern) {
                // Search 150 chars after the label
                let startIndex = range.upperBound
                let endIndex = lowercased.index(startIndex, offsetBy: 150, limitedBy: lowercased.endIndex) ?? lowercased.endIndex
                searchRange = startIndex..<endIndex
                break
            }
        }

        // If no label found, search the entire first 1500 chars
        let finalSearchRange = searchRange ?? (searchText.startIndex..<(searchText.index(searchText.startIndex, offsetBy: min(1500, searchText.count))))
        let searchSubstring = String(searchText[finalSearchRange])

        // Use DataDetector to find dates
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }

        let matches = detector.matches(in: searchSubstring, options: [], range: NSRange(searchSubstring.startIndex..., in: searchSubstring))

        // Return the first valid date found
        if let match = matches.first, let date = match.date {
            // Filter out dates in the distant past or future
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: Date())
            let dateYear = calendar.component(.year, from: date)

            // Accept dates within +/- 5 years of current year
            if abs(dateYear - currentYear) <= 5 {
                return formatDate(date)
            }
        }

        return nil
    }

    private func extractDateUsingRegex(from text: String) -> String? {
        // Common date patterns to look for
        let datePatterns = [
            // ISO format: 2025-08-28, 2025/08/28
            "\\b(20\\d{2})[-/](0[1-9]|1[0-2])[-/](0[1-9]|[12][0-9]|3[01])\\b",
            // European format: 28.08.2025, 28/08/2025, 28-08-2025
            "\\b(0[1-9]|[12][0-9]|3[01])[-/.](0[1-9]|1[0-2])[-/.](20\\d{2})\\b",
            // French format: 28 août 2025, le 28 août 2025
            "\\b(\\d{1,2})\\s+(janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre)\\s+(20\\d{2})\\b",
            // English format: August 28, 2025
            "\\b(january|february|march|april|may|june|july|august|september|october|november|december)\\s+(\\d{1,2}),?\\s+(20\\d{2})\\b"
        ]

        let lowercased = text.lowercased()

        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(lowercased.startIndex..., in: lowercased)
                if let match = regex.firstMatch(in: lowercased, options: [], range: range) {
                    let matchedString = String(lowercased[Range(match.range, in: lowercased)!])

                    // Try to convert to YYYY-MM-DD format
                    if let standardDate = normalizeDate(matchedString) {
                        return standardDate
                    }
                }
            }
        }

        return nil
    }

    private func normalizeDate(_ dateString: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        // Try various input formats
        let formats = [
            "yyyy-MM-dd", "yyyy/MM/dd",
            "dd.MM.yyyy", "dd/MM/yyyy", "dd-MM-yyyy",
            "d MMMM yyyy", "MMMM d, yyyy"
        ]

        // Also try French month names
        let frenchFormatter = DateFormatter()
        frenchFormatter.locale = Locale(identifier: "fr_FR")

        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: dateString) {
                return formatDate(date)
            }

            frenchFormatter.dateFormat = format
            if let date = frenchFormatter.date(from: dateString) {
                return formatDate(date)
            }
        }

        return nil
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - Reference Number Extraction

    private func extractReferenceNumber(from text: String, docType: String?) -> String? {
        // Only extract reference numbers for specific document types
        guard let docType = docType,
              ["Invoice", "Receipt", "Statement", "Contract"].contains(docType) else {
            return nil
        }

        // Patterns for invoice/reference numbers
        let patterns = [
            // Invoice #12345, Invoice No. 12345, Facture N° 12345
            "(?:invoice|facture|receipt|reçu|ref|reference)\\s*[#n°no\\.:\\s]+\\s*([a-z0-9-]{3,15})",
            // INV-2024-001, REC-123456
            "\\b([a-z]{2,4}[-_]\\d{3,10})\\b",
            // Simple number after "No:" or "#:"
            "(?:no|#|n°)[:\\s]+([0-9]{4,10})\\b"
        ]

        let lowercased = text.lowercased()

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(lowercased.startIndex..., in: lowercased)
                if let match = regex.firstMatch(in: lowercased, options: [], range: range),
                   match.numberOfRanges > 1 {
                    let numberRange = match.range(at: 1)
                    if let swiftRange = Range(numberRange, in: lowercased) {
                        let refNumber = String(lowercased[swiftRange]).uppercased()
                        // Only return if it looks reasonable (not too long, has some digits)
                        if refNumber.count >= 3 && refNumber.count <= 15 &&
                           refNumber.contains(where: { $0.isNumber }) {
                            return "#\(refNumber)"
                        }
                    }
                }
            }
        }

        return nil
    }

    // MARK: - Filename Sanitization
    
    private func sanitizeFilename(_ name: String) -> String {
        // Remove invalid filename characters
        let invalidCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
        let sanitized = name.components(separatedBy: invalidCharacters).joined()
        
        // Replace multiple spaces with single space
        let normalized = sanitized
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        // Limit length to 80 characters
        let truncated = String(normalized.prefix(80))
        
        return truncated.trimmingCharacters(in: .whitespaces)
    }
    
    // MARK: - Date Prefix
    
    private func generateDatePrefix() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
