import Observation

@MainActor @Observable
final class ToneModel {
    private let controller: any AudioGainControlling
    private(set) var input: GainConfiguration = .unity
    private(set) var output: GainConfiguration = .unity
    private(set) var isBusy = false
    private(set) var errorMessage: String?

    init(controller: any AudioGainControlling) { self.controller = controller }

    func refresh() async {
        input = await controller.gain(for: .input)
        output = await controller.gain(for: .output)
    }

    func update(_ configuration: GainConfiguration, stage: GainStage) async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil
        do { try await controller.setGain(configuration, for: stage) }
        catch { errorMessage = "Could not apply gain. The previous setting was retained." }
        await refresh()
    }
}
