import SwiftUI

struct PowerZoneLegend: View {
    private let zones: [(name: String, color: Color)] = [
        ("Z1", .gray),
        ("Z2", .blue),
        ("Z3", .green),
        ("SS", .yellow),
        ("Z4", .orange),
        ("Z5", .red),
        ("Z6+", .purple),
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(zones, id: \.name) { zone in
                HStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(zone.color.opacity(0.6))
                        .frame(width: 12, height: 8)
                    Text(zone.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
