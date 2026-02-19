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

        }
        .padding()
    }
}

#Preview {
    JobRow(detail: jobExample)
}
