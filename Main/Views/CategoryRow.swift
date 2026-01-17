import SwiftUI

struct CategoryRow: View, Hashable {
    var category: JobCategory
    var body: some View {
        HStack(spacing: 12) {
            Text(JobCategory.icon(for: category))
                .font(.system(size: 22))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                Text(category.examples)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .tag(Optional(category))
    }
}

#Preview {
    CategoryRow(category: JobCategory.design)
}
