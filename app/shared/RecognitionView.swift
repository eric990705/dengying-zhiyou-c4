import SwiftUI
#if os(iOS)
import PhotosUI
import UIKit
#elseif os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

struct RecognitionView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    #if os(iOS)
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isCameraPresented = false
    #elseif os(macOS)
    @State private var isFileImporterPresented = false
    #endif

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SectionTitle("拍照识别", subtitle: "相机/相册输入后，Vision/Core ML 输出目标框并匹配灯组知识卡片")

                    detectionPreview
                    actionPanel

                    if let result = viewModel.recognitionResult {
                        RecognitionResultCard(result: result)
                        LanternDetailCard(lantern: result.lantern)
                        feedbackPanel
                    } else {
                        emptyResult
                    }
                }
                .padding()
            }
            .background(AppColors.surface.ignoresSafeArea())
            .navigationTitle("AI识别")
            #if os(iOS)
            .sheet(isPresented: $isCameraPresented) {
                CameraImagePicker { image in
                    viewModel.runDetection(on: image)
                }
            }
            .onChange(of: selectedPhotoItem) { _, item in
                loadPhotoItem(item)
            }
            #elseif os(macOS)
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: [.image],
                allowsMultipleSelection: false
            ) { result in
                importImage(result)
            }
            #endif
        }
    }

    private var currentLantern: Lantern {
        viewModel.selectedLantern ?? viewModel.database.lanterns[0]
    }

    private var detectionPreview: some View {
        ZStack {
            if let selectedImage = viewModel.selectedImage {
                Image(platformImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 300)
                    .background(AppColors.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        detectionOverlay
                    }
            } else {
                LanternVisual(lantern: currentLantern, height: 300)
                    .overlay {
                        detectionOverlay
                    }
            }

            if viewModel.isRecognizing {
                ProgressView("正在检测灯组")
                    .font(.headline)
                    .padding(18)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var detectionOverlay: some View {
        GeometryReader { proxy in
            ForEach(viewModel.recognitionResult?.detections ?? []) { detection in
                DetectionBoxView(detection: detection, proxySize: proxy.size)
            }
        }
    }

    private var actionPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("输入照片并运行目标检测")
                .font(.headline)

            Picker("灯组", selection: Binding(
                get: { viewModel.selectedLantern?.id ?? currentLantern.id },
                set: { id in
                    viewModel.selectedLantern = viewModel.database.lanterns.first(where: { $0.id == id })
                }
            )) {
                ForEach(viewModel.database.lanterns) { lantern in
                    Text(lantern.name).tag(lantern.id)
                }
            }
            #if os(macOS)
            .pickerStyle(.menu)
            #else
            .pickerStyle(.navigationLink)
            #endif

            Text(viewModel.recognitionMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                #if os(iOS)
                Button {
                    isCameraPresented = true
                } label: {
                    Label("拍照检测", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.red)

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("相册检测", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                #elseif os(macOS)
                Button {
                    isFileImporterPresented = true
                } label: {
                    Label("导入图片", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.red)
                #endif

                Button {
                    viewModel.runSampleDetection(preferred: currentLantern)
                } label: {
                    Label("样张检测", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.resetRecognition()
                } label: {
                    Label("重置", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 8))
    }

    private var emptyResult: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("等待识别结果", systemImage: "viewfinder")
                .font(.headline)
            Text("目标检测模块已接入 Vision/Core ML。当前若没有训练好的 LanternDetector.mlmodel，会自动使用 Vision 显著目标检测作为可运行 fallback。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 8))
    }

    private var feedbackPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("识别反馈")
                .font(.headline)
            HStack(spacing: 12) {
                Button {
                    viewModel.submitFeedback(isAccurate: true)
                } label: {
                    Label("准确", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.jade)

                Button {
                    viewModel.submitFeedback(isAccurate: false)
                } label: {
                    Label("需要纠错", systemImage: "exclamationmark.triangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            if viewModel.feedbackSubmitted {
                Text(viewModel.feedbackMessage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.jade)
            }
        }
        .padding(16)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 8))
    }

    #if os(iOS)
    private func loadPhotoItem(_ item: PhotosPickerItem?) {
        guard let item else {
            return
        }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    viewModel.runDetection(on: image)
                    selectedPhotoItem = nil
                }
            }
        }
    }
    #elseif os(macOS)
    private func importImage(_ result: Result<[URL], Error>) {
        guard let url = try? result.get().first else {
            return
        }

        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        if let image = NSImage(contentsOf: url) {
            viewModel.runDetection(on: image)
        }
    }
    #endif
}

struct RecognitionResultCard: View {
    let result: RecognitionResult

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title)
                .foregroundStyle(AppColors.jade)
            VStack(alignment: .leading, spacing: 8) {
                Text(result.lantern.name)
                    .font(.title3.weight(.bold))
                HStack {
                    Pill(text: "置信度 \(Int(result.confidence * 100))%", color: AppColors.red)
                    Pill(text: result.lantern.area, color: AppColors.blue)
                    Pill(text: result.engine.rawValue, color: AppColors.jade)
                }
                Text("识别后自动匹配知识卡片、展区位置和推荐路线。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if result.detections.count > 1 {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(result.detections.prefix(4)) { detection in
                            HStack {
                                Text(detection.lantern.name)
                                Spacer()
                                Text("\(Int(detection.confidence * 100))%")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.caption)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct DetectionBoxView: View {
    let detection: LanternDetection
    let proxySize: CGSize

    var body: some View {
        let box = detection.box.clamped()
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6)
                .stroke(AppColors.amber, lineWidth: 3)
                .background(AppColors.amber.opacity(0.08))
            Text("\(detection.lantern.name) \(Int(detection.confidence * 100))%")
                .font(.caption2.weight(.bold))
                .lineLimit(1)
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(AppColors.red, in: RoundedRectangle(cornerRadius: 5))
                .padding(5)
        }
        .frame(width: proxySize.width * box.width, height: proxySize.height * box.height)
        .position(
            x: proxySize.width * (box.x + box.width / 2),
            y: proxySize.height * (box.y + box.height / 2)
        )
    }
}

#if os(iOS)
private struct CameraImagePicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked, dismiss: dismiss)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let onImagePicked: (UIImage) -> Void
        private let dismiss: DismissAction

        init(onImagePicked: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onImagePicked = onImagePicked
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
#endif
