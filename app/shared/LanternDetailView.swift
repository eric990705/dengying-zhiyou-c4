import SwiftUI

struct LanternDetailCard: View {
    let lantern: Lantern

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LanternVisual(lantern: lantern, height: 170)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lantern.name)
                        .font(.title2.weight(.bold))
                    Text("\(lantern.category) · \(lantern.area)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            tagCloud
            InfoBlock(title: "主题寓意", systemImage: "text.book.closed", text: lantern.meaning)
            InfoBlock(title: "工艺特征", systemImage: "hammer", text: lantern.craft)
            InfoBlock(title: "推荐拍照点", systemImage: "camera", text: lantern.photoTip)
            InfoBlock(title: "展区提示", systemImage: "mappin.and.ellipse", text: lantern.locationHint)
        }
        .padding(16)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 8))
    }

    private var tagCloud: some View {
        HStack {
            ForEach(lantern.tags, id: \.self) { tag in
                Pill(text: tag, color: AppColors.red)
            }
        }
    }
}

struct InfoBlock: View {
    let title: String
    let systemImage: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(AppColors.ink)
            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct LanternLibraryView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var query = ""

    private var filtered: [Lantern] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return viewModel.database.lanterns
        }
        return viewModel.database.lanterns.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.category.localizedCaseInsensitiveContains(query) ||
            $0.tags.joined(separator: " ").localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { lantern in
                NavigationLink {
                    ScrollView {
                        LanternDetailCard(lantern: lantern)
                            .padding()
                    }
                    .background(AppColors.surface)
                    .navigationTitle(lantern.name)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(lantern.name)
                            .font(.headline)
                        Text("\(lantern.category) · \(lantern.area)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .searchable(text: $query, prompt: "搜索灯组、类别或标签")
            .navigationTitle("灯组知识库")
        }
    }
}

