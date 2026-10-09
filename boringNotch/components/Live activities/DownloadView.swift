import AppKit
import CoreAudio
import CoreMediaIO
import Defaults
import Foundation
import SwiftUI

enum Browser { case safari, chrome, finder }

struct DownloadFile: Identifiable, Equatable {
    let id: String
    let name: String
    let size: Int64
    let formattedSize: String
    let browser: Browser
    let url: URL
}

@MainActor
final class DownloadWatcher: ObservableObject {
    static let shared = DownloadWatcher()
    @Published private(set) var downloadFiles: [DownloadFile] = []
    @Published private(set) var recentlyCompletedName: String?
    private var priorFiles: [String: DownloadFile] = [:]
    private var observedSizes: [String: Int64] = [:]
    private var completionTask: Task<Void, Never>?
    private var timer: Timer?
    private let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!

    private init() {
        scan()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.scan() }
        }
    }

    func reveal(_ download: DownloadFile) {
        NSWorkspace.shared.activateFileViewerSelecting([download.url])
    }

    private func scan() {
        guard Defaults[.enableDownloadListener] else {
            downloadFiles = []; priorFiles = [:]; return
        }
        let keys: Set<URLResourceKey> = [.fileSizeKey, .totalFileAllocatedSizeKey, .contentModificationDateKey]
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: downloadsURL, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles]
        )) ?? []
        let temporaryExtensions = ["download", "crdownload", "part"]
        let files = urls.compactMap { url -> DownloadFile? in
            let ext = url.pathExtension.lowercased()
            let values = try? url.resourceValues(forKeys: keys)
            let size = Int64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0)
            let isTemporary = temporaryExtensions.contains(ext)
            let wasObserved = observedSizes[url.path] != nil
            let isGrowing = wasObserved && observedSizes[url.path] != size
                && (values?.contentModificationDate?.timeIntervalSinceNow ?? -.infinity) > -120
            guard isTemporary || (isGrowing && size > 1_000_000) else { return nil }
            let browser: Browser = ext == "download" ? .safari
                : ext == "crdownload" ? .chrome : .finder
            return DownloadFile(
                id: url.path,
                name: url.deletingPathExtension().lastPathComponent,
                size: size,
                formattedSize: ByteCountFormatter.string(fromByteCount: size, countStyle: .file),
                browser: browser,
                url: url
            )
        }.sorted { $0.size > $1.size }
        let current = Dictionary(uniqueKeysWithValues: files.map { ($0.id, $0) })
        if let completed = priorFiles.values.first(where: { current[$0.id] == nil }) {
            recentlyCompletedName = completed.name
            completionTask?.cancel()
            completionTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(4))
                guard !Task.isCancelled else { return }
                self?.recentlyCompletedName = nil
            }
        }
        priorFiles = current
        observedSizes = Dictionary(uniqueKeysWithValues: urls.map { url in
            let values = try? url.resourceValues(forKeys: keys)
            return (url.path, Int64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0))
        })
        downloadFiles = files
    }
}

@MainActor
final class NotchTimerManager: ObservableObject {
    static let shared = NotchTimerManager()
    @Published private(set) var endDate: Date?
    @Published private(set) var remainingSeconds = 0
    @Published private(set) var label = "Timer"
    @Published private(set) var justFinished = false
    private var timer: Timer?

    private init() {}

    func start(minutes: Int, label: String? = nil) {
        self.label = label ?? "\(minutes)-minute timer"
        endDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        justFinished = false
        tick()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func cancel() {
        timer?.invalidate(); timer = nil; endDate = nil
        remainingSeconds = 0; justFinished = false
    }

    private func tick() {
        guard let endDate else { return }
        remainingSeconds = max(0, Int(endDate.timeIntervalSinceNow.rounded(.up)))
        guard remainingSeconds == 0 else { return }
        timer?.invalidate(); timer = nil; self.endDate = nil; justFinished = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            self?.justFinished = false
        }
    }
}

@MainActor
final class PrivacyActivityMonitor: ObservableObject {
    static let shared = PrivacyActivityMonitor()
    @Published private(set) var microphoneInUse = false
    @Published private(set) var cameraInUse = false
    @Published private(set) var shouldShowActivity = false
    private var timer: Timer?
    private var hideActivityTask: Task<Void, Never>?

    private init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    private func refresh() {
        guard Defaults[.privacyActivitiesEnabled] else {
            microphoneInUse = false
            cameraInUse = false
            shouldShowActivity = false
            hideActivityTask?.cancel()
            return
        }

        let newMicrophoneInUse = Self.defaultInputDeviceIsRunning()
        let newCameraInUse = Self.anyCameraIsRunning()
        let newlyActivated = (newMicrophoneInUse && !microphoneInUse)
            || (newCameraInUse && !cameraInUse)

        microphoneInUse = newMicrophoneInUse
        cameraInUse = newCameraInUse

        guard newlyActivated else { return }
        shouldShowActivity = true
        hideActivityTask?.cancel()
        hideActivityTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            self?.shouldShowActivity = false
        }
    }

    private nonisolated static func defaultInputDeviceIsRunning() -> Bool {
        var deviceID = AudioDeviceID(kAudioObjectUnknown)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID) == noErr,
              deviceID != kAudioObjectUnknown else { return false }
        address.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere
        var running: UInt32 = 0
        size = UInt32(MemoryLayout<UInt32>.size)
        return AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &running) == noErr && running != 0
    }

    private nonisolated static func anyCameraIsRunning() -> Bool {
        var address = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
        var size: UInt32 = 0
        guard CMIOObjectGetPropertyDataSize(CMIOObjectID(kCMIOObjectSystemObject), &address, 0, nil, &size) == noErr,
              size > 0 else { return false }
        var devices = [CMIODeviceID](repeating: 0, count: Int(size) / MemoryLayout<CMIODeviceID>.size)
        guard CMIOObjectGetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &address, 0, nil, size, &size, &devices) == noErr else { return false }
        for device in devices {
            var runningAddress = CMIOObjectPropertyAddress(
                mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere),
                mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
            var running: UInt32 = 0
            var runningSize = UInt32(MemoryLayout<UInt32>.size)
            if CMIOObjectGetPropertyData(CMIOObjectID(device), &runningAddress, 0, nil, runningSize, &runningSize, &running) == noErr,
               running != 0 { return true }
        }
        return false
    }
}

struct DownloadArea: View {
    @ObservedObject private var watcher = DownloadWatcher.shared
    var body: some View {
        if let download = watcher.downloadFiles.first {
            Label(download.name, systemImage: "arrow.down.circle.fill")
        }
    }
}
