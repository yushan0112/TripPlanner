import SwiftUI
import UIKit

// 確認出發後跳出的登機證
struct TicketView: View {
    let plan: TripPlan
    let themeColor: Color
    let coverImage: Image?

    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // 上半部：封面與航線
                    ZStack {
                        Group {
                            if let coverImage {
                                coverImage.resizable().scaledToFill()
                            } else {
                                LinearGradient(colors: [plan.destination.color, themeColor],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            }
                        }
                        .frame(height: 170)
                        .clipped()
                        .overlay(Color.black.opacity(0.3))

                        HStack {
                            airport(code: "TPE", city: "台北")
                            Spacer()
                            Image(systemName: "airplane")
                                .font(.title)
                                .symbolEffect(.bounce, value: appeared)
                            Spacer()
                            airport(code: plan.destination.code, city: plan.destination.name)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                    }

                    // 虛線撕線
                    Line()
                        .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                        .foregroundStyle(.secondary)
                        .frame(height: 1)
                        .padding(.horizontal)
                        .padding(.vertical, 16)

                    // 下半部：資訊
                    VStack(alignment: .leading, spacing: 16) {
                        Text(plan.name)
                            .font(.title2.bold())

                        Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 14) {
                            GridRow {
                                info("日期", plan.dateText)
                                info("出發", plan.timeText)
                            }
                            GridRow {
                                info("天數", "\(plan.days) 天 \(plan.nights) 夜")
                                info("人數", "\(plan.people) 人")
                            }
                            GridRow {
                                info("交通", plan.travelClass.rawValue)
                                info("住宿", plan.needHotel ? plan.hotel.rawValue : "不需要")
                            }
                        }

                        Divider()

                        HStack(alignment: .firstTextBaseline) {
                            Text("每人平均")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("NT$ \(plan.perPerson.formatted())")
                                .font(.title.bold())
                                .foregroundStyle(themeColor)
                        }
                        Text("總花費 NT$ \(plan.total.formatted())")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        if !plan.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("行程筆記", systemImage: "note.text")
                                    .font(.subheadline.bold())
                                Text(plan.notes)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // 假條碼
                        HStack(spacing: 2) {
                            ForEach(0..<40, id: \.self) { i in
                                Rectangle()
                                    .frame(width: CGFloat([1, 2, 3][i % 3]), height: 44)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                    }
                    .padding([.horizontal, .bottom], 24)
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: .black.opacity(0.15), radius: 16, y: 8)
                .padding()
                // 登機證從下方彈上來
                .offset(y: appeared ? 0 : 300)
                .opacity(appeared ? 1 : 0)
            }
            .background(Color(.systemGroupedBackground))
            .fontDesign(.rounded)
            .navigationTitle("Bon Voyage!")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    appeared = true
                }
            }
        }
    }

    private func airport(code: String, city: String) -> some View {
        VStack(spacing: 2) {
            Text(code)
                .font(.system(size: 36, weight: .heavy, design: .rounded))
            Text(city)
                .font(.caption)
        }
    }

    private func info(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
        }
    }
}

// 撕線用的水平線
struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
