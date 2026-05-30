import SwiftUI

struct RoutesView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SectionTitle("路线导览", subtitle: "根据主题偏好生成轻量参观路径")
                    routePicker

                    if let route = viewModel.selectedRoute {
                        RouteDetail(route: route, lanterns: viewModel.lanterns(for: route))
                    }
                }
                .padding()
            }
            .background(AppColors.surface.ignoresSafeArea())
            .navigationTitle("路线")
        }
    }

    private var routePicker: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.database.routes) { route in
                RouteRow(route: route, lanterns: viewModel.lanterns(for: route)) {
                    viewModel.selectedRoute = route
                }
                .overlay {
                    if viewModel.selectedRoute?.id == route.id {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.red, lineWidth: 2)
                    }
                }
            }
        }
    }
}

struct RouteDetail: View {
    let route: LanternRoute
    let lanterns: [Lantern]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(route.name)
                    .font(.title2.weight(.bold))
                Text(route.summary)
                    .foregroundStyle(.secondary)
                Pill(text: route.duration, color: AppColors.red)
            }

            VStack(spacing: 0) {
                ForEach(Array(lanterns.enumerated()), id: \.element.id) { index, lantern in
                    RouteStop(index: index + 1, lantern: lantern, isLast: index == lanterns.count - 1)
                }
            }
        }
        .padding(16)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct RouteStop: View {
    let index: Int
    let lantern: Lantern
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Text("\(index)")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(AppColors.red, in: Circle())
                if !isLast {
                    Rectangle()
                        .fill(AppColors.red.opacity(0.22))
                        .frame(width: 2, height: 66)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(lantern.name)
                    .font(.headline)
                Text("\(lantern.category) · \(lantern.area)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(lantern.locationHint)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(.bottom, isLast ? 0 : 18)

            Spacer()
        }
    }
}

