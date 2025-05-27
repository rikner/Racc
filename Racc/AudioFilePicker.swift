import SwiftUI
import FilePicker

struct AudioFilePicker: View {
    @Binding var selectedFileUrl: URL? // Changed to bind a single URL
    var buttonText: String = "Open"

    @State private var filePickerOpen = false
    @State private var filePickerFiles: [URL] = [] // Still used by the .filePicker modifier

    var body: some View {
        Button {
            filePickerOpen.toggle()
        } label: {
            Image(systemName: "square.and.arrow.down")
                .frame(width: 64, height: 24)
        }
        .filePicker(
            isPresented: $filePickerOpen,
            files: $filePickerFiles, // The modifier expects a binding to an array
            types: [.wav, .mp3, .aiff] // Added more common audio types
        )
        .onChange(of: filePickerFiles) { _, newFiles in
            if let firstFile = newFiles.first {
                selectedFileUrl = firstFile
                // If you only ever want one file, clear the array after selection
                // to allow re-selection of the same file if needed by the picker.
                // Or, ensure your picker logic handles single selection appropriately.
            }
        }
    }
}
