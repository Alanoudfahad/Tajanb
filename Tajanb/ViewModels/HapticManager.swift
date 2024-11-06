//
//  HapticManager.swift
//  Tajanb
//
//  Created by Afrah Saleh on 17/04/1446 AH.
//

import CoreHaptics

// HapticManager handles haptic feedback using CoreHaptics.
class HapticManager {
    private var hapticEngine: CHHapticEngine?  // CoreHaptics engine for managing haptic feedback
    private var hapticsCooldownActive = false  // Tracks cooldown status to avoid frequent haptic triggers
    private var hapticsCooldownTimer: Timer?  // Timer for managing cooldown period between haptics

    // Initialize and prepare the haptic engine
    init() {
        prepareHapticEngine()
    }

    // Prepare the haptic engine for use, checking for device support
    private func prepareHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Haptics are not supported on this device.")
            return
        }

        do {
            // Initialize and start the haptic engine
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Failed to start haptic engine: \(error)")
        }
    }

    // Perform a continuous haptic feedback with a specified intensity, sharpness, and duration
    func performHapticFeedback() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        // Prevent haptic feedback if cooldown is active
        guard !hapticsCooldownActive else { return }

        // Define haptic feedback parameters: intensity, sharpness, and duration
        var events = [CHHapticEvent]()
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4)  // Medium intensity
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)  // Medium sharpness
        let duration: TimeInterval = 1.0  // 1-second haptic feedback duration

        // Create a continuous haptic event with defined parameters
        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0, duration: duration)
        events.append(event)

        do {
            // Create a haptic pattern from the events and play it using the haptic engine
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)

            // Activate cooldown to prevent multiple rapid haptic triggers
            hapticsCooldownActive = true
            hapticsCooldownTimer?.invalidate()  // Reset any existing timer
            hapticsCooldownTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
                self?.hapticsCooldownActive = false  // Reset cooldown after 1.5 seconds
            }
        } catch {
            print("Failed to perform haptic feedback: \(error)")
        }
    }
}
