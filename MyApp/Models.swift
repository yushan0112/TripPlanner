import SwiftUI

// MARK: - 目的地
enum Destination: String, CaseIterable, Identifiable {
    case tokyo, osaka, seoul, bangkok, paris, hualien

    var id: Self { self }

    var name: String {
        switch self {
        case .tokyo: "東京"
        case .osaka: "大阪"
        case .seoul: "首爾"
        case .bangkok: "曼谷"
        case .paris: "巴黎"
        case .hualien: "花蓮"
        }
    }

    var emoji: String {
        switch self {
        case .tokyo: "🗼"
        case .osaka: "🏯"
        case .seoul: "🇰🇷"
        case .bangkok: "🛕"
        case .paris: "🥐"
        case .hualien: "🌊"
        }
    }

    // 機場代碼，登機證上會用到
    var code: String {
        switch self {
        case .tokyo: "TYO"
        case .osaka: "OSA"
        case .seoul: "SEL"
        case .bangkok: "BKK"
        case .paris: "PAR"
        case .hualien: "HUN"
        }
    }

    var color: Color {
        switch self {
        case .tokyo: .pink
        case .osaka: .red
        case .seoul: .indigo
        case .bangkok: .orange
        case .paris: .purple
        case .hualien: .teal
        }
    }

    // 每人來回交通費（新台幣，粗估）
    var travelCost: Int {
        switch self {
        case .tokyo: 12000
        case .osaka: 11000
        case .seoul: 9000
        case .bangkok: 8000
        case .paris: 35000
        case .hualien: 1200
        }
    }

    // 每人每天的吃喝玩樂花費（新台幣，粗估）
    var dailyCost: Int {
        switch self {
        case .tokyo: 3000
        case .osaka: 2800
        case .seoul: 2500
        case .bangkok: 1800
        case .paris: 4500
        case .hualien: 1500
        }
    }

    var intro: String {
        switch self {
        case .tokyo: "購物、動漫、美食一次滿足，晴天還有機會看到富士山。"
        case .osaka: "日本的廚房！環球影城、道頓堀，大阪燒和章魚燒必吃。"
        case .seoul: "追星、逛街、吃炸雞，弘大和明洞永遠逛不完。"
        case .bangkok: "物價便宜、按摩超舒服，夜市和寺廟都很好拍。"
        case .paris: "浪漫之都，羅浮宮、艾菲爾鐵塔和可頌一次收集。"
        case .hualien: "不用出國的好山好水，太魯閣和七星潭都很療癒。"
        }
    }
}

// MARK: - 交通等級
enum TravelClass: String, CaseIterable, Identifiable {
    case budget = "省錢"
    case standard = "標準"
    case luxury = "豪華"

    var id: Self { self }

    var multiplier: Double {
        switch self {
        case .budget: 0.8
        case .standard: 1.0
        case .luxury: 2.5
        }
    }
}

// MARK: - 住宿等級
enum HotelLevel: String, CaseIterable, Identifiable {
    case hostel = "青年旅館"
    case business = "商務飯店"
    case resort = "五星飯店"

    var id: Self { self }

    // 每間房每晚的價格（兩人一間）
    var pricePerNight: Int {
        switch self {
        case .hostel: 1000
        case .business: 2800
        case .resort: 8000
        }
    }

    var symbol: String {
        switch self {
        case .hostel: "bed.double"
        case .business: "building.2"
        case .resort: "star.fill"
        }
    }
}

// MARK: - 一趟旅行的所有資料與花費計算
struct TripPlan {
    var name: String
    var destination: Destination
    var travelClass: TravelClass
    var dates: [Date]               // 已排序的出遊日期
    var departTime: Date
    var people: Int
    var budgetPerPerson: Double
    var needHotel: Bool
    var hotel: HotelLevel
    var insurance: Bool
    var notes: String

    var days: Int { dates.count }
    var nights: Int { max(days - 1, 0) }
    var rooms: Int { (people + 1) / 2 }

    // 每人交通費
    var travelCostPerPerson: Int {
        Int(Double(destination.travelCost) * travelClass.multiplier)
    }

    // 每人吃喝玩樂費
    var funCostPerPerson: Int { destination.dailyCost * days }

    // 住宿總費用
    var hotelCost: Int {
        needHotel ? hotel.pricePerNight * nights * rooms : 0
    }

    // 旅平險總費用（每人 500）
    var insuranceCost: Int { insurance ? 500 * people : 0 }

    var total: Int {
        (travelCostPerPerson + funCostPerPerson) * people + hotelCost + insuranceCost
    }

    var perPerson: Int { people > 0 ? total / people : 0 }

    var isOverBudget: Bool { Double(perPerson) > budgetPerPerson }

    var dateText: String {
        guard let first = dates.first, let last = dates.last else { return "未選擇" }
        let style = Date.FormatStyle.dateTime.month(.defaultDigits).day()
        if days == 1 { return first.formatted(style) }
        return "\(first.formatted(style)) – \(last.formatted(style))"
    }

    var timeText: String {
        departTime.formatted(date: .omitted, time: .shortened)
    }

    // alert 裡顯示的行程摘要
    var summary: String {
        var lines = [
            "📍 目的地：\(destination.emoji) \(destination.name)",
            "📅 日期：\(dateText)（\(days) 天 \(nights) 夜）",
            "⏰ 出發：\(timeText)",
            "👥 人數：\(people) 人",
            "🚌 交通：\(travelClass.rawValue)",
            "🏨 住宿：\(needHotel ? "\(hotel.rawValue) \(rooms) 間" : "不需要")",
            "🛡️ 旅平險：\(insurance ? "有" : "沒有")",
            "",
            "💰 總花費：NT$ \(total.formatted())",
            "🙋 每人平均：NT$ \(perPerson.formatted())"
        ]
        if isOverBudget {
            let over = perPerson - Int(budgetPerPerson)
            lines.append("⚠️ 每人超出預算 NT$ \(over.formatted())")
        } else {
            lines.append("✅ 在預算內，玩得開心！")
        }
        return lines.joined(separator: "\n")
    }
}
