//
//  RecommendationsView.swift
//  MapWizard
//
//  Created by Ilia Sazonov on 9/23/24.
//

import SwiftUI
import AppKit

struct RecommendationTableView: NSViewRepresentable {
    @ObservedObject var erdViewModel: ERDViewModel

    private let columns = ["Source", "Source Attribute", "Target", "Target Attribute", "Score"]

    class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource {
        var parent: RecommendationTableView
        var erdViewModel: ERDViewModel

        init(parent: RecommendationTableView) {
            self.parent = parent
            erdViewModel = parent.erdViewModel
        }

        func numberOfRows(in tableView: NSTableView) -> Int {
            return erdViewModel.recommendations.count
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard let tableColumn = tableColumn else { return nil }
            let value: String

            let record = erdViewModel.recommendations[row]
            switch tableColumn.identifier {
                case .init("Source"):
                    value = record.sourceName
                case .init("Source Attribute"):
                    value = record.sourceAttribute
                case .init("Target"):
                    value = record.targetName
                case .init("Target Attribute"):
                    value = record.targetAttribute
                case .init("Score"):
                    value = String(record.score)
                default:
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

        tableView.headerView = NSTableHeaderView()

        // set up columns
        for col in columns {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: col))
            column.title = col
            column.width = 150
            tableView.addTableColumn(column)
        }

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let tableView = nsView.documentView as? NSTableView else { return }
        tableView.reloadData()
    }

}

struct RecommendationsView: View {
    @ObservedObject var erdViewModel: ERDViewModel

    var body: some View {
        VStack {
            RecommendationTableView(erdViewModel: erdViewModel)
                .frame(minWidth: 800, minHeight: 600)
                .padding()
        }
    }
}

#Preview {
    RecommendationsView(erdViewModel: ERDViewModel.preview)
}
