import AppKit
import AVFoundation
import CoreImage
import StillhandsCore

final class TouchCamera: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    static let folder = URL.picturesDirectory.appending(path: "Stillhands")
    static let warmUp: TimeInterval = 1
    static let giveUp: TimeInterval = 10

    var onSaved: (Date) -> Void = { _ in }
    private let archive = PhotoArchive()
    private let queue = DispatchQueue(label: "io.github.fukislim.stillhands.camera")
    private lazy var context = CIContext()
    private var session: AVCaptureSession?
    private var touchedAt = Date()
    private var firstFrameAt: Date?

    static func requestAccess(_ done: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async { done(granted) }
        }
    }

    static func showPhotos() {
        prepareFolder()
        NSWorkspace.shared.open(folder)
    }

    private static func prepareFolder() {
        let fm = FileManager.default
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        try? fm.setAttributes([.posixPermissions: 0o700], ofItemAtPath: folder.path)
        var url = folder
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
    }

    func prune() {
        let now = Date()
        queue.async { [archive] in
            Self.prepareFolder()
            let names = (try? FileManager.default.contentsOfDirectory(atPath: Self.folder.path)) ?? []
            for name in archive.expired(names, now: now) {
                try? FileManager.default.removeItem(at: Self.folder.appending(path: name))
            }
        }
    }

    func snap() {
        let now = Date()
        queue.async { [self] in
            guard session == nil, AVCaptureDevice.authorizationStatus(for: .video) == .authorized,
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
            queue.asyncAfter(deadline: .now() + Self.giveUp) { [self] in
                guard session === s else { return }
                s.stopRunning()
                session = nil
            }
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
        if (try? save(CIImage(cvPixelBuffer: frame))) != nil {
            let takenAt = touchedAt
            DispatchQueue.main.async { self.onSaved(takenAt) }
        }
    }

    private func save(_ image: CIImage) throws {
        let dir = Self.folder.appending(path: archive.folderName(for: touchedAt))
        Self.prepareFolder()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        try context.writeJPEGRepresentation(of: image, to: dir.appending(path: archive.fileName(for: touchedAt)), colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)
    }

    private static func camera() -> AVCaptureDevice? {
        AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
            .devices.first ?? AVCaptureDevice.default(for: .video)
    }
}
