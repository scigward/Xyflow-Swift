#if canImport(UIKit)
import UIKit
import XYSystem

extension UITextField: FlowTextInput {}
extension UITextView: FlowTextInput {}

/// `KeyHandler.svelte`: follows the keys of the shortcuts of the flow, which are the selection, the
/// multi selection, the delete, the pan activation and the zoom activation key.
final class KeyHandler {
    private let store: SwiftFlowStore

    var selectionKey: KeyDefinitions = "Shift"
    var multiSelectionKey: KeyDefinitions = KeyHandler.platformKey
    var deleteKey: KeyDefinitions = "Backspace"
    var panActivationKey: KeyDefinitions = " "
    var zoomActivationKey: KeyDefinitions = KeyHandler.platformKey

    /// `isMacOs() ? 'Meta' : 'Control'`
    static var platformKey: KeyDefinitions {
        isMacOs() ? "Meta" : "Control"
    }

    init(store: SwiftFlowStore) {
        self.store = store
    }

    private func trigger(_ keys: KeyDefinitions, _ event: FlowKeyEvent, _ callback: () -> Void) {
        for definition in keys.definitions where definition.matches(event) {
            callback()
        }
    }

    func keyDown(_ event: FlowKeyEvent) {
        trigger(selectionKey, event) { store.selectionKeyPressed.set(true) }
        trigger(multiSelectionKey, event) { store.multiselectionKeyPressed.set(true) }
        trigger(deleteKey, event) {
            let isModifierKey = event.ctrlKey || event.metaKey || event.shiftKey
            if !isModifierKey && !isInputDOMNode(event) {
                store.deleteKeyPressed.set(true)
            }
        }
        trigger(panActivationKey, event) { store.panActivationKeyPressed.set(true) }
        trigger(zoomActivationKey, event) { store.zoomActivationKeyPressed.set(true) }
    }

    func keyUp(_ event: FlowKeyEvent) {
        trigger(selectionKey, event) { store.selectionKeyPressed.set(false) }
        trigger(multiSelectionKey, event) { store.multiselectionKeyPressed.set(false) }
        trigger(deleteKey, event) { store.deleteKeyPressed.set(false) }
        trigger(panActivationKey, event) { store.panActivationKeyPressed.set(false) }
        trigger(zoomActivationKey, event) { store.zoomActivationKeyPressed.set(false) }
    }

    /// The window lost the focus, or a context menu opened: no key is held any more.
    func resetKeysAndSelection() {
        store.selectionRect.set(nil)
        store.selectionKeyPressed.set(false)
        store.multiselectionKeyPressed.set(false)
        store.deleteKeyPressed.set(false)
        store.panActivationKeyPressed.set(false)
        store.zoomActivationKeyPressed.set(false)
    }
}

extension FlowKeyEvent {
    /// A hardware key as the event of a browser would describe it.
    init?(key: UIKey, isRepeat: Bool = false, target: AnyObject? = nil) {
        var modifiers: EventModifiers = []
        let flags = key.modifierFlags
        if flags.contains(.shift) { modifiers.insert(.shift) }
        if flags.contains(.control) { modifiers.insert(.control) }
        if flags.contains(.alternate) { modifiers.insert(.alt) }
        if flags.contains(.command) { modifiers.insert(.meta) }

        let named = FlowKeyEvent.names[key.keyCode]
        let name: String
        if let named {
            name = named.key
        } else if modifiers.isDisjoint(with: [.control, .alt, .meta]) {
            name = key.characters
        } else {
            name = key.charactersIgnoringModifiers
        }

        if name.isEmpty { return nil }

        self.init(
            key: name,
            code: named?.code ?? "",
            modifiers: modifiers,
            isRepeat: isRepeat,
            target: target)
    }

    private static let names: [UIKeyboardHIDUsage: (key: String, code: String)] = [
        .keyboardLeftShift: ("Shift", "ShiftLeft"),
        .keyboardRightShift: ("Shift", "ShiftRight"),
        .keyboardLeftControl: ("Control", "ControlLeft"),
        .keyboardRightControl: ("Control", "ControlRight"),
        .keyboardLeftAlt: ("Alt", "AltLeft"),
        .keyboardRightAlt: ("Alt", "AltRight"),
        .keyboardLeftGUI: ("Meta", "MetaLeft"),
        .keyboardRightGUI: ("Meta", "MetaRight"),
        .keyboardDeleteOrBackspace: ("Backspace", "Backspace"),
        .keyboardDeleteForward: ("Delete", "Delete"),
        .keyboardEscape: ("Escape", "Escape"),
        .keyboardReturnOrEnter: ("Enter", "Enter"),
        .keypadEnter: ("Enter", "NumpadEnter"),
        .keyboardTab: ("Tab", "Tab"),
        .keyboardSpacebar: (" ", "Space"),
        .keyboardUpArrow: ("ArrowUp", "ArrowUp"),
        .keyboardDownArrow: ("ArrowDown", "ArrowDown"),
        .keyboardLeftArrow: ("ArrowLeft", "ArrowLeft"),
        .keyboardRightArrow: ("ArrowRight", "ArrowRight"),
        .keyboardHome: ("Home", "Home"),
        .keyboardEnd: ("End", "End"),
        .keyboardPageUp: ("PageUp", "PageUp"),
        .keyboardPageDown: ("PageDown", "PageDown"),
        .keyboardCapsLock: ("CapsLock", "CapsLock")
    ]
}
#endif
