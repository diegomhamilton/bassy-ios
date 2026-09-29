import SwiftUI

struct SessionView: View {
    let audioEngine: any AudioEngineProtocol

    var body: some View {
        ContentUnavailableView {
            Label("Start a Session", systemImage: "waveform.circle")
        } description: {
            Text("Input monitoring and recording arrive in the audio foundation milestones.")
        }
        .navigationTitle("Session")
    }
}
