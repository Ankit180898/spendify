import WidgetKit
import SwiftUI

// ── Data model ────────────────────────────────────────────────────────────────

struct SpendifyEntry: TimelineEntry {
    let date: Date
    let balance: String
    let monthSpent: String
    let monthlyBudget: String
    let budgetPct: Double
    let hasBudget: Bool
}

// ── Data provider ─────────────────────────────────────────────────────────────

struct SpendifyProvider: TimelineProvider {
    private let appGroupId = "group.com.example.spendify"

    func placeholder(in context: Context) -> SpendifyEntry {
        SpendifyEntry(date: Date(), balance: "₹25,000", monthSpent: "₹12,000",
                      monthlyBudget: "₹30,000", budgetPct: 0.4, hasBudget: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (SpendifyEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SpendifyEntry>) -> Void) {
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry()], policy: .after(nextUpdate)))
    }

    private func entry() -> SpendifyEntry {
        let prefs = UserDefaults(suiteName: appGroupId)
        let balance     = prefs?.string(forKey: "balance")       ?? "—"
        let monthSpent  = prefs?.string(forKey: "month_spent")   ?? "—"
        let budget      = prefs?.string(forKey: "monthly_budget") ?? ""
        let budgetPct   = prefs?.double(forKey: "budget_pct")    ?? 0.0
        return SpendifyEntry(
            date: Date(),
            balance: balance,
            monthSpent: monthSpent,
            monthlyBudget: budget,
            budgetPct: budgetPct,
            hasBudget: !budget.isEmpty
        )
    }
}

// ── Widget view ───────────────────────────────────────────────────────────────

struct SpendifyWidgetView: View {
    var entry: SpendifyEntry

    var budgetColor: Color {
        if entry.budgetPct >= 1.0 { return Color(hex: "FF5370") }
        if entry.budgetPct >= 0.8 { return Color(hex: "FFB300") }
        return Color(hex: "8552FF")
    }

    var body: some View {
        ZStack {
            Color(hex: "1C1B1A").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // App name
                Text("Spendify")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "8552FF"))
                    .tracking(1)

                // Balance label
                Text("Total Balance")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "908E88"))
                    .padding(.top, 6)

                // Balance value
                Text(entry.balance)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "F5F4F2"))
                    .padding(.top, 2)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Spacer()

                // Month spent row
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("This month")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "908E88"))
                    Spacer()
                    Text(entry.monthSpent)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "FF5370"))
                    if entry.hasBudget {
                        Text("/ \(entry.monthlyBudget)")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "525048"))
                    }
                }

                // Budget progress bar
                if entry.hasBudget {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 100)
                                .fill(Color(hex: "383633"))
                                .frame(height: 5)
                            RoundedRectangle(cornerRadius: 100)
                                .fill(budgetColor)
                                .frame(width: geo.size.width * entry.budgetPct, height: 5)
                        }
                    }
                    .frame(height: 5)
                    .padding(.top, 6)
                }
            }
            .padding(16)
        }
    }
}

// ── Widget config ─────────────────────────────────────────────────────────────

@main
struct SpendifyWidget: Widget {
    let kind = "SpendifyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpendifyProvider()) { entry in
            SpendifyWidgetView(entry: entry)
        }
        .configurationDisplayName("Spendify")
        .description("Your balance and monthly spending at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// ── Color hex helper ──────────────────────────────────────────────────────────

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
