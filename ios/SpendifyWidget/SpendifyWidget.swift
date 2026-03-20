import WidgetKit
import SwiftUI

// ── Data model ────────────────────────────────────────────────────────────────

struct SpendifyEntry: TimelineEntry {
    let date: Date
    let monthSpent: String
    let monthlyBudget: String
    let budgetPct: Double
    let hasBudget: Bool
}

// ── Data provider ─────────────────────────────────────────────────────────────

struct SpendifyProvider: TimelineProvider {
    private let appGroupId = "group.com.example.spendify"

    func placeholder(in context: Context) -> SpendifyEntry {
        SpendifyEntry(date: Date(), monthSpent: "₹12,450",
                      monthlyBudget: "₹30,000", budgetPct: 0.42, hasBudget: true)
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
        let monthSpent  = prefs?.string(forKey: "month_spent")    ?? "—"
        let budget      = prefs?.string(forKey: "monthly_budget") ?? ""
        let budgetPct   = prefs?.double(forKey: "budget_pct")     ?? 0.0
        return SpendifyEntry(
            date: Date(),
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

    private let purple = Color(hex: "8552FF")
    private let orange = Color(hex: "FFB300")

    var body: some View {
        ZStack {
            // Purple card background
            RoundedRectangle(cornerRadius: 20)
                .fill(purple)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // App name
                Text("Spendify")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.75))
                    .tracking(0.5)

                Spacer().frame(height: 10)

                // Spending amount — large headline
                Text(entry.monthSpent)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer().frame(height: 4)

                // Subtitle
                Text(entry.hasBudget
                     ? "of \(entry.monthlyBudget) spent this month"
                     : "spent this month")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)

                Spacer()

                // Orange progress bar
                if entry.hasBudget {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.25))
                                .frame(height: 6)
                            Capsule()
                                .fill(orange)
                                .frame(width: geo.size.width * min(entry.budgetPct, 1.0), height: 6)
                        }
                    }
                    .frame(height: 6)
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
        .description("Your monthly spending at a glance.")
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
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
