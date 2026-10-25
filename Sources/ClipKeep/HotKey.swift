import Carbon.HIToolbox

// Carbon RegisterEventHotKey: system-wide shortcut without Accessibility permission.
final class HotKey {
    struct Combo {
        var keyCode: UInt32
        var modifiers: UInt32
        // ⌘⇧V, same as Paste. Change here to rebind.
        static let `default` = Combo(keyCode: UInt32(kVK_ANSI_V), modifiers: UInt32(cmdKey | shiftKey))
    }

    private var ref: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private let action: () -> Void

    init?(_ combo: Combo, action: @escaping () -> Void) {
        self.action = action
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let me = Unmanaged.passUnretained(self).toOpaque()
        let installed = InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            Unmanaged<HotKey>.fromOpaque(userData!).takeUnretainedValue().action()
            return noErr
        }, 1, &spec, me, &handler)
        // ponytail: one hotkey per app, so the id is a constant; give each its own id if more are added.
        let id = EventHotKeyID(signature: OSType(0x434C_4B50), id: 1) // 'CLKP'
        let registered = RegisterEventHotKey(combo.keyCode, combo.modifiers, id, GetApplicationEventTarget(), 0, &ref)
        guard installed == noErr, registered == noErr else { return nil } // e.g. combo already taken by another app
    }

    deinit {
        if let ref { UnregisterEventHotKey(ref) }
        if let handler { RemoveEventHandler(handler) }
    }
}
