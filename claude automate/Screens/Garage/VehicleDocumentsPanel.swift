import SwiftUI
import PhotosUI
import QuickLook
import QuickLookThumbnailing
import UniformTypeIdentifiers

// MARK: - Documents panel (Maintenance → Documents, Figma 621:1568)

struct VehicleDocumentsPanel: View {
    @Environment(AppState.self) private var appState
    let vehicle: Vehicle

    /// nil = "All".
    @State private var filter: DocumentCategory?
    @State private var showSourcePicker = false
    @State private var showPhotoPicker = false
    @State private var showFileImporter = false
    @State private var showCamera = false
    @State private var photoItem: PhotosPickerItem?
    @State private var pending: PendingDocument?
    @State private var editing: VehicleDocument?
    @State private var previewURL: URL?
    @State private var confirmDelete: VehicleDocument?
    @State private var importError: String?

    private var allDocuments: [VehicleDocument] { appState.documents(for: vehicle.id) }

    private var shown: [VehicleDocument] {
        guard let filter else { return allDocuments }
        return allDocuments.filter { $0.category == filter }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            categoryChips

            if shown.isEmpty {
                emptyState
            } else {
                documentList
            }
        }
        .confirmationDialog("Add a document", isPresented: $showSourcePicker, titleVisibility: .visible) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") { showCamera = true }
            }
            Button("Choose from Photos") { showPhotoPicker = true }
            Button("Choose File") { showFileImporter = true }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            photoItem = nil
            Task { await importPhoto(item) }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.pdf, .image]) { result in
            importFile(result)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCapture { image in
                if let image { pending = PendingDocument(image: image, category: filter) }
            }
            .ignoresSafeArea()
        }
        .sheet(item: $pending) { pending in
            DocumentDetailsSheet(mode: .new(pending), vehicle: vehicle)
        }
        .sheet(item: $editing) { document in
            DocumentDetailsSheet(mode: .edit(document), vehicle: vehicle)
        }
        .quickLookPreview($previewURL)
        .alert(
            "Delete this document?",
            isPresented: Binding(get: { confirmDelete != nil }, set: { if !$0 { confirmDelete = nil } }),
            presenting: confirmDelete
        ) { document in
            Button("Delete", role: .destructive) {
                withAnimation(.snappy) { appState.deleteDocument(document) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { document in
            Text("“\(document.title)” will be removed from this phone. This can’t be undone.")
        }
        .alert(
            "Couldn’t add that file",
            isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "")
        }
    }

    // MARK: Category chips

    private var categoryChips: some View {
        FlowLayout(spacing: 8) {
            chip(icon: "doc-icon-all", label: "All", count: allDocuments.count, selected: filter == nil) {
                filter = nil
            }
            ForEach(DocumentCategory.allCases) { category in
                chip(
                    icon: category.iconName,
                    label: category.rawValue,
                    count: allDocuments.filter { $0.category == category }.count,
                    selected: filter == category
                ) {
                    filter = category
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chip(
        icon: String, label: String, count: Int, selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.2)) { action() }
        } label: {
            HStack(spacing: 8) {
                Image(icon)
                    .renderingMode(.template)
                    .frame(width: 16, height: 16)
                Text(label)
                    .font(.quicksandScaled(.medium, size: 12))
                Text("\(count)")
                    .font(.quicksandScaled(.regular, size: 11))
                    .monospacedDigit()
                    .opacity(0.7)
            }
            .foregroundStyle(selected ? Color.vdAccent : Color.vdMuted)
            .padding(.horizontal, 12.625)
            .padding(.vertical, 8.625)
            .background(selected ? Color.vdAccent.opacity(0.1) : Color.vdPage, in: Capsule())
            .overlay(
                Capsule().strokeBorder(selected ? Color.vdAccent.opacity(0.4) : Color.vdBorder, lineWidth: 1)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label), \(count)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: Empty state

    private var emptyState: some View {
        Button { showSourcePicker = true } label: {
            VStack(spacing: 12) {
                uploadBadge
                VStack(spacing: 6) {
                    Text(filter.map { "No \($0.rawValue.lowercased()) yet" } ?? "No documents yet")
                        .font(.quicksandScaled(.semibold, size: 15))
                        .foregroundStyle(Color.vdInk)
                    Text("Snap a photo or upload a PDF. We’ll keep it safe and easy to find.")
                        .font(.quicksandScaled(.regular, size: 12))
                        .foregroundStyle(Color.vdMuted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .frame(maxWidth: 200)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16.625)
            .padding(.vertical, 32.625)
            .background(Color.vdTrack.opacity(0.4), in: RoundedRectangle(cornerRadius: 16))
            .overlay(dashedBorder(cornerRadius: 16))
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(filter.map { "Upload a document to \($0.rawValue)" } ?? "Upload a document")
    }

    private var uploadBadge: some View {
        Image("doc-icon-upload")
            .renderingMode(.template)
            .foregroundStyle(Color.vdAccent)
            .frame(width: 20, height: 20)
            .frame(width: 48, height: 48)
            .background(Color.vdPage, in: Circle())
            .shadow(color: .black.opacity(0.05), radius: 0.5, x: 0, y: 1)
    }

    private func dashedBorder(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(Color.vdBorder, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
    }

    // MARK: List

    private var documentList: some View {
        VStack(spacing: 8) {
            ForEach(shown) { document in
                DocumentRow(document: document, fileURL: appState.fileURL(for: document)) {
                    previewURL = appState.fileURL(for: document)
                }
                .contextMenu {
                    Button("Edit Details", systemImage: "pencil") { editing = document }
                    ShareLink(item: appState.fileURL(for: document)) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Button("Delete", systemImage: "trash", role: .destructive) { confirmDelete = document }
                }
            }

            addRow
        }
    }

    private var addRow: some View {
        Button { showSourcePicker = true } label: {
            HStack(spacing: 8) {
                Image("doc-icon-upload")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 16, height: 16)
                Text(filter.map { "Add \($0.singular.lowercased())" } ?? "Add a document")
                    .font(.quicksandScaled(.semibold, size: 13))
            }
            .foregroundStyle(Color.vdAccent)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(Color.vdTrack.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
            .overlay(dashedBorder(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: Importing

    private func importPhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            importError = "That photo couldn’t be loaded. Try another one."
            return
        }
        pending = PendingDocument(image: image, category: filter)
    }

    private func importFile(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url) else {
            importError = "That file couldn’t be read."
            return
        }
        let name = url.deletingPathExtension().lastPathComponent
        if UTType(filenameExtension: url.pathExtension)?.conforms(to: .pdf) == true {
            pending = PendingDocument(data: data, kind: .pdf, suggestedTitle: name, category: filter)
        } else if let image = UIImage(data: data) {
            pending = PendingDocument(image: image, suggestedTitle: name, category: filter)
        } else {
            importError = "Only photos and PDFs can be added."
        }
    }
}

// MARK: - Row

private struct DocumentRow: View {
    let document: VehicleDocument
    let fileURL: URL
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                DocumentThumbnail(url: fileURL, kind: document.kind, category: document.category)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(document.title)
                        .font(.quicksandScaled(.semibold, size: 14))
                        .foregroundStyle(Color.vdInk)
                        .lineLimit(1)
                    Text("\(document.category.singular) · \(document.addedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.quicksandScaled(.regular, size: 12))
                        .foregroundStyle(Color.vdMuted)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image("vehicle-icon-chevron")
                    .renderingMode(.template)
                    .foregroundStyle(Color.vdMuted)
                    .frame(width: 16, height: 16)
            }
            .padding(12)
            .background(Color.vdSurface, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.vdBorder, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the document")
    }
}

/// QuickLook thumbnail of the saved file, with a category icon while it loads.
private struct DocumentThumbnail: View {
    let url: URL
    let kind: VehicleDocument.Kind
    let category: DocumentCategory
    @Environment(\.displayScale) private var scale
    @State private var image: UIImage?

    var body: some View {
        // Color.vdTrack sets the size; the photo fills it as an overlay so a
        // wide image can't push the thumbnail past its frame.
        Color.vdTrack
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(category.iconName)
                        .renderingMode(.template)
                        .foregroundStyle(Color.vdMuted)
                        .frame(width: 16, height: 16)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .bottomTrailing) {
            if kind == .pdf {
                Text("PDF")
                    .font(.quicksand(.bold, size: 8))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.vdAccent, in: RoundedRectangle(cornerRadius: 4))
                    .padding(3)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.vdBorder, lineWidth: 0.625))
        .task(id: url) {
            let request = QLThumbnailGenerator.Request(
                fileAt: url, size: CGSize(width: 44, height: 44), scale: scale, representationTypes: .thumbnail
            )
            image = try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: request).uiImage
        }
    }
}

// MARK: - Pending upload

struct PendingDocument: Identifiable {
    let id = UUID()
    let data: Data
    let kind: VehicleDocument.Kind
    let preview: UIImage?
    let suggestedTitle: String?
    let category: DocumentCategory?

    init(data: Data, kind: VehicleDocument.Kind, suggestedTitle: String? = nil, category: DocumentCategory?) {
        self.data = data
        self.kind = kind
        self.preview = nil
        self.suggestedTitle = suggestedTitle
        self.category = category
    }

    /// Downscales big photos and stores them as JPEG.
    init(image: UIImage, suggestedTitle: String? = nil, category: DocumentCategory?) {
        let resized = image.resized(maxDimension: 2400)
        self.data = resized.jpegData(compressionQuality: 0.8) ?? Data()
        self.kind = .image
        self.preview = resized
        self.suggestedTitle = suggestedTitle
        self.category = category
    }
}

private extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }
        let ratio = maxDimension / longest
        let target = CGSize(width: size.width * ratio, height: size.height * ratio)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

// MARK: - Name + category sheet (new upload or edit)

struct DocumentDetailsSheet: View {
    enum Mode {
        case new(PendingDocument)
        case edit(VehicleDocument)
    }

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let mode: Mode
    let vehicle: Vehicle

    @State private var title = ""
    @State private var category: DocumentCategory = .receipts
    @State private var saveFailed = false

    private var isNew: Bool { if case .new = mode { return true } else { return false } }
    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        FormSheetScaffold(
            eyebrow: isNew ? "Add document" : "Edit document",
            title: vehicle.displayName,
            canSave: !trimmedTitle.isEmpty,
            onClose: { dismiss() },
            onSave: save
        ) {
            VStack(alignment: .leading, spacing: 20) {
                if case .new(let pending) = mode {
                    preview(pending)
                }

                FormSheetField(label: "Name *") {
                    FormSheetTextField(placeholder: "e.g. Oil change receipt", text: $title)
                }

                FormSheetField(label: "Category") {
                    FormSheetMenuField(selection: $category, options: DocumentCategory.allCases) { $0.rawValue }
                }

                if isNew {
                    FormSheetHint(text: "Stored on this phone only.")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear(perform: prefill)
        .alert("Couldn’t save the document", isPresented: $saveFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("There may not be enough free space on this phone.")
        }
    }

    @ViewBuilder
    private func preview(_ pending: PendingDocument) -> some View {
        Group {
            if let image = pending.preview {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "doc.richtext")
                        .font(.system(size: 28, weight: .light))
                    Text("PDF")
                        .font(.quicksand(.semibold, size: 12))
                }
                .foregroundStyle(Color.vdMuted)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.vdTrack)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.vdBorder, lineWidth: 1))
        .accessibilityHidden(true)
    }

    private func prefill() {
        switch mode {
        case .new(let pending):
            category = pending.category ?? .receipts
            title = pending.suggestedTitle ?? ""
        case .edit(let document):
            category = document.category
            title = document.title
        }
    }

    private func save() {
        switch mode {
        case .new(let pending):
            let added = appState.addDocument(
                vehicleId: vehicle.id, title: trimmedTitle, category: category,
                kind: pending.kind, data: pending.data
            )
            if added == nil { saveFailed = true; return }
        case .edit(var document):
            document.title = trimmedTitle
            document.category = category
            appState.updateDocument(document)
        }
        dismiss()
    }
}

// MARK: - Camera

private struct CameraCapture: UIViewControllerRepresentable {
    let onFinish: (UIImage?) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCapture
        init(_ parent: CameraCapture) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.originalImage] as? UIImage
            parent.dismiss()
            // Let the camera finish closing before the details sheet opens.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { self.parent.onFinish(image) }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
