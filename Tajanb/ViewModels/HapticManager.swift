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
    private var hapticsCooldownActive = false
    private var hapticsCooldownTimer: Timer?

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

        // Check if cooldown is active
        guard !hapticsCooldownActive else { return }

        // Add a continuous haptic event with a duration.
        var events = [CHHapticEvent]()
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        let duration: TimeInterval = 1.0

        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0, duration: duration)
        events.append(event)

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)

            // Start cooldown timer to prevent multiple haptic triggers
            hapticsCooldownActive = true
            hapticsCooldownTimer?.invalidate()
            hapticsCooldownTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
                self?.hapticsCooldownActive = false
            }
        } catch {
            print("Failed to perform haptic feedback: \(error)")
        }
    }
}
