import SwiftUI

struct RetirementView: View {
    @ObservedObject var player: Player
    @ObservedObject var appUIState: AppUIState

    var body: some View {
        VStack(spacing: 16) {
            Text("Retirement")
                .font(.title2.bold())
                .padding(.top)

            Text("You've retired at age \(player.age).")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("Money earned: \(player.savings)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                player.reset()
                appUIState.reset()
            } label: {
                Text("Restart")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        #if os(macOS)
        .frame(minWidth: 700, minHeight: 400)
        #endif
    }
}
