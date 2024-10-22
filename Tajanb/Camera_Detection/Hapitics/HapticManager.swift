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

    // Perform haptic feedback.
    func performHapticFeedback() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        var events = [CHHapticEvent]()

        // Add a sharp transient haptic event (like a click).
         let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0) // Max intensity
         let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0) // Max sharpness
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
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
