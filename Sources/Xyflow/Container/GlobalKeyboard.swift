#if canImport(UIKit) && canImport(GameController)
import UIKit
import GameController
import XYSystem

/// `<svelte:window onkeydown onkeyup>`: the keys of a hardware keyboard reach every flow that is on
/// screen, not only the one that has the focus. They are told by GameController, which reports the keys
/// without sending them to a view, so a flow that is not the first responder still hears them. A text
/// input that has the focus keeps its keys the way it does on the web (`isInputDOMNode`).
final class GlobalKeyboard {
    static let shared = GlobalKeyboard()

    private struct WeakFlow {
        weak var flow: SwiftFlow?
    }

    private var flows: [WeakFlow] = []
    private var observers: [NSObjectProtocol] = []

    private init() {}

    func add(_ flow: SwiftFlow) {
        flows.removeAll { $0.flow == nil || $0.flow === flow }
        flows.append(WeakFlow(flow: flow))

        if observers.isEmpty {
            let center = NotificationCenter.default
            observers = [
                center.addObserver(forName: .GCKeyboardDidConnect, object: nil, queue: .main) { [weak self] _ in
                    self?.bind()
                },
                center.addObserver(forName: .GCKeyboardDidDisconnect, object: nil, queue: .main) { [weak self] _ in
                    self?.bind()
                }
            ]
        }

        bind()
    }

    func remove(_ flow: SwiftFlow) {
        flows.removeAll { $0.flow == nil || $0.flow === flow }

        if flows.isEmpty {
            observers.forEach { NotificationCenter.default.removeObserver($0) }
            observers = []
            GCKeyboard.coalesced?.keyboardInput?.keyChangedHandler = nil
        }
    }

    /// The keyboard that is connected now is the one that is followed.
    private func bind() {
        GCKeyboard.coalesced?.keyboardInput?.keyChangedHandler = { [weak self] keyboard, button, code, pressed in
            if Thread.isMainThread {
                self?.receive(keyboard, button, code, pressed)
            } else {
                DispatchQueue.main.async { self?.receive(keyboard, button, code, pressed) }
            }
        }
    }

    private func receive(_ keyboard: GCKeyboardInput, _ button: GCControllerButtonInput, _ code: GCKeyCode, _ pressed: Bool) {
        func isDown(_ codes: GCKeyCode...) -> Bool {
            codes.contains { keyboard.button(forKeyCode: $0)?.isPressed == true }
        }

        var modifiers: EventModifiers = []
        if isDown(.leftShift, .rightShift) { modifiers.insert(.shift) }
        if isDown(.leftControl, .rightControl) { modifiers.insert(.control) }
        if isDown(.leftAlt, .rightAlt) { modifiers.insert(.alt) }
        if isDown(.leftGUI, .rightGUI) { modifiers.insert(.meta) }

        guard let event = FlowKeyEvent(usage: Int(code.rawValue), name: button.localizedName, modifiers: modifiers) else {
            return
        }

        for entry in flows {
            entry.flow?.handleGlobalKey(event, pressed: pressed)
        }
    }
}
#endif
