import SwiftUI

struct DecisionView: View {
    @ObservedObject var appUIState: AppUIState

    var body: some View {
        VStack(spacing: 18) {
            Text(appUIState.decisionText)
                .font(.title2)
                .padding()

            Button {
                appUIState.showDecisionSheet = false
                appUIState.showTertiarySheet = true
            } label: {
                Text("Enter College / University")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                appUIState.showDecisionSheet = false
                appUIState.showCareersSheet = true
            } label: {
                Text("Find a Job")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
