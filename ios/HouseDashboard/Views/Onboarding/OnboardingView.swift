import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject var syncEngine: SyncEngine
    @EnvironmentObject var notificationScheduler: NotificationScheduler
    @StateObject private var vm = HouseViewModel()

    @State private var name = ""
    @State private var yearBuilt = ""
    @State private var zipCode = ""
    @State private var hvacType = "central"
    @State private var roofMaterial = "asphalt"
    @State private var hasFireplace = false
    @State private var hasPool = false
    @State private var hasBasement = false
    @State private var waterHeaterAge = ""

    private let hvacOptions = ["central", "heat_pump", "window_units", "none"]
    private let roofOptions = ["asphalt", "metal", "tile", "flat", "wood"]

    var body: some View {
        NavigationStack {
            Form {
                Section("About your home") {
                    TextField("Home name (e.g. Main House)", text: $name)
                    TextField("Year built", text: $yearBuilt)
                        .keyboardType(.numberPad)
                    TextField("ZIP code", text: $zipCode)
                        .keyboardType(.numberPad)
                }

                Section("Systems") {
                    Picker("HVAC type", selection: $hvacType) {
                        ForEach(hvacOptions, id: \.self) { Text($0.replacingOccurrences(of: "_", with: " ")).tag($0) }
                    }
                    Picker("Roof material", selection: $roofMaterial) {
                        ForEach(roofOptions, id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Water heater age (years)", text: $waterHeaterAge)
                        .keyboardType(.numberPad)
                }

                Section("Features") {
                    Toggle("Fireplace / chimney", isOn: $hasFireplace)
                    Toggle("Swimming pool", isOn: $hasPool)
                    Toggle("Basement or crawl space", isOn: $hasBasement)
                }

                Section {
                    Button(action: save) {
                        if vm.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Generate my maintenance plan")
                                .frame(maxWidth: .infinity)
                                .bold()
                        }
                    }
                    .disabled(name.isEmpty || vm.isLoading)
                }
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func save() {
        let house = HouseModel(
            name: name,
            yearBuilt: Int(yearBuilt),
            zipCode: zipCode.isEmpty ? nil : zipCode,
            hvacType: hvacType,
            roofMaterial: roofMaterial,
            hasFireplace: hasFireplace,
            hasPool: hasPool,
            hasBasement: hasBasement,
            waterHeaterAge: Int(waterHeaterAge)
        )
        Task {
            await vm.createHouse(
                house,
                context: context,
                syncEngine: syncEngine,
                notificationScheduler: notificationScheduler
            )
        }
    }
}
