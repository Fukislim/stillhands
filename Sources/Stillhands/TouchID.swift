import Foundation
import LocalAuthentication
import StillhandsCore

final class TouchID {
    static let timeout: TimeInterval = 30
    private var context: LAContext?

    func verify(_ done: @escaping (LockSession.Verification) -> Void) {
        let ctx = LAContext()
        ctx.localizedFallbackTitle = ""
        var error: NSError?
        let usable = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if !usable && error?.code != LAError.biometryLockout.rawValue {
            done(.unavailable)
            return
        }
        context = ctx
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.timeout) { [weak ctx] in ctx?.invalidate() }
        ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "unlock your keyboard and mouse") { ok, _ in
            DispatchQueue.main.async {
                guard self.context === ctx else { return }
                self.context = nil
                done(ok ? .verified : .failed)
            }
        }
    }

    func cancel() {
        context?.invalidate()
        context = nil
    }
}
