import SwiftUI

@MainActor
@Observable
final class HistoryViewModel {
    var documents: [SavedDocument] = []

    private let repository = DocumentRepository()

    func loadDocuments() {
        Task {
            documents = await repository.fetchAll()
        }
    }

    func deleteDocument(_ document: SavedDocument) {
        Task {
            try? await repository.delete(id: document.id)
            documents = await repository.fetchAll()
        }
    }
}

struct HistoryView: View {
    @State private var viewModel = HistoryViewModel()

    var body: some View {
        List {
            if viewModel.documents.isEmpty {
                emptyStateRow
            } else {
                ForEach(Array(viewModel.documents.enumerated()), id: \.element.id) { index, document in
                    VStack(spacing: 0) {
                        NavigationLink(destination: SavedDocumentActionsView(document: document)) {
                            DocumentRow(document: document)
                        }
                        .padding(.trailing, DesignSystem.Spacing.sm)

                        // Show divider for all items except the last one
                        if index < viewModel.documents.count - 1 {
                            Divider()
                                .accessibilityHidden(true)
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteDocument(document)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .accessibilityLabel("Delete \(document.displayName)")
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Past Scans")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadDocuments()
        }
    }

    private var emptyStateRow: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: DesignSystem.IconSize.header))
                .foregroundStyle(.secondary)
                .accessibilityLabel("No documents")

            Text("No Scans Yet")
                .font(DesignSystem.Typography.screenTitle)
                .accessibilityAddTraits(.isHeader)

            Text("Your scanned documents will appear here")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No scans yet. Your scanned documents will appear here")
    }
}

struct DocumentRow: View {
    let document: SavedDocument

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "doc.fill")
                .font(.title2)
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: DesignSystem.IconSize.listItem)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(document.displayName)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text(document.createdAt, style: .date)
                    Text("•")
                    Text("\(document.pageCount) page\(document.pageCount == 1 ? "" : "s")")
                }
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(document.displayName), \(document.pageCount) page\(document.pageCount == 1 ? "" : "s"), scanned \(document.createdAt.formatted(date: .abbreviated, time: .omitted))")
        .accessibilityHint("Double tap to view document actions")
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
}
