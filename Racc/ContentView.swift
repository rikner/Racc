//
//  ContentView.swift
//  Racc
//
//  Created by Erik Werner on 23.05.25.
//

import SwiftUI
import Controls
import FilePicker

struct ContentView: View {
    @State var modulation: Float = 0
    
    var body: some View {
        HStack {
            VStack {
                AudioFilePicker()
                
                Equalizer()

                ModWheel(value: $modulation)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                    .frame(width: 50)
            }
            
        }
        .padding()
    }
}

struct AudioFilePicker: View {
    @State var filePickerOpen = false
    
    // TODO: use one or the other publicly?
    @State var filePickerFiles: [URL] = []
    @State var fileName: String?

    var body: some View {
        VStack {
            Text(fileName ?? "Select File")
                .padding()

            Button("Select File", systemImage: "square.and.arrow.down") {
                filePickerOpen.toggle()
            }

            ForEach(filePickerFiles, id: \.self) { file in
                Text(file.lastPathComponent)
            }
        }
        .padding()
        .filePicker(
            isPresented: $filePickerOpen,
            files: $filePickerFiles,
            types: [.wav, .mp3]
        )
        .onChange(of: $filePickerFiles.wrappedValue) { newFiles in
            if let firstFile = newFiles.first {
                fileName = firstFile.lastPathComponent
            }
        }
    }
}

struct Equalizer: View {
    @State var hi: Float = 0
    @State var mid: Float = 0
    @State var lo: Float = 0
    
    var body: some View {
        VStack {
            ArcKnob("Hi", value: $hi).foregroundColor(.black)
            ArcKnob("Mid", value: $mid).foregroundColor(.black)
            ArcKnob("Lo", value: $lo).foregroundColor(.black)
        }
    }
}

#Preview {
    ContentView()
}
