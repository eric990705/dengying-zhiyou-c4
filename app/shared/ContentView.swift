import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()

    var body: some View {
        TabView {
            HomeView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("首页", systemImage: "house")
                }

            RecognitionView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("识别", systemImage: "camera.viewfinder")
                }

            RoutesView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("路线", systemImage: "map")
                }

            LanternLibraryView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("灯组", systemImage: "square.grid.2x2")
                }
        }
        .tint(AppColors.red)
        .background(AppColors.surface)
        .task {
            await viewModel.refreshFromRemote()
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    hero
                    quickStats
                    dataSourceBanner
                    recognitionShortcut
                    hotLanterns
                    routes
                }
                .padding()
            }
            .background(AppColors.surface.ignoresSafeArea())
            .navigationTitle("灯影智游")
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [AppColors.ink, AppColors.red, AppColors.amber],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    GeometryReader { proxy in
                        Canvas { context, size in
                            for index in 0..<16 {
                                let rect = CGRect(
                                    x: CGFloat(index) * size.width / 12 - 30,
                                    y: CGFloat(index % 5) * 34 + 16,
                                    width: 32,
                                    height: 58
                                )
                                var path = Path()
                                path.addRoundedRect(in: rect, cornerSize: CGSize(width: 16, height: 16))
                                context.stroke(path, with: .color(.white.opacity(0.16)), lineWidth: 1.4)
                            }
                            var line = Path()
                            line.move(to: CGPoint(x: 0, y: size.height * 0.72))
                            line.addCurve(
                                to: CGPoint(x: size.width, y: size.height * 0.58),
                                control1: CGPoint(x: size.width * 0.28, y: size.height * 0.48),
                                control2: CGPoint(x: size.width * 0.68, y: size.height * 0.88)
                            )
                            context.stroke(line, with: .color(.white.opacity(0.26)), lineWidth: 2)
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height)
                    }
                }

            VStack(alignment: .leading, spacing: 12) {
                Pill(text: "AI识别 + 非遗导览", color: .white)
                    .background(.white.opacity(0.12), in: Capsule())
                Text("拍一下灯组\n看懂自贡彩灯")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                    .lineSpacing(4)
                Text("面向灯会展陈现场的移动识别导览原型")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.86))
            }
            .padding(22)
        }
        .frame(minHeight: 260)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var dataSourceBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: viewModel.isRefreshingRemoteData ? "arrow.triangle.2.circlepath" : "externaldrive.connected.to.line.below")
                .font(.title3)
                .foregroundStyle(AppColors.jade)
                .frame(width: 34, height: 34)
                .background(AppColors.jade.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text("数据源")
                    .font(.headline)
                Text(viewModel.dataSourceMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 8))
    }

    private var quickStats: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(viewModel.database.lanterns.count)", label: "样板灯组")
            StatCard(value: "3", label: "主题路线")
            StatCard(value: "2s", label: "演示返回")
        }
    }

    private var recognitionShortcut: some View {
        Button {
            viewModel.runDemoRecognition()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "camera.viewfinder")
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(AppColors.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 4) {
                    Text("开始拍照识别")
                        .font(.headline)
                    Text("演示模式会返回灯组名称、置信度和知识卡片")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.headline)
            }
            .foregroundStyle(AppColors.ink)
            .padding(16)
            .background(AppColors.card, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var hotLanterns: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("热门灯组", subtitle: "竞赛演示先覆盖 10-12 类稳定对象")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.hotLanterns) { lantern in
                        Button {
                            viewModel.selectedLantern = lantern
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                LanternVisual(lantern: lantern, height: 132, showsBadge: false)
                                Text(lantern.name)
                                    .font(.headline)
                                    .foregroundStyle(AppColors.ink)
                                    .lineLimit(1)
                                Text(lantern.area)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 190)
                            .padding(10)
                            .background(AppColors.card, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var routes: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("推荐路线")
            ForEach(viewModel.database.routes) { route in
                RouteRow(route: route, lanterns: viewModel.lanterns(for: route)) {
                    viewModel.selectedRoute = route
                }
            }
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(AppColors.red)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct RouteRow: View {
    let route: LanternRoute
    let lanterns: [Lantern]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(route.name)
                            .font(.headline)
                        Text("\(route.duration) · \(lanterns.count) 个点位")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                Text(route.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack {
                    ForEach(lanterns.prefix(3)) { lantern in
                        Pill(text: lantern.name, color: AppColors.blue)
                    }
                }
            }
            .foregroundStyle(AppColors.ink)
            .padding(14)
            .background(AppColors.card, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
