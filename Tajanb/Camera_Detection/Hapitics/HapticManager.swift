//
//  HapticManager.swift
//  Tajanb
//
//  Created by Afrah Saleh on 17/04/1446 AH.
//

import CoreHaptics

// HapticManager handles haptic feedback using CoreHaptics.
class HapticManager {
    private var hapticEngine: CHHapticEngine?

    init() {
        prepareHapticEngine()
    }

    // Prepare the haptic engine.
    private func prepareHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Haptics are not supported on this device.")
            return
        }

        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Failed to start haptic engine: \(error)")
        }
    }

    // Perform longer haptic feedback.
    func performHapticFeedback() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        var events = [CHHapticEvent]()

        // Add a continuous haptic event with a duration.
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4) // Adjust intensity as needed.
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5) // Adjust sharpness as needed.
        let duration: TimeInterval = 1.0 // Duration of the haptic event in seconds.

        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0, duration: duration)
        events.append(event)

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to perform haptic feedback: \(error)")
        }
    }
}
