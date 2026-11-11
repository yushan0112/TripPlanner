import SwiftUI
import UIKit
import PhotosUI

// 規劃流程分成四步
enum PlanStep: Int, CaseIterable {
    case place, dates, people, style

    var title: String {
        switch self {
        case .place: "目的地"
        case .dates: "日期"
        case .people: "旅伴預算"
        case .style: "個人化"
        }
    }
}

struct ContentView: View {
    // MARK: - 使用者輸入的資料
    @State private var tripName = ""
    @State private var destination: Destination = .tokyo
    @State private var travelClass: TravelClass = .standard
    @State private var dates: Set<DateComponents> = []
    @State private var departTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
    @State private var people = 2
    @State private var budget: Double = 30000
    @State private var needHotel = true
    @State private var hotel: HotelLevel = .business
    @State private var insurance = false
    @State private var themeColor: Color = .indigo
    @State private var notes = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var coverImage: Image?

    // MARK: - 畫面狀態
    @State private var step: PlanStep = .place
    @State private var goingForward = true
    @State private var showSummary = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showTicket = false
    @State private var showReset = false
    @State private var infoDestination: Destination?

    private let presetColors: [Color] = [.indigo, .blue, .teal, .green, .orange, .pink, .purple]

    // 把所有輸入組成一個行程，金額會即時重新計算
    private var plan: TripPlan {
        TripPlan(
            name: tripName.isEmpty ? "我的\(destination.name)之旅" : tripName,
            destination: destination,
            travelClass: travelClass,
            dates: dates.compactMap { Calendar.current.date(from: $0) }.sorted(),
            departTime: departTime,
            people: people,
            budgetPerPerson: budget,
            needHotel: needHotel,
            hotel: hotel,
            insurance: insurance,
            notes: notes
        )
    }

    var body: some View {
        NavigationStack {
            screenWithAlerts
                .sheet(isPresented: $showTicket) {
                    TicketView(plan: plan, themeColor: themeColor, coverImage: coverImage)
                }
        }
        .tint(themeColor)
        .fontDesign(.rounded)
        // PhotosPicker 選到照片後讀取圖片
        .onChange(of: photoItem) { _, newItem in
            loadPhoto(newItem)
        }
    }

    // MARK: - 畫面拆成幾段，讓編譯器比較好處理

