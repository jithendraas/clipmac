import SwiftUI
import AppKit

struct ContentView: View {
    @State private var clipboardHistory: [ClipboardItem] = []
    @State private var memoryUsage: String = ""
    @State private var showSuccessMessage: Bool = false
    @State private var simulatedEnergyUsage: String = "Low" // Simulated Energy Usage Level

    private var macOSVersion: String {
        ProcessInfo.processInfo.operatingSystemVersionString
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerView

            if showSuccessMessage {
                successMessageView
            }

            List(clipboardHistory, id: \.id) { item in
                VStack(alignment: .leading, spacing: 5) {
                    Button(action: {
                        copyToClipboard(item)
                        showSuccessMessageWithDelay()
                    }) {
                        itemView(for: item)
                            .padding(10)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle()) // Ensures the button looks like a regular view
                }
                .padding(.vertical, 5)
                .transition(.opacity)
            }
            .padding([.leading, .trailing], 20)
            .frame(maxWidth: .infinity)

            Spacer()

            memoryUsageView
            simulatedEnergyUsageView // Simulated energy usage
        }
        .padding([.leading, .trailing], 20)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear(perform: {
            startMonitoring()
            updateMemoryUsage()
            updateSimulatedEnergyUsage()
        })
        .frame(minWidth: 400, minHeight: 600)
    }

    var headerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Clipboard History")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("macOS Version: \(macOSVersion)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
        .padding(.leading, 20)
    }

    var successMessageView: some View {
        Text("Copied to clipboard!")
            .font(.headline)
            .foregroundColor(.green)
            .transition(.opacity)
            .padding(.top, 10)
            .padding(.leading, 20)
    }

    var memoryUsageView: some View {
        Text("Memory Usage: \(memoryUsage)")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.bottom, 5)
            .onAppear(perform: updateMemoryUsage)
    }

    var simulatedEnergyUsageView: some View {
        Text("Energy Usage: \(simulatedEnergyUsage)")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.bottom, 20)
    }

    func itemView(for item: ClipboardItem) -> some View {
        switch item.type {
        case .text(let text):
            return AnyView(Text(text))
        case .image(let nsImage):
            return AnyView(
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
            )
        case .file(let filePath):
            return AnyView(
                HStack {
                    Image(systemName: "doc.fill")
                    Text("File: \(filePath.lastPathComponent)")
                }
            )
        }
    }

    func startMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            let pasteboard = NSPasteboard.general

            if let newClipboardItem = getClipboardItem(pasteboard: pasteboard),
               !clipboardHistory.contains(where: { $0.content == newClipboardItem.content }) {
                clipboardHistory.insert(newClipboardItem, at: 0)
                print("Copied: \(newClipboardItem.content)")
            }
        }
    }

    func getClipboardItem(pasteboard: NSPasteboard) -> ClipboardItem? {
        if let text = pasteboard.string(forType: .string) {
            return ClipboardItem(type: .text(text))
        } else if let imageData = pasteboard.data(forType: .tiff),
                  let image = NSImage(data: imageData) {
            return ClipboardItem(type: .image(image))
        } else if let filePaths = pasteboard.propertyList(forType: .fileURL) as? [String],
                  let filePath = filePaths.first {
            return ClipboardItem(type: .file(URL(fileURLWithPath: filePath)))
        }
        return nil
    }

    func updateMemoryUsage() {
        memoryUsage = formatMemoryUsage(getMemoryUsage())
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.updateMemoryUsage()
        }
    }

    func getMemoryUsage() -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return (result == KERN_SUCCESS) ? info.phys_footprint : 0
    }

    func formatMemoryUsage(_ memory: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(memory))
    }

    func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.type {
        case .text(let text):
            pasteboard.setString(text, forType: .string)
        case .image(let nsImage):
            if let imageData = nsImage.tiffRepresentation {
                pasteboard.setData(imageData, forType: .tiff)
            }
        case .file(let filePath):
            pasteboard.setPropertyList([filePath.path], forType: .fileURL)
        }
    }

    func showSuccessMessageWithDelay() {
        withAnimation {
            showSuccessMessage = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSuccessMessage = false
            }
        }
    }

    func updateSimulatedEnergyUsage() {
        // Placeholder logic to simulate energy usage changes
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            simulatedEnergyUsage = "Medium" // Change based on your own logic
        }
    }
}

// MARK: - Clipboard Item Model

struct ClipboardItem {
    enum ClipboardType {
        case text(String)
        case image(NSImage)
        case file(URL)
    }

    let id = UUID()
    let type: ClipboardType

    var content: String {
        switch type {
        case .text(let text):
            return text
        case .image(_):
            return "Image"
        case .file(let fileURL):
            return fileURL.path
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
