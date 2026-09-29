import SwiftUI

struct ToneView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Shape Your Tone", systemImage: "slider.horizontal.3")
        } description: {
            Text("Instrument profiles, gain, and EQ will live here.")
        }
        .navigationTitle("Tone")
    }
}
