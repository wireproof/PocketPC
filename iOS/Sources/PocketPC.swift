import SwiftUI
import UniformTypeIdentifiers
import Darwin

@_silgen_name("qemu_init") private func qemuInit(_ argc: Int32, _ argv: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>)
@_silgen_name("qemu_main_loop") private func qemuMainLoop() -> Int32

@main struct PocketPCApp: App {
    @StateObject private var engine = Engine()
    var body: some Scene { WindowGroup { ContentView().environmentObject(engine) } }
}

struct ContentView: View {
    @EnvironmentObject var engine: Engine
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selection: PocketSection = .emulator
    @State private var importing = false
    @AppStorage("pocket.smoothDisplay") private var smoothDisplay = false

    var body: some View {
        GeometryReader { geometry in
            let rail = sizeClass == .regular && geometry.size.height > geometry.size.width
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    sectionContent.frame(maxWidth: .infinity, maxHeight: .infinity)
                    if rail { navigationRail }
                }
                if !rail { navigationBar }
            }.background(Color(uiColor: .systemBackground))
        }
        .accentColor(.blue)
        .onAppear {
            if ProcessInfo.processInfo.environment["POCKETPC_AUTOTEST"] == "1" && !engine.started {
                let testROM = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("WM6-PPC-USA-240x320.bin")
                engine.importROM(testROM); engine.start()
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.data]) { result in
            switch result { case .success(let url): engine.importROM(url); selection = .sessions
            case .failure(let error): engine.message = error.localizedDescription }
        }
    }
    @ViewBuilder private var sectionContent: some View {
        switch selection {
        case .emulator:
            NavigationView {
                VStack(spacing: 0) {
                    if let image = engine.image {
                        GeometryReader { geo in
                            Image(uiImage: image).resizable().interpolation(smoothDisplay ? .medium : .none)
                                .aspectRatio(contentMode: .fit).frame(width: geo.size.width, height: geo.size.height)
                                .contentShape(Rectangle())
                                .gesture(DragGesture(minimumDistance: 0).onEnded { value in
                                    let scale = min(geo.size.width / 240, geo.size.height / 320)
                                    guard scale > 0 else { return }
                                    let x = (value.location.x - (geo.size.width - 240 * scale) / 2) / scale
                                    let y = (value.location.y - (geo.size.height - 320 * scale) / 2) / scale
                                    if x >= 0 && x < 240 && y >= 0 && y < 320 { engine.tap(x: Int(x), y: Int(y)) }
                                })
                        }.background(Color(uiColor: .secondarySystemBackground))
                    } else {
                        Spacer()
                        Image(systemName: "iphone").font(.system(size: 45)).foregroundStyle(.secondary)
                        Text(engine.message).multilineTextAlignment(.center).foregroundStyle(.secondary).padding()
                        if !engine.started { Button("Start Windows Mobile") { engine.start() }.buttonStyle(.borderedProminent).disabled(engine.rom == nil) }
                        Spacer()
                    }
                    if engine.image != nil { Text(engine.message).font(.footnote).foregroundStyle(.secondary).padding(.vertical, 5) }
                }.navigationTitle("Emulator").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .primaryAction) { Button { importing = true } label: { Image(systemName: "plus") }.accessibilityLabel("Import ROM").disabled(engine.started) } }
            }
        case .sessions:
            NavigationView {
                List {
                    if engine.profiles.isEmpty { Text("No sessions. Select + to import a compatible Windows Mobile ROM.").foregroundStyle(.secondary) }
                    else {
                        Section("Imported ROMs") {
                            ForEach(engine.profiles, id: \.self) { url in
                                Button { engine.selectROM(url); selection = .emulator } label: {
                                    HStack { Image(systemName: "iphone"); VStack(alignment: .leading) { Text(engine.profileName(url)); if engine.rom == url { Text("Selected").font(.caption).foregroundStyle(.secondary) } }; Spacer(); if engine.rom == url { Image(systemName: "checkmark") } }
                                }.disabled(engine.started && engine.rom != url)
                            }
                        }
                        if engine.started { Text("Close and reopen the app before selecting another ROM.").font(.footnote).foregroundStyle(.secondary) }
                    }
                }.navigationTitle("Sessions").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .primaryAction) { Button { importing = true } label: { Image(systemName: "plus") }.accessibilityLabel("Import ROM").disabled(engine.started) } }
            }
        case .settings:
            NavigationView { Form { Section("Display") { Toggle("Smooth screen scaling", isOn: $smoothDisplay); Text("Turn off for crisp original pixels.").font(.footnote).foregroundStyle(.secondary) } }
                .navigationTitle("Settings").navigationBarTitleDisplayMode(.inline) }
        case .about:
            NavigationView { Form { Section("Pocket PC") { HStack { Text("Version"); Spacer(); Text("0.1.1").foregroundStyle(.secondary) }; Text("Runs compatible Windows Mobile Device Emulator images supplied by you.") }; Section("Emulation") { Text("The interpreter runs locally and may be slow. ROM compatibility, audio and saved changes are still being tested.") } }.navigationTitle("About").navigationBarTitleDisplayMode(.inline) }
        }
    }
    private var navigationRail: some View {
        VStack(spacing: 8) { ForEach(PocketSection.allCases) { item in navigationButton(item) } }
            .padding(8).background(Color(uiColor: .secondarySystemBackground), in: Capsule()).padding(.trailing, 8)
    }
    private var navigationBar: some View {
        HStack { ForEach(PocketSection.allCases) { item in navigationButton(item).frame(maxWidth: .infinity) } }
            .padding(.top, 7).padding(.bottom, 5).background(.bar)
    }
    private func navigationButton(_ item: PocketSection) -> some View {
        Button { selection = item } label: {
            VStack(spacing: 3) { Image(systemName: item.symbol).font(.system(size: 20)); if sizeClass != .regular { Text(item.rawValue).font(.caption2) } }
                .frame(minWidth: 46, minHeight: 44).foregroundStyle(selection == item ? Color.accentColor : Color.secondary)
                .background(selection == item && sizeClass == .regular ? Color(uiColor: .tertiarySystemFill) : Color.clear, in: Circle())
        }.accessibilityLabel(item.rawValue).accessibilityAddTraits(selection == item ? .isSelected : [])
    }
}

