//
//  ContentView.swift
//  MapWizard
//
//  Created by Ilia Sazonov on 6/16/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(FileViewModel.self) private var fileViewModel: FileViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        @Bindable var fileViewModel = fileViewModel
        NavigationSplitView {
            List(fileViewModel.files, selection: $fileViewModel.selectedFile) { file in
                Text(file.fileName)
                    .tag(file)
            }

            .navigationTitle("Files")
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        fileViewModel.openFiles()
                        Task { await fileViewModel.computeEmbeddings() }
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
                ToolbarItem {
                    Button(action: showDiagram) {
                        Label("Diagram", systemImage: "wand.and.rays")
                    }
                }
            }
        } detail: {
            if let _ = fileViewModel.selectedFile {
                FileContentView(fileViewModel: fileViewModel)
            } else {
                Text("Select a file to view its contents.")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    func showDiagram() {
        fileViewModel.appViewModel?.erdViewModel.populate(from: fileViewModel.files)
        openWindow(id: "erd")
    }
}


#Preview {
    ContentView()
        .environment(FileViewModel())
}
