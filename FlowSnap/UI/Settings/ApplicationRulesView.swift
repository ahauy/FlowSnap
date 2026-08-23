import SwiftUI

/// Per-app behavior rules configuration.
///
/// See spec §12 (Per-App Behavior) and §10 (Window Policy).
struct ApplicationRulesView: View {

    var body: some View {
        Form {
            // TODO: List of apps with their policies
            // TODO: Add/edit/remove rules
            // TODO: Default policy selector
            Text("Application Rules")
                .font(.title2)
        }
        .padding()
    }
}
