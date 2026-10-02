import Foundation

/// The modifier keys that were held while an event happened.
public struct EventModifiers: OptionSet, Equatable, Hashable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let shift = EventModifiers(rawValue: 1 << 0)
    public static let control = EventModifiers(rawValue: 1 << 1)
    public static let alt = EventModifiers(rawValue: 1 << 2)
    public static let meta = EventModifiers(rawValue: 1 << 3)
}

/// A mouse or touch event, with its position in the coordinates of the window it happened in
/// (`clientX` and `clientY` of the DOM events).
public struct FlowPointerEvent {
    public enum Kind: String {
        case mouse
        case touch
    }

    public var kind: Kind
    public var clientX: Double
    public var clientY: Double
    public var modifiers: EventModifiers
    /// The mouse button that is pressed, `0` for the primary one, `2` for the secondary one.
    public var button: Int
    /// The bitmask of the buttons that are pressed (`1` primary, `2` secondary, `4` auxiliary).
    public var buttons: Int
    public var timeStamp: TimeInterval
    /// How many fingers are on the screen, for a touch event (`event.touches.length`).
    public var touchCount: Int
    /// The view the event started on, if the host knows it.
    public var target: AnyObject?
    /// The event of the platform, for a callback that wants more than this carries.
    public var native: AnyObject?

    public var shiftKey: Bool { modifiers.contains(.shift) }
    public var ctrlKey: Bool { modifiers.contains(.control) }
    public var altKey: Bool { modifiers.contains(.alt) }
    public var metaKey: Bool { modifiers.contains(.meta) }

    public init(
        kind: Kind = .mouse,
        clientX: Double,
        clientY: Double,
        modifiers: EventModifiers = [],
        button: Int = 0,
        buttons: Int = 1,
        timeStamp: TimeInterval = Date().timeIntervalSinceReferenceDate,
        touchCount: Int = 0,
        target: AnyObject? = nil,
        native: AnyObject? = nil
    ) {
        self.kind = kind
        self.clientX = clientX
        self.clientY = clientY
        self.modifiers = modifiers
        self.button = button
        self.buttons = buttons
        self.timeStamp = timeStamp
        self.touchCount = touchCount
        self.target = target
        self.native = native
    }
}

/// A key event. `key` is the value of `KeyboardEvent.key` (`"Enter"`, `"a"`, `"Shift"`, ...) and
/// `code` the one of `KeyboardEvent.code` (`"KeyA"`, `"ShiftLeft"`, ...).
public struct FlowKeyEvent {
    public var key: String
    public var code: String
    public var modifiers: EventModifiers
    public var isRepeat: Bool
    /// The view that had the focus.
    public var target: AnyObject?

    public var shiftKey: Bool { modifiers.contains(.shift) }
    public var ctrlKey: Bool { modifiers.contains(.control) }
    public var altKey: Bool { modifiers.contains(.alt) }
    public var metaKey: Bool { modifiers.contains(.meta) }

    public init(
        key: String,
        code: String = "",
        modifiers: EventModifiers = [],
        isRepeat: Bool = false,
        target: AnyObject? = nil
    ) {
        self.key = key
        self.code = code
        self.modifiers = modifiers
        self.isRepeat = isRepeat
        self.target = target
    }
}

/// A wheel event: a mouse wheel, or the scrolling of a trackpad. The deltas are the ones of
/// `WheelEvent`, in the unit `deltaMode` names.
public struct FlowWheelEvent {
    public enum DeltaMode: Int {
        case pixel = 0
        case line = 1
        case page = 2
    }

    public var clientX: Double
    public var clientY: Double
    public var deltaX: Double
    public var deltaY: Double
    public var deltaMode: DeltaMode
    public var modifiers: EventModifiers
    public var timeStamp: TimeInterval
    public var target: AnyObject?

    public var shiftKey: Bool { modifiers.contains(.shift) }
    public var ctrlKey: Bool { modifiers.contains(.control) }
    public var altKey: Bool { modifiers.contains(.alt) }
    public var metaKey: Bool { modifiers.contains(.meta) }

    public init(
        clientX: Double,
        clientY: Double,
        deltaX: Double,
        deltaY: Double,
        deltaMode: DeltaMode = .pixel,
        modifiers: EventModifiers = [],
        timeStamp: TimeInterval = Date().timeIntervalSinceReferenceDate,
        target: AnyObject? = nil
    ) {
        self.clientX = clientX
        self.clientY = clientY
        self.deltaX = deltaX
        self.deltaY = deltaY
        self.deltaMode = deltaMode
        self.modifiers = modifiers
        self.timeStamp = timeStamp
        self.target = target
    }
}
