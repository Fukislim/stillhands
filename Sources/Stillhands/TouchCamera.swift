import AppKit
import AVFoundation
import CoreImage
import StillhandsCore

final class TouchCamera: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    static let folder = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Pictures/Stillhands")
    static let warmUp: TimeInterval = 1

    var onSaved: () -> Void = {}
    private let archive = PhotoArchive()
    private let queue = DispatchQueue(label: "io.github.fukislim.stillhands.camera")
    private let context = CIContext()
    private var session: AVCaptureSession?
    private var touchedAt = Date()
    private var firstFrameAt: Date?

    static func requestAccess(_ done: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async { done(granted) }
        }
    }

    static func openPrivacySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")!)
    }

    static func showPhotos() {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        NSWorkspace.shared.open(folder)
    }

    func prune() {
        let now = Date()
        queue.async { [archive] in
            let names = (try? FileManager.default.contentsOfDirectory(atPath: Self.folder.path)) ?? []
            for name in archive.expired(names, now: now) {
                try? FileManager.default.removeItem(at: Self.folder.appendingPathComponent(name))
            }
        }
    }

    func snap() {
        let now = Date()
        queue.async { [self] in
            if let stuck = session {
                guard now.timeIntervalSince(touchedAt) > 10 else { return }
                stuck.stopRunning()
                session = nil
            }
            guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized,
                  let device = Self.camera(), let input = try? AVCaptureDeviceInput(device: device) else { return }
            let s = AVCaptureSession()
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: queue)
            guard s.canAddInput(input), s.canAddOutput(output) else { return }
            s.addInput(input)
            s.addOutput(output)
            touchedAt = now
            firstFrameAt = nil
            session = s
            s.startRunning()
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let session else { return }
        let now = Date()
        let first = firstFrameAt ?? now
        firstFrameAt = first
        guard now.timeIntervalSince(first) >= Self.warmUp, let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        self.session = nil
        queue.async { session.stopRunning() }
        if save(CIImage(cvPixelBuffer: frame)) {
            DispatchQueue.main.async { self.onSaved() }
        }
    }

    private func save(_ image: CIImage) -> Bool {
        let dir = Self.folder.appendingPathComponent(archive.folderName(for: touchedAt))
        let url = dir.appendingPathComponent(archive.fileName(for: touchedAt))
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try context.writeJPEGRepresentation(of: image, to: url, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)
            return true
        } catch {
            return false
        }
    }

    private static func camera() -> AVCaptureDevice? {
        AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
            .devices.first ?? AVCaptureDevice.default(for: .video)
    }
}
