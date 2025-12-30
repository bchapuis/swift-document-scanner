import SwiftUI
import PDFKit

enum SortOption: String, CaseIterable {
    case dateNewest = "Date (Newest First)"
    case dateOldest = "Date (Oldest First)"
    case nameAZ = "Name (A-Z)"
    case nameZA = "Name (Z-A)"
}

@MainActor
@Observable
final class HistoryViewModel {
    var documents: [SavedDocument] = []
    var searchText = ""
    var sortOption: SortOption = .dateNewest

    private let repository = DocumentRepository()

    var filteredAndSortedDocuments: [SavedDocument] {
        var result = documents

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { document in
                document.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Sort based on option
        switch sortOption {
        case .dateNewest:
            result.sort { $0.createdAt > $1.createdAt }
        case .dateOldest:
            result.sort { $0.createdAt < $1.createdAt }
        case .nameAZ:
            result.sort { $0.displayName.localizedCompare($1.displayName) == .orderedAscending }
        case .nameZA:
            result.sort { $0.displayName.localizedCompare($1.displayName) == .orderedDescending }
        }

        return result
    }

    func loadDocuments() {
        Task {
            documents = await repository.fetchAll()
        }
    }

    func refreshDocuments() async {
        documents = await repository.fetchAll()
    }

    func deleteDocument(_ document: SavedDocument) {
        Task {
            try? await repository.delete(id: document.id)
            documents = await repository.fetchAll()
        }
    }

    func getFileSize(for document: SavedDocument) -> String? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: document.fileURL.path),
              let fileSize = attributes[.size] as? Int64 else {
            return nil
        }

        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

struct HistoryView: View {
    @State private var viewModel = HistoryViewModel()

    var body: some View {
        Group {
            if viewModel.documents.isEmpty && viewModel.searchText.isEmpty {
                emptyState
            } else {
                documentList
            }
        }
        .navigationTitle("Past Scans")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $viewModel.searchText,
            placement: .toolbar,
            prompt: "Search documents"
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort By", selection: $viewModel.sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
            }
        }
        .onAppear {
            viewModel.loadDocuments()
        }
        .refreshable {
            await viewModel.refreshDocuments()
        }
    }

    private var documentList: some View {
        List {
            if viewModel.filteredAndSortedDocuments.isEmpty {
                ContentUnavailableView.search
            } else {
                ForEach(viewModel.filteredAndSortedDocuments) { document in
                    NavigationLink(destination: SavedDocumentActionsView(document: document)) {
                        DocumentRow(document: document, fileSize: viewModel.getFileSize(for: document))
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteDocument(document)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Scans Yet",
            systemImage: "doc.text.magnifyingglass",
            description: Text("Scanned documents will appear here")
        )
    }
}

struct DocumentRow: View {
    let document: SavedDocument
    let fileSize: String?

    @State private var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            // PDF Thumbnail
            Group {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.red.gradient)

                        Image(systemName: "doc.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(width: 44, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            .accessibilityHidden(true)

            // Document Info
            VStack(alignment: .leading, spacing: 2) {
                Text(document.displayName.replacingOccurrences(of: ".pdf", with: ""))
                    .font(.body)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text(document.createdAt, format: .relative(presentation: .named))
                    Text("•")
                    Text("\(document.pageCount) page\(document.pageCount == 1 ? "" : "s")")
                    if let fileSize = fileSize {
                        Text("•")
                        Text(fileSize)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .task {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        Task.detached(priority: .background) {
            guard let pdfDocument = PDFDocument(url: document.fileURL),
                  let page = pdfDocument.page(at: 0) else {
                return
            }

            let pageRect = page.bounds(for: .mediaBox)
            let scale: CGFloat = 132 / max(pageRect.width, pageRect.height) // 44pt * 3 for @3x
            let thumbnailSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

            let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
            let thumbnailImage = renderer.image { context in
                UIColor.white.set()
                context.fill(CGRect(origin: .zero, size: thumbnailSize))

                context.cgContext.translateBy(x: 0, y: thumbnailSize.height)
                context.cgContext.scaleBy(x: scale, y: -scale)

                page.draw(with: .mediaBox, to: context.cgContext)
            }

            await MainActor.run {
                thumbnail = thumbnailImage
            }
        }
    }
}

#Preview("History View") {
    NavigationStack {
        HistoryView()
    }
}

#Preview("Document Row") {
    List {
        DocumentRow(
            document: SavedDocument(
                internalFilename: "20251229-120000.pdf",
                displayName: "Example Document.pdf",
                fileURL: URL(fileURLWithPath: "/tmp/example.pdf"),
                createdAt: Date().addingTimeInterval(-3600),
                pageCount: 3
            ),
            fileSize: "1.2 MB"
        )
    }
    .listStyle(.insetGrouped)
}
