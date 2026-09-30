import Foundation
import LocalAuthentication

final class TouchID {
    enum Outcome { case verified, unavailable, failed }

    static let timeout: TimeInterval = 30
    private var context: LAContext?

    func verify(_ done: @escaping (Outcome) -> Void) {
        guard context == nil else { return }
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
                self.context = nil
                done(ok ? .verified : .failed)
            }
        }
    }

    func cancel() {
        context?.invalidate()
    }
}
