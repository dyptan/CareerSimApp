import SwiftUI

struct CertificationsAndLicensesView: View {
    @Binding var selectedCertifications: Set<Certification>
    @Binding var selectedLicences: Set<License>
    // Access player to read locked certifications
    @EnvironmentObject private var player: Player

    // Local radio selection (at most one). We sync this with selectedCertifications.
    @State private var selectedRadioCert: Certification?

    // Precompute sorted arrays to simplify generic inference and avoid heavy work in body
    private var sortedCertifications: [Certification] {
        Certification.allCases.sorted(by: { $0.rawValue < $1.rawValue })
    }
    private var sortedLicenses: [License] {
        License.allCases.sorted(by: { $0.rawValue < $1.rawValue })
    }

    var body: some View {
        VStack(spacing: 10) {
//            // Certifications as radio-like selection (at most one)
//            Text("Certifications:")
//
            ForEach(sortedCertifications, id: \.self) { cert in
                let isLocked = player.lockedCertifications.contains(cert)
                // Selected if this is the current radio choice
                let isSelected = selectedRadioCert == cert

                // Row acts like a radio option
                HStack {
                    // Simple radio indicator
                    Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
//                        .foregroundStyle(isLocked ? .secondary : .accentColor)
                    Text(cert.friendlyName)
                        .foregroundStyle(isLocked ? .secondary : .primary)
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !isLocked else { return }
                    if isSelected {
                        // Tapping again deselects (so “at most one”, not “exactly one”)
                        selectedRadioCert = nil
                        selectedCertifications.removeAll()
                    } else {
                        selectedRadioCert = cert
                        // Ensure only this one is in the bound set
                        selectedCertifications = [cert]
                    }
                }
                .opacity(isLocked ? 0.5 : 1.0)
                .disabled(isLocked)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(cert.friendlyName)
                .accessibilityValue(isSelected ? "Selected" : "Not selected")
                .accessibilityHint(isLocked ? "Locked after year end" : "Select to choose this certification")
            }

            // Licenses (unchanged behavior)
            Text("Licenses:")
            ForEach(sortedLicenses, id: \.self) { lic in
                let binding = Binding<Bool>(
                    get: { selectedLicences.contains(lic) },
                    set: { isSelected in
                        if isSelected {
                            selectedLicences.insert(lic)
                        } else {
                            selectedLicences.remove(lic)
                        }
                    }
                )

                let t = Toggle(displayName(for: lic), isOn: binding)
                    .frame(maxWidth: .infinity, alignment: .leading)

                #if os(macOS)
                t.toggleStyle(.checkbox)
                #endif
                #if os(iOS)
                t.toggleStyle(.switch)
                #endif
            }
        }
        // Keep local radio selection in sync with external binding
        .onAppear {
            if let current = selectedCertifications.first {
                selectedRadioCert = current
            } else {
                selectedRadioCert = nil
            }
        }
        .onChange(of: selectedCertifications) { _, newValue in
            if let first = newValue.first {
                if selectedRadioCert != first {
                    selectedRadioCert = first
                }
            } else if selectedRadioCert != nil {
                selectedRadioCert = nil
            }
        }
        .onChange(of: selectedRadioCert) { _, newSelection in
            // Keep the external set aligned with radio selection
            if let cert = newSelection {
                selectedCertifications = [cert]
            } else {
                selectedCertifications.removeAll()
            }
        }
    }

    private func displayName(for lic: License) -> String {
        switch lic {
        case .drivers:
            return "Driver’s License 🚗"
        case .pilot:
            return "Pilot License ✈️"
        case .nurse:
            return "Nurse License 🩺"
        case .electrician:
            return "Electrician License 🔌"
        case .plumber:
            return "Plumber License 🔧"
        case .cdl:
            return "Commercial Driver’s License 🚚"
        case .commercialPilot:
            return "Commercial Pilot License 🛫"
        case .realEstateAgent:
            return "Real Estate Agent License 🏠"
        case .insuranceAgent:
            return "Insurance Agent License 🛡️"
        }
    }
}

#Preview {
    @Previewable @State var certs = Set<Certification>()
    @Previewable @State var lic = Set<License>()
    return CertificationsAndLicensesView(
        selectedCertifications: $certs,
        selectedLicences: $lic
    )
    .environmentObject(Player())
    .padding()
}
