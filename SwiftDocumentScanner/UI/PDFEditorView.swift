import SwiftUI
import PDFKit

/// View for previewing and editing the generated PDF (works both as sheet and navigation destination)
struct PDFEditorView: View {
    let pdfData: Data
    let onUpdate: ((Data) -> Void)?

    init(pdfData: Data, onUpdate: ((Data) -> Void)? = nil) {
        self.pdfData = pdfData
        self.onUpdate = onUpdate
    }

    var body: some View {
        PDFKitEditView(data: pdfData, onUpdate: onUpdate)
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Edit Pages")
            .navigationBarTitleDisplayMode(.inline)
    }
}

/// UIViewRepresentable wrapper for PDFView with editing support
struct PDFKitEditView: UIViewRepresentable {
    let data: Data
    let onUpdate: ((Data) -> Void)?

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()

        // Main PDF view
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.accessibilityLabel = "PDF preview"
        pdfView.accessibilityHint = "Swipe to navigate pages"
        containerView.addSubview(pdfView)

        // Create custom collection view for thumbnails with editing
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 140)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        // Use directional insets for proper RTL support
        layout.sectionInsetReference = .fromLayoutMargins
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = context.coordinator
        collectionView.dataSource = context.coordinator
        collectionView.register(PDFThumbnailCell.self, forCellWithReuseIdentifier: "ThumbnailCell")
        collectionView.dragDelegate = context.coordinator
        collectionView.dropDelegate = context.coordinator
        collectionView.dragInteractionEnabled = true
        collectionView.accessibilityLabel = "Page thumbnails"
        collectionView.accessibilityHint = "Swipe to navigate between pages. Double tap a page to view it. Drag to reorder pages."
        containerView.addSubview(collectionView)

        // Set up constraints
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: containerView.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: collectionView.topAnchor),

            collectionView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 160)
        ])

        // Store references in context
        context.coordinator.pdfView = pdfView
        context.coordinator.collectionView = collectionView
        context.coordinator.onUpdate = onUpdate

        return containerView
    }

    func updateUIView(_ containerView: UIView, context: Context) {
        guard let pdfView = context.coordinator.pdfView,
              let collectionView = context.coordinator.collectionView else { return }

        // Update document if needed
        if pdfView.document == nil, let document = PDFDocument(data: data) {
            pdfView.document = document
            context.coordinator.document = document
            context.coordinator.generateThumbnails()
            collectionView.reloadData()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
        var pdfView: PDFView?
        var collectionView: UICollectionView?
        var document: PDFDocument?
        var hasChanges = false
        var thumbnails: [(page: PDFPage, image: UIImage)] = []
        var onUpdate: ((Data) -> Void)?

        deinit {
            // Save changes when view is dismissed
            if hasChanges, let document = document, let updatedData = document.dataRepresentation() {
                onUpdate?(updatedData)
            }
        }

        func generateThumbnails() {
            guard let document = document else { return }
            thumbnails = []
            for i in 0..<document.pageCount {
                if let page = document.page(at: i) {
                    let thumbnail = page.thumbnail(of: CGSize(width: 100, height: 140), for: .trimBox)
                    thumbnails.append((page: page, image: thumbnail))
                }
            }
        }

        // MARK: - UICollectionViewDataSource
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return thumbnails.count
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailCell", for: indexPath) as! PDFThumbnailCell
            let thumbnail = thumbnails[indexPath.item]
            cell.configure(with: thumbnail.image, pageNumber: indexPath.item + 1)
            cell.onDelete = { [weak self] in
                self?.deletePage(at: indexPath.item)
            }
            // Accessibility
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = "Page \(indexPath.item + 1)"
            cell.accessibilityHint = "Double tap to view this page. Swipe up or down to delete."
            cell.accessibilityTraits = .button
            return cell
        }

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            guard let pdfView = pdfView else { return }
            let page = thumbnails[indexPath.item].page
            pdfView.go(to: page)
        }

        // MARK: - Page Management
        func deletePage(at index: Int) {
            guard let document = document, document.pageCount > 1 else { return }
            document.removePage(at: index)
            thumbnails.remove(at: index)
            collectionView?.deleteItems(at: [IndexPath(item: index, section: 0)])
            hasChanges = true
        }

        // MARK: - Drag & Drop
        func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
            let itemProvider = NSItemProvider(object: String(indexPath.item) as NSString)
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = indexPath.item
            return [dragItem]
        }

        func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }

        func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
            guard let destinationIndexPath = coordinator.destinationIndexPath,
                  let item = coordinator.items.first,
                  let sourceIndex = item.dragItem.localObject as? Int,
                  let document = document else { return }

            collectionView.performBatchUpdates({
                // Move in thumbnails array
                let thumbnail = thumbnails.remove(at: sourceIndex)
                thumbnails.insert(thumbnail, at: destinationIndexPath.item)

                // Move in PDF document
                if let page = document.page(at: sourceIndex) {
                    document.removePage(at: sourceIndex)
                    document.insert(page, at: destinationIndexPath.item)
                }

                // Move in collection view
                collectionView.deleteItems(at: [IndexPath(item: sourceIndex, section: 0)])
                collectionView.insertItems(at: [destinationIndexPath])

                hasChanges = true
            })

            coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
        }
    }
}

// MARK: - Custom Thumbnail Cell
class PDFThumbnailCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let pageLabel = UILabel()
    private let deleteButton = UIButton(type: .system)
    var onDelete: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // Image view
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.separator.cgColor
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)

        // Page label
        pageLabel.font = .systemFont(ofSize: 10)
        pageLabel.textAlignment = .center
        pageLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pageLabel)

        // Delete button
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.backgroundColor = .systemBackground
        deleteButton.layer.cornerRadius = 12
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        deleteButton.accessibilityLabel = "Delete page"
        deleteButton.accessibilityTraits = .button
        contentView.addSubview(deleteButton)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            imageView.bottomAnchor.constraint(equalTo: pageLabel.topAnchor, constant: -4),

            pageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            pageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            pageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            pageLabel.heightAnchor.constraint(equalToConstant: 14),

            deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            deleteButton.widthAnchor.constraint(equalToConstant: 24),
            deleteButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    func configure(with image: UIImage, pageNumber: Int) {
        imageView.image = image
        pageLabel.text = "Page \(pageNumber)"
    }

    @objc private func deleteButtonTapped() {
        onDelete?()
    }
}

#Preview {
    // Create a simple PDF for preview
    let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
    let data = renderer.pdfData { context in
        context.beginPage()
        let text = "Sample PDF Preview"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24)
        ]
        text.draw(at: CGPoint(x: 50, y: 50), withAttributes: attributes)
    }

    return PDFEditorView(pdfData: data)
}
