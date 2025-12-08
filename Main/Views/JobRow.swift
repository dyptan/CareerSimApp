import SwiftUI

struct JobRow: View {
    var detail: Job

    private func formattedIncome(_ dollars: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: dollars)) ?? "$\(dollars)"
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(detail.icon)
                .font(.system(size: 28))
                .frame(width: 40, height: 40)
                .background(Color(.systemGray))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(detail.id)
                .font(.headline)
            Spacer()
            if let tier = detail.companyTier {
                Text(tier.displayName)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12))
                    .foregroundStyle(.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            Text(formattedIncome(detail.income))
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.15))
                .foregroundStyle(.green)
                .clipShape(RoundedRectangle(cornerRadius: 8))

        }
        .padding()
    }
}

#Preview {
    JobRow(detail: jobExample)
}
