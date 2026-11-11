import SwiftUI
import UIKit

// MARK: - 毛玻璃卡片
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial,
                        in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(.white.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }
}

// MARK: - 彩色圖示方塊
struct IconBadge: View {
    let icon: String
    let color: Color
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color.gradient,
                        in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
    }
}

// MARK: - 每一步的大標題
struct StepHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            IconBadge(icon: icon, color: color, size: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.bold())
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}

// MARK: - 卡片裡的小標題
struct CardTitle: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(color)
    }
}

// MARK: - 步驟進度條
struct StepIndicator: View {
    let current: Int
    let titles: [String]
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach(titles.indices, id: \.self) { i in
                VStack(spacing: 6) {
                    Capsule()
                        .fill(i <= current
                              ? AnyShapeStyle(color.gradient)
                              : AnyShapeStyle(Color.primary.opacity(0.12)))
                        .frame(height: 6)
                    Text(titles[i])
                        .font(.caption2.weight(i == current ? .bold : .regular))
                        .foregroundStyle(i == current ? color : .secondary)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: current)
    }
}

// MARK: - 目的地方塊
struct DestinationTile: View {
    let destination: Destination
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(destination.emoji)
                .font(.system(size: 34))
            Text(destination.name)
                .font(.subheadline.bold())
            Text("$\(destination.dailyCost.formatted())/天")
                .font(.caption2)
                .opacity(0.75)
        }
        .foregroundStyle(isSelected ? .white : .primary)
        .frame(maxWidth: .infinity)
        .frame(height: 110)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isSelected
                      ? AnyShapeStyle(destination.color.gradient)
                      : AnyShapeStyle(Color.primary.opacity(0.05)))
        )
        .overlay(alignment: .topTrailing) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .padding(8)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .shadow(color: isSelected ? destination.color.opacity(0.4) : .clear, radius: 10, y: 5)
        .scaleEffect(isSelected ? 1.04 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isSelected)
    }
}

// MARK: - 旅伴頭像（人數越多頭像越多）
struct PeopleAvatars: View {
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: -12) {
            ForEach(0..<min(count, 6), id: \.self) { i in
                Image(systemName: "person.crop.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, color.opacity(0.55 + 0.08 * Double(i)))
                    .font(.system(size: 42))
                    .background(Circle().fill(Color(.systemBackground)))
                    .transition(.scale.combined(with: .opacity))
            }
            if count > 6 {
                Text("+\(count - 6)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(color))
                    .transition(.scale)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: count)
    }
}

// MARK: - 有圖示的開關列
struct OptionToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let color: Color

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                IconBadge(icon: icon, color: isOn ? color : .gray)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .tint(color)
    }
}

// MARK: - 一列「項目 — 金額」
struct CostRow: View {
    let icon: String
    let title: String
    let amount: Int

    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundStyle(.secondary)
            Spacer()
            Text("NT$ \(amount.formatted())")
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .font(.subheadline)
    }
}
