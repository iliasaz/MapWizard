//
//  FileContentView.swift
//  MapWizard
//
//  Created by Ilia Sazonov on 6/16/24.
//

import SwiftUI
import AppKit

struct FileDataTableView: NSViewRepresentable {
    @ObservedObject var fileViewModel: FileViewModel

    class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource {
        var parent: FileDataTableView

        init(parent: FileDataTableView) {
            self.parent = parent
        }

        func numberOfRows(in tableView: NSTableView) -> Int {
            return parent.fileViewModel.selectedFile?.rows.count ?? 0
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard let tableColumn = tableColumn else { return nil }
            guard let fileData = parent.fileViewModel.selectedFile else { return nil }
            let columnIndex = tableView.tableColumns.firstIndex(of: tableColumn)!
            let value: String

            if row < fileData.rows.count, columnIndex < fileData.rows[row].count {
                value = fileData.rows[row][columnIndex]
            } else {
                value = ""
            }

            let textField = NSTextField()
            textField.stringValue = value
            textField.isBordered = false
            textField.backgroundColor = .clear
            textField.isEditable = false

            return textField
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let tableView = NSTableView()

        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator

        updateColumns(in: tableView)

        tableView.headerView = NSTableHeaderView()
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let tableView = nsView.documentView as? NSTableView else { return }
        updateColumns(in: tableView)
        tableView.reloadData()
    }

    private func updateColumns(in tableView: NSTableView) {
        tableView.tableColumns.forEach { tableView.removeTableColumn($0) }
        guard let fileData = fileViewModel.selectedFile else { return }
        for (index, header) in fileData.header.enumerated() {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "\(index)"))
            column.title = header
            column.width = 150
            tableView.addTableColumn(column)
        }
    }
}


struct FileContentView: View {
    @ObservedObject var fileViewModel: FileViewModel

    var body: some View {
        VStack {
            if let selectedFile = fileViewModel.selectedFile {
                FileDataTableView(fileViewModel: fileViewModel)
                    .frame(minWidth: 800, minHeight: 600)
                    .padding()
            } else {
                Text("Select a file to view its contents.")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }
}

//struct FileContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        let sampleCSVData = """
//        Name,Age,Occupation
//        Alice,30,Engineer
//        Bob,25,Designer
//        Charlie,35,Manager
//        """
//        let sampleURL = URL(fileURLWithPath: "/path/to/sample.csv")
//        try? sampleCSVData.write(to: sampleURL, atomically: true, encoding: .utf8)
//        let sampleFileData = try! FileData(url: sampleURL)
//        let fileViewModel = FileViewModel()
//        fileViewModel.files = [sampleFileData]
//        fileViewModel.selectedFile = sampleFileData
//        return FileContentView(fileViewModel: fileViewModel)
//    }
//}
