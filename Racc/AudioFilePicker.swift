import SwiftUI
import FilePicker

struct AudioFilePicker: View {
    @Binding var selectedFileUrl: URL?
    var buttonText: String = "Open"

    @State private var filePickerOpen = false
    @State private var filePickerFiles: [URL] = []
    
    var body: some View {
        Button {
            filePickerOpen.toggle()
        } label: {
            Image(systemName: "square.and.arrow.down")
                .frame(width: 64, height: 24)
        }
        .filePicker(
            isPresented: $filePickerOpen,
            files: $filePickerFiles,
            types: [.wav, .mp3, .aiff]
        )
        .onChange(of: filePickerFiles) { _, newFiles in
            if let firstFile = newFiles.first {
                selectedFileUrl = firstFile
            }
        }
    }
}