enum PocketSection: String, CaseIterable, Identifiable {
    case emulator = "Emulator", sessions = "Sessions", settings = "Settings", about = "About"
    var id: String { rawValue }
    var symbol: String { switch self { case .emulator: return "iphone"; case .sessions: return "square.stack"; case .settings: return "gearshape"; case .about: return "questionmark.circle" } }
}

final class Engine: ObservableObject {
    @Published var image: UIImage?
    @Published var message = "Import a compatible Windows Mobile Device Emulator ROM."
    @Published var rom: URL?
    @Published var started = false
    @Published var profiles: [URL] = []
    private var lastFrameSequence: UInt64?
    private let io = DispatchQueue(label: "pocketpc.control")
    private var control: Int32 = -1
    private var timer: Timer?
    private let root = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("PocketPC", isDirectory: true)
    private var frame: URL { root.appendingPathComponent("frames.bin") }
    private var storage: URL { root.appendingPathComponent((rom?.lastPathComponent ?? "missing") + ".storage") }
    private var sock: URL { FileManager.default.temporaryDirectory.appendingPathComponent("p2d.sock") }
    init() {
        refreshProfiles()
        if let name = UserDefaults.standard.string(forKey: "selectedROM"), !name.contains("/"), name.hasPrefix("import-"), name.hasSuffix(".bin") {
            let candidate = root.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: candidate.path) { rom = candidate; message = "ROM ready to start." }
        }
    }
    func refreshProfiles() {
        let entries = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
        profiles = entries.filter { $0.lastPathComponent.hasPrefix("import-") && $0.pathExtension.lowercased() == "bin" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
    func profileName(_ url: URL) -> String {
        UserDefaults.standard.string(forKey: "rom.name." + url.lastPathComponent) ?? "Imported ROM (" + String(url.deletingPathExtension().lastPathComponent.suffix(6)) + ")"
    }
    func selectROM(_ url: URL) {
        guard !started || rom == url, profiles.contains(url) else { return }
        rom = url; UserDefaults.standard.set(url.lastPathComponent, forKey: "selectedROM"); message = "ROM ready to start."
    }
    func importROM(_ url: URL) {
        do {
            let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            let target = root.appendingPathComponent("import-\(UUID().uuidString).bin")
            try FileManager.default.copyItem(at: url, to: target); rom = target; UserDefaults.standard.set(url.lastPathComponent, forKey: "rom.name." + target.lastPathComponent); UserDefaults.standard.set(target.lastPathComponent, forKey: "selectedROM"); refreshProfiles(); message = "ROM imported. Ready to start."
        } catch { message = "Import failed: \(error.localizedDescription)" }
    }
    func createFile(_ url: URL, size: Int64) throws {
        if FileManager.default.fileExists(atPath: url.path) { return }
        guard FileManager.default.createFile(atPath: url.path, contents: nil) else { throw NSError(domain: "PocketPC", code: 1) }
        let h = try FileHandle(forWritingTo: url); try h.truncate(atOffset: UInt64(size)); try h.close()
    }
    func start() {
        guard !started, let rom = rom else { return }
        do { try createFile(storage, size: 32 * 1024 * 1024); try createFile(frame, size: 64 + 1024 * 800 * 4) }
        catch { message = "Storage setup failed: \(error.localizedDescription)"; return }
        if FileManager.default.fileExists(atPath: sock.path) {
            do { try FileManager.default.removeItem(at: sock) } catch { message = "Control setup failed: \(error.localizedDescription)"; return }
        }
        do { let h = try FileHandle(forWritingTo: frame); try h.seek(toOffset: 0); try h.write(contentsOf: Data(repeating: 0, count: 64)); try h.close() } catch { message = "Display setup failed: \(error.localizedDescription)"; return }
        lastFrameSequence = nil; image = nil
        started = true; message = "Starting Windows Mobile…"
        let machine = "p2d-devemu,storage=\(storage.path),frame-file=\(frame.path)"
        let args = ["pocketpc", "-M", machine, "-m", "128M", "-bios", rom.path, "-accel", "tcg,thread=single,tb-size=32", "-display", "none", "-monitor", "none", "-serial", "none", "-S", "-qmp", "unix:\(sock.path),server=on,wait=off"]
        DispatchQueue.global(qos: .userInitiated).async {
            let strings = args.map { strdup($0) }; defer { for s in strings { free(s) } }
            NSLog("PocketPC: initializing core, socket path length %d", self.sock.path.utf8.count)
            var argv = strings + [nil]; argv.withUnsafeMutableBufferPointer { qemuInit(Int32(args.count), $0.baseAddress!) }
            NSLog("PocketPC: core initialized")
            _ = qemuMainLoop()
            NSLog("PocketPC: core loop ended")
        }
        io.async { [weak self] in self?.connect() }
        timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in self?.readFrame() }
    }
    private func connect() {
        let deadline = Date().addingTimeInterval(90)
        while Date() < deadline {
            let fd = socket(AF_UNIX, SOCK_STREAM, 0)
            if fd < 0 { break }
            var addr = sockaddr_un(); addr.sun_family = sa_family_t(AF_UNIX)
            let path = sock.path.utf8CString
            if path.count > MemoryLayout.size(ofValue: addr.sun_path) { close(fd); break }
            withUnsafeMutableBytes(of: &addr.sun_path) { dest in path.withUnsafeBytes { dest.copyBytes(from: $0) } }
            let ok = withUnsafePointer(to: &addr) { $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { Darwin.connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size)) } }
            if ok == 0 {
                control = fd
                guard receiveLine() != nil, command(["execute":"qmp_capabilities"]), command(["execute":"cont"]) else { close(fd); control = -1; break }
                DispatchQueue.main.async { self.message = "Windows Mobile is starting…" }; return
            }
            close(fd); Thread.sleep(forTimeInterval: 0.25)
        }
        DispatchQueue.main.async { self.message = "Could not connect to the emulator." }
    }
    private func receiveLine() -> Data? {
        var data = Data(); var b: UInt8 = 0
        while data.count < 1_000_000 { let n = Darwin.read(control, &b, 1); if n != 1 { return nil }; if b == 10 { return data }; data.append(b) }
        return nil
    }
    private func command(_ value: [String: Any]) -> Bool {
        guard control >= 0, var data = try? JSONSerialization.data(withJSONObject: value) else { return false }
        data.append(10); let sent = data.withUnsafeBytes { Darwin.write(control, $0.baseAddress!, data.count) }; guard sent == data.count else { return false }
        while let line = receiveLine() { if let obj = (try? JSONSerialization.jsonObject(with: line)) as? [String: Any] { if obj["return"] != nil { return true }; if obj["error"] != nil { return false } } }; return false
    }
    func tap(x: Int, y: Int) { io.async {
        let events: [[String: Any]] = [["type":"abs","data":["axis":"x","value":x * 32767 / 239]], ["type":"abs","data":["axis":"y","value":y * 32767 / 319]], ["type":"btn","data":["button":"left","down":true]]]
        _ = self.command(["execute":"input-send-event","arguments":["events":events]])
        _ = self.command(["execute":"input-send-event","arguments":["events":[["type":"btn","data":["button":"left","down":false]]]]])
    } }
    private func readFrame() {
        guard let handle = try? FileHandle(forReadingFrom: frame) else { return }
        defer { try? handle.close() }
        guard let header = try? handle.read(upToCount: 64), header.count == 64, header.prefix(4) == Data("P2DF".utf8) else { return }
        func number(_ bytes: Data, _ i: Int, _ count: Int) -> UInt64 { bytes[i..<i+count].enumerated().reduce(0) { $0 | UInt64($1.element) << ($1.offset * 8) } }
        let w = Int(number(header, 8, 4)), h = Int(number(header, 12, 4)), sequence = number(header, 24, 8)
        guard w > 0, h > 0, w <= 1024, h <= 800, sequence != lastFrameSequence,
              let data = try? handle.read(upToCount: w*h*4), data.count == w*h*4 else { return }
        lastFrameSequence = sequence
        let pixels = data as CFData
        guard let provider = CGDataProvider(data: pixels), let cg = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w*4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue), provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else { return }
        image = UIImage(cgImage: cg); message = "Windows Mobile running"
    }
}
