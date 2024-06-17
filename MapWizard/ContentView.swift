//
//  ContentView.swift
//  MapWizard
//
//  Created by Ilia Sazonov on 6/16/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var fileViewModel: FileViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        NavigationSplitView {
            List(fileViewModel.files, selection: $fileViewModel.selectedFile) { file in
                Text(file.fileName)
                    .tag(file)
            }
            .navigationTitle("Files")
            .toolbar {
                ToolbarItem {
                    Button(action: { fileViewModel.openFiles() }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
                ToolbarItem {
                    Button(action: showDiagram) {
                        Label("Diagram", systemImage: "brain.head.profile")
                    }
                }
            }
        } detail: {
            if let selectedFile = fileViewModel.selectedFile {
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
        openWindow(id: "file-columns")
    }
}

//struct ContentView: View {
//    @Environment(\.modelContext) private var modelContext
//    @Query private var items: [Item]
//
//    var body: some View {
//        NavigationSplitView {
//            List {
//                ForEach(items) { item in
//                    NavigationLink {
//                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
//                    } label: {
//                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
//                    }
//                }
//                .onDelete(perform: deleteItems)
//            }
//            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
//            .toolbar {
//                ToolbarItem {
//                    Button(action: addItem) {
//                        Label("Add Item", systemImage: "plus")
//                    }
//                }
//            }
//        } detail: {
//            Text("Select an item")
//        }
//    }
//
//    private func addItem() {
//        withAnimation {
//            let newItem = Item(timestamp: Date())
//            modelContext.insert(newItem)
//        }
//    }
//
//    private func deleteItems(offsets: IndexSet) {
//        withAnimation {
//            for index in offsets {
//                modelContext.delete(items[index])
//            }
//        }
//    }
//}


#Preview {
    ContentView()
        .environmentObject(FileViewModel())
        .modelContainer(for: Item.self, inMemory: true)
}