    // 主要內容：封面、進度條、目前這一步
    private var mainScroll: some View {
        ScrollView {
            VStack(spacing: 20) {
                hero
                StepIndicator(current: step.rawValue,
                              titles: PlanStep.allCases.map(\.title),
                              color: themeColor)
                    .padding(.horizontal, 4)

                // 每一步的內容，切換時左右滑動
                stepContent
                    .id(step)
                    .transition(stepTransition)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(background)
        .safeAreaInset(edge: .bottom) { bottomBar }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .place: placeStep
        case .dates: datesStep
        case .people: peopleStep
        case .style: styleStep
        }
    }

    private var stepTransition: AnyTransition {
        let insertEdge: Edge = goingForward ? .trailing : .leading
        let removeEdge: Edge = goingForward ? .leading : .trailing
        return .asymmetric(
            insertion: AnyTransition.move(edge: insertEdge).combined(with: .opacity),
            removal: AnyTransition.move(edge: removeEdge).combined(with: .opacity)
        )
    }

    // 加上標題和工具列
    private var screenWithToolbar: some View {
        mainScroll
            .navigationTitle("旅行規劃小幫手")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showReset = true
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                }
            }
    }

    // 前三個 alert
    private var screenWithAlerts: some View {
        screenWithToolbar
            // alert 1：行程摘要
            .alert("行程確認 ✈️", isPresented: $showSummary) {
                Button("再改改", role: .cancel) { }
                Button("確認出發") { showTicket = true }
            } message: {
                Text(plan.summary)
            }
            // alert 2：資料沒填完
            .alert("還沒填完喔", isPresented: $showError) {
                Button("好，我去補") { }
            } message: {
                Text(errorMessage)
            }
            // alert 3：重新規劃
            .alert("要清除全部重來嗎？", isPresented: $showReset) {
                Button("取消", role: .cancel) { }
                Button("清除", role: .destructive) { reset() }
            } message: {
                Text("所有填寫的內容都會被清除。")
            }
    }

    // alert 4：目的地介紹（從 contextMenu 打開）用到的資料
    private var infoTitle: String {
        guard let place = infoDestination else { return "" }
        return place.emoji + " " + place.name
    }

    private var showInfo: Binding<Bool> {
        Binding(
            get: { infoDestination != nil },
            set: { isShowing in
                if !isShowing { infoDestination = nil }
            }
        )
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        Task {
            if let data = try? await item?.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                withAnimation { coverImage = Image(uiImage: uiImage) }
            }
        }
    }

    // MARK: - 背景：跟著目的地和主題色變化的漸層
    private var background: some View {
        let d = destination.color
        let t = themeColor
        let b = Color(.systemBackground)

        let points: [SIMD2<Float>] = [
            SIMD2(0, 0), SIMD2(0.5, 0), SIMD2(1, 0),
            SIMD2(0, 0.45), SIMD2(0.6, 0.5), SIMD2(1, 0.4),
            SIMD2(0, 1), SIMD2(0.5, 1), SIMD2(1, 1)
        ]
        let colors: [Color] = [
            d.opacity(0.55), d.opacity(0.3), t.opacity(0.45),
            b, t.opacity(0.15), d.opacity(0.2),
            b, b, t.opacity(0.25)
        ]

        return MeshGradient(width: 3, height: 3, points: points, colors: colors)
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.6), value: destination)
        .animation(.easeInOut(duration: 0.6), value: themeColor)
    }

    // MARK: - 封面
    private var hero: some View {
        ZStack {
            Group {
                if let coverImage {
                    coverImage
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(colors: [destination.color, themeColor],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .overlay(alignment: .trailing) {
                            Text(destination.emoji)
                                .font(.system(size: 130))
                                .opacity(0.3)
                                .rotationEffect(.degrees(-12))
                                .offset(x: 20)
                        }
                }
            }
            .frame(height: 190)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(LinearGradient(colors: [.black.opacity(0.05), .black.opacity(0.5)],
                                    startPoint: .top, endPoint: .bottom))

            VStack(alignment: .leading, spacing: 8) {
                // 航線
                HStack(spacing: 8) {
                    Text("TPE")
                    Line()
                        .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                        .frame(width: 40, height: 1)
                    Image(systemName: "airplane")
                        .symbolEffect(.bounce, value: destination)
                    Line()
                        .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                        .frame(width: 40, height: 1)
                    Text(destination.code)
                        .contentTransition(.numericText())
                }
                .font(.headline.weight(.heavy))

                Spacer()

                Text(plan.name)
                    .font(.largeTitle.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Label(plan.days > 0 ? "\(plan.dateText) · \(plan.days) 天 \(plan.nights) 夜" : "還沒選日期",
                      systemImage: "calendar")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(.white)
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: destination.color.opacity(0.35), radius: 18, y: 10)
        .animation(.easeInOut(duration: 0.4), value: destination)
    }

    // MARK: - 步驟 1：名稱、目的地、交通
    private var placeStep: some View {
        placeStepContent
            .alert(infoTitle, isPresented: showInfo, presenting: infoDestination) { (place: Destination) in
                Button("就去這裡！") { destination = place }
                Button("再看看", role: .cancel) { }
            } message: { (place: Destination) in
                Text(place.intro)
            }
    }

    private var placeStepContent: some View {
        VStack(spacing: 16) {
            StepHeader(title: "要去哪裡？",
                       subtitle: "選一個目的地，長按可以看介紹",
                       icon: "globe.asia.australia.fill",
                       color: themeColor)

            // TextField
            VStack(alignment: .leading, spacing: 10) {
                CardTitle(title: "旅行名稱", icon: "pencil.line", color: themeColor)
                TextField("例如：畢業旅行、閨蜜小旅行", text: $tripName)
                    .padding(14)
                    .background(Color.primary.opacity(0.05),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .submitLabel(.done)
            }
            .glassCard()

            // 目的地方塊 + contextMenu
            VStack(alignment: .leading, spacing: 12) {
                CardTitle(title: "目的地", icon: "mappin.and.ellipse", color: themeColor)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                          spacing: 12) {
                    ForEach(Destination.allCases) { place in
                        DestinationTile(destination: place, isSelected: place == destination)
                            .onTapGesture { destination = place }
                            .contextMenu {
                                Button {
                                    destination = place
                                } label: {
                                    Label("設為目的地", systemImage: "checkmark.circle")
                                }
                                Button {
                                    infoDestination = place
                                } label: {
                                    Label("看介紹", systemImage: "info.circle")
                                }
                            }
                    }
                }
            }
            .glassCard()

            // Picker
            VStack(alignment: .leading, spacing: 12) {
                CardTitle(title: "交通等級", icon: "airplane.departure", color: themeColor)
                Picker("交通等級", selection: $travelClass) {
                    ForEach(TravelClass.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                Text("每人來回約 NT$ \(plan.travelCostPerPerson.formatted())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: plan.travelCostPerPerson)
            }
            .glassCard()
        }
    }

    // MARK: - 步驟 2：日期與時間
    private var datesStep: some View {
        VStack(spacing: 16) {
            StepHeader(title: "什麼時候出發？",
                       subtitle: "在月曆上點選每一天，可以複選",
                       icon: "calendar",
                       color: themeColor)

            // MultiDatePicker
            VStack(alignment: .leading, spacing: 8) {
                MultiDatePicker("出遊日期",
                                selection: $dates,
                                in: Calendar.current.startOfDay(for: .now)...)

                if !dates.isEmpty {
                    HStack {
                        Label(plan.dateText, systemImage: "calendar.badge.checkmark")
                        Spacer()
                        Text("\(plan.days) 天 \(plan.nights) 夜")
                            .bold()
                            .contentTransition(.numericText())
                    }
                    .font(.subheadline)
                    .foregroundStyle(themeColor)
                    .padding(12)
                    .background(themeColor.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring, value: dates.isEmpty)
            .glassCard()

            // DatePicker
            HStack(spacing: 12) {
                IconBadge(icon: "clock.fill", color: themeColor)
                DatePicker("第一天出發時間", selection: $departTime, displayedComponents: .hourAndMinute)
                    .font(.body.weight(.semibold))
            }
            .glassCard()
        }
    }

    // MARK: - 步驟 3：人數、預算、住宿保險
    private var peopleStep: some View {
        VStack(spacing: 16) {
            StepHeader(title: "跟誰一起去？",
                       subtitle: "設定人數、預算和住宿",
                       icon: "person.2.fill",
                       color: themeColor)

            // Stepper
            VStack(alignment: .leading, spacing: 14) {
                CardTitle(title: "旅伴人數", icon: "person.3.fill", color: themeColor)
                HStack {
                    PeopleAvatars(count: people, color: themeColor)
                    Spacer()
                    Stepper("\(people) 人", value: $people, in: 1...20)
                        .labelsHidden()
                }
                Text("一共 \(people) 人")
                    .font(.title3.bold())
                    .contentTransition(.numericText())
                    .animation(.snappy, value: people)
            }
            .glassCard()

            // Slider
            VStack(alignment: .leading, spacing: 10) {
                CardTitle(title: "每人預算", icon: "creditcard.fill", color: themeColor)
                Text("NT$ \(Int(budget).formatted())")
                    .font(.system(size: 34, weight: .bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy, value: budget)
                Slider(value: $budget, in: 5000...100000, step: 1000) {
                    Text("每人預算")
                } minimumValueLabel: {
                    Text("5千").font(.caption).foregroundStyle(.secondary)
                } maximumValueLabel: {
                    Text("10萬").font(.caption).foregroundStyle(.secondary)
                }
            }
            .glassCard()

            // Toggle + Picker
            VStack(alignment: .leading, spacing: 16) {
                OptionToggleRow(icon: "bed.double.fill",
                                title: "需要訂住宿",
                                subtitle: "兩人一間，共 \(plan.rooms) 間",
                                isOn: $needHotel.animation(.spring),
                                color: themeColor)

                if needHotel {
                    HStack {
                        Text("住宿等級")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("住宿等級", selection: $hotel) {
                            ForEach(HotelLevel.allCases) { level in
                                Label(level.rawValue, systemImage: level.symbol).tag(level)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    .padding(.leading, 52)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Divider()

                OptionToggleRow(icon: "cross.case.fill",
                                title: "加保旅平險",
                                subtitle: "每人 NT$ 500",
                                isOn: $insurance,
                                color: themeColor)
            }
            .glassCard()
        }
    }

    // MARK: - 步驟 4：顏色、封面、筆記、花費
    private var styleStep: some View {
        VStack(spacing: 16) {
            StepHeader(title: "最後一步！",
                       subtitle: "幫這趟旅行加點個人風格",
                       icon: "sparkles",
                       color: themeColor)

            // ColorPicker
            VStack(alignment: .leading, spacing: 14) {
                CardTitle(title: "行李箱顏色", icon: "suitcase.rolling.fill", color: themeColor)
                HStack(spacing: 10) {
                    ForEach(presetColors, id: \.self) { color in
                        Circle()
                            .fill(color.gradient)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .strokeBorder(.white, lineWidth: themeColor == color ? 3 : 0)
                            )
                            .shadow(color: color.opacity(0.4), radius: themeColor == color ? 6 : 0)
                            .onTapGesture {
                                withAnimation(.spring) { themeColor = color }
                            }
                    }
                    Spacer(minLength: 0)
                    ColorPicker("自訂顏色", selection: $themeColor, supportsOpacity: false)
                        .labelsHidden()
                }
            }
            .glassCard()

            // PhotosPicker
            VStack(alignment: .leading, spacing: 12) {
                CardTitle(title: "封面照片", icon: "photo.fill", color: themeColor)
                PhotosPicker(selection: $photoItem, matching: .images) {
                    HStack(spacing: 14) {
                        Group {
                            if let coverImage {
                                coverImage.resizable().scaledToFill()
                            } else {
                                Image(systemName: "photo.badge.plus")
                                    .font(.title2)
                                    .foregroundStyle(themeColor)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(themeColor.opacity(0.12))
                            }
                        }
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(coverImage == nil ? "從相簿選一張照片" : "換一張照片")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("會出現在封面和登機證上")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .glassCard()

            // TextEditor
            VStack(alignment: .leading, spacing: 12) {
                CardTitle(title: "行程筆記", icon: "note.text", color: themeColor)
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 110)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color.primary.opacity(0.05),
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    if notes.isEmpty {
                        Text("想去的景點、必吃美食、要帶的東西⋯")
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
            }
            .glassCard()

            costCard
        }
    }

    // MARK: - 花費明細
    private var costCard: some View {
        let ratio = min(Double(plan.perPerson) / budget, 1)

        return VStack(alignment: .leading, spacing: 12) {
            CardTitle(title: "花費試算", icon: "chart.bar.fill", color: themeColor)

            CostRow(icon: "airplane", title: "交通（每人）", amount: plan.travelCostPerPerson)
            CostRow(icon: "fork.knife", title: "吃喝玩樂（每人）", amount: plan.funCostPerPerson)
            CostRow(icon: "bed.double", title: "住宿（全部）", amount: plan.hotelCost)
            CostRow(icon: "cross.case", title: "旅平險（全部）", amount: plan.insuranceCost)

            Divider()

            HStack {
                Text("總花費")
                    .font(.headline)
                Spacer()
                Text("NT$ \(plan.total.formatted())")
                    .font(.headline)
                    .monospacedDigit()
            }

            ProgressView(value: ratio)
                .tint(plan.isOverBudget ? .red : .green)
                .animation(.easeInOut, value: ratio)

            Label(plan.isOverBudget ? "每人超出預算，考慮換個等級？" : "還在預算內，讚！",
                  systemImage: plan.isOverBudget ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(plan.isOverBudget ? .red : .green)
        }
        .glassCard()
    }

    // MARK: - 底部列：即時價格 + 上一步 / 下一步
    private var bottomBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("每人約")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("NT$ \(plan.perPerson.formatted())")
                    .font(.title3.bold())
                    .monospacedDigit()
                    .foregroundStyle(plan.isOverBudget ? .red : .primary)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: plan.perPerson)
            }

            Spacer()

            if step != .place {
                Button {
                    move(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .frame(width: 50, height: 50)
                        .background(.thinMaterial, in: Circle())
                }
                .transition(.scale.combined(with: .opacity))
            }

            Button {
                nextTapped()
            } label: {
                HStack(spacing: 6) {
                    Text(step == .style ? "產生行程" : "下一步")
                    Image(systemName: step == .style ? "paperplane.fill" : "chevron.right")
                        .contentTransition(.symbolEffect(.replace))
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .frame(height: 50)
                .background(themeColor.gradient, in: Capsule())
                .shadow(color: themeColor.opacity(0.4), radius: 8, y: 4)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 6)
        .background(.ultraThinMaterial)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: step)
    }

    // MARK: - 動作
    private func nextTapped() {
        switch step {
        case .place where tripName.trimmingCharacters(in: .whitespaces).isEmpty:
            errorMessage = "幫這趟旅行取個名字吧！"
            showError = true
        case .dates where dates.isEmpty:
            errorMessage = "請在月曆上至少選一天出遊日期。"
            showError = true
        case .style:
            showSummary = true
        default:
            move(by: 1)
        }
    }

    private func move(by offset: Int) {
        guard let next = PlanStep(rawValue: step.rawValue + offset) else { return }
        goingForward = offset > 0
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            step = next
        }
    }

    private func reset() {
        withAnimation(.spring) {
            tripName = ""
            destination = .tokyo
            travelClass = .standard
            dates = []
            people = 2
            budget = 30000
            needHotel = true
            hotel = .business
            insurance = false
            themeColor = .indigo
            notes = ""
            photoItem = nil
            coverImage = nil
            goingForward = false
            step = .place
        }
    }
}

#Preview {
    ContentView()
}
