import Foundation
import ScreenCaptureKit
import AVFoundation
import CoreMedia
import Darwin

final class DesktopRecorder: NSObject, SCStreamOutput, SCStreamDelegate {
    private var stream: SCStream?
    private var writer: AVAssetWriter?
    private var input: AVAssetWriterInput?
    private let samples = DispatchQueue(label: "desktop.video.samples")
    private var begun = false
    private var stopping = false
    private var lastTimestamp: CMTime?

    func start(path: String) async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first else { throw NSError(domain: "Recorder", code: 1) }
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.width = display.width
        config.height = display.height
        config.minimumFrameInterval = CMTime(value: 1, timescale: 15)
        config.queueDepth = 5
        config.showsCursor = true
        let w = try AVAssetWriter(outputURL: URL(fileURLWithPath: path), fileType: .mov)
        let i = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: display.width,
            AVVideoHeightKey: display.height,
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 3_000_000]
        ])
        i.expectsMediaDataInRealTime = true
        guard w.canAdd(i) else { throw NSError(domain: "Recorder", code: 2) }
        w.add(i); writer = w; input = i
        let s = SCStream(filter: filter, configuration: config, delegate: self)
        try s.addStreamOutput(self, type: .screen, sampleHandlerQueue: samples)
        stream = s
        try await s.startCapture()
        print("CAPTURE_READY"); fflush(stdout)
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer buffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, !stopping, CMSampleBufferIsValid(buffer), CMSampleBufferGetImageBuffer(buffer) != nil,
              let writer, let input else { return }
        guard let attachments = CMSampleBufferGetSampleAttachmentsArray(buffer, createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
              let status = attachments.first?[.status] as? Int,
              status == SCFrameStatus.complete.rawValue else { return }
        let timestamp = CMSampleBufferGetPresentationTimeStamp(buffer)
        if let lastTimestamp, CMTimeCompare(timestamp, lastTimestamp) <= 0 { return }
        if !begun {
            guard writer.startWriting() else { return }
            writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(buffer))
            begun = true
        }
        if input.isReadyForMoreMediaData, input.append(buffer) { lastTimestamp = timestamp }
    }

    func stop() async {
        try? await stream?.stopCapture()
        samples.async { [self] in
            stopping = true
            guard begun, let writer, let input else { exit(2) }
            input.markAsFinished()
            writer.finishWriting {
                if writer.status == .completed { print("CAPTURE_SAVED"); exit(0) }
                fputs("Recording finalization failed\n", stderr); exit(3)
            }
        }
    }
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        fputs("Capture error: \(error)\n", stderr)
        Task { await stop() }
    }
}

let recorder = DesktopRecorder()
signal(SIGUSR1, SIG_IGN)
let stopSignal = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
stopSignal.setEventHandler { Task { await recorder.stop() } }
stopSignal.resume()
Task {
    do { try await recorder.start(path: CommandLine.arguments[1]) }
    catch { fputs("Could not start capture: \(error)\n", stderr); exit(1) }
}
dispatchMain()
