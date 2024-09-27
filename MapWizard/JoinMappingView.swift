//
//  JoinMappingTableView.swift
//  MapWizard
//
//  Created by Ilia Sazonov on 9/23/24.
//

import SwiftUI
import AppKit

struct JoinMappingTableView: NSViewRepresentable {
    @ObservedObject var erdViewModel: ERDViewModel

    private let columnLabels = ["Source 1", "Attribute 1", "Source 2", "Attribute 2",  "Score", "Preferred"]
    private let columnWidths: [CGFloat] = [200, 150, 200, 150, 80, 50]
    let booleanColumnLabel = "Preferred"

    class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource {
        var parent: JoinMappingTableView
        var erdViewModel: ERDViewModel

        init(parent: JoinMappingTableView) {
            self.parent = parent
            erdViewModel = parent.erdViewModel
        }

        func numberOfRows(in tableView: NSTableView) -> Int {
            return erdViewModel.joinMapping.count
        }

        func makeTableCellViewTextField(identifier: NSUserInterfaceItemIdentifier, isPreferred: Bool = false) -> NSTableCellView {
            let text = NSTextField()
            text.isEditable = false
            text.isSelectable = true
            text.drawsBackground = false
            text.isBordered = false
            text.translatesAutoresizingMaskIntoConstraints = false
            text.preferredMaxLayoutWidth = 400
            text.font = NSFont.preferredFont(forTextStyle: .body)

            if !isPreferred {
                // Check if the text field has a font set
                if let currentFont = text.font {
                    // Convert the current font to its italic version
                    let italicFont = NSFontManager.shared.convert(currentFont, toHaveTrait: .italicFontMask)
                    text.font = italicFont
                    text.textColor = .secondaryLabelColor
                }
            }

            let cell = NSTableCellView()
            cell.textField = text
            cell.addSubview(text)
            cell.autoresizingMask = .width
            cell.identifier = identifier
            cell.clipsToBounds = true

            // bind text field to cell's objectValue, which is auto-magically populated
            // by tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? (see below)
            cell.textField?.bind(.value , to: cell, withKeyPath: "objectValue", options: nil)

            cell.addConstraint(NSLayoutConstraint(item: text, attribute: .centerY, relatedBy: .equal, toItem: cell, attribute: .centerY, multiplier: 1, constant: 0))
            cell.addConstraint(NSLayoutConstraint(item: text, attribute: .leading, relatedBy: .equal, toItem: cell, attribute: .leading, multiplier: 1, constant: 0))
            return cell
        }

        func makeTableCellViewBoolean(identifier: NSUserInterfaceItemIdentifier) -> NSView {
            let control = CheckBox()
            control.translatesAutoresizingMaskIntoConstraints = false
            control.autoresizingMask = .width
            control.identifier = identifier
            control.setButtonType(.switch)
            control.alignment = .center
            control.title = ""
            return control
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

            var cell: NSView //NSTableCellView
            guard let cellIdentifier = tableColumn?.identifier else { return nil }
            // find a cell object in cache
            let isPreferred = erdViewModel.joinMapping[row].isSelected

            switch cellIdentifier.rawValue {
                case parent.booleanColumnLabel:
                    cell = makeTableCellViewBoolean(identifier: cellIdentifier)
                default:
                    cell = makeTableCellViewTextField(identifier: cellIdentifier, isPreferred: isPreferred)
            }

            return cell
        }

        func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
            let record = erdViewModel.joinMapping[row]
            let value: Any
            switch tableColumn!.identifier.rawValue {
                case "Source 1":
                    value = record.targetName
                case "Source 2":
                    value = record.sourceName
                case "Attribute 1":
                    value = record.targetAttribute
                case "Attribute 2":
                    value = record.sourceAttribute
                case "Score":
                    value = String(format: "%.2f", record.score)
                case "Preferred":
                    value = record.isSelected
                default:
                    value = ""
            }
            return value
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
        tableView.target = context.coordinator
        tableView.headerView = NSTableHeaderView()

        tableView.intercellSpacing = NSSize(width: 5, height: 0)
        tableView.allowsMultipleSelection = true
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.style = .inset //.automatic
        tableView.usesStaticContents = false
        tableView.usesAutomaticRowHeights = false
        tableView.columnAutoresizingStyle = .sequentialColumnAutoresizingStyle

        // set up columns
        for (idx, col) in columnLabels.enumerated() {
            let column = NSTableColumn(identifier: .init(col))
            column.title = col
            column.width = columnWidths[idx]
//            column.sortDescriptorPrototype = NSSortDescriptor(key: col, ascending: true)
            column.headerCell.attributedStringValue = NSAttributedString(
                string: col,
                attributes: [
                    NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 12),
                    NSAttributedString.Key.foregroundColor: NSColor.systemBlue
                ]
            )
            tableView.addTableColumn(column)
        }

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let tableView = nsView.documentView as? NSTableView else { return }
        tableView.reloadData()
    }
}

struct JoinMappingView: View {
    @ObservedObject var erdViewModel: ERDViewModel

    var body: some View {
        JoinMappingTableView(erdViewModel: erdViewModel)
            .padding()
    }
}

extension Recommendation {
    static func joinMappingMock() -> [Recommendation] {
        var results = [Recommendation]()
        results.append(Recommendation(sourceName: "Source2", targetName: "Source1", sourceAttribute: "Source1 Attribute 0", targetAttribute: "Source2 Attribute 0", score: 0.95234523))
        results.append(Recommendation(sourceName: "Source2", targetName: "Source1", sourceAttribute: "Source1 Attribute 1", targetAttribute: "Source2 Attribute 1", score: 0.95345673457))
        results.append(Recommendation(sourceName: "Source2", targetName: "Source1", sourceAttribute: "Source2 Attribute 1", targetAttribute: "Target Attribute 1", score: 0.919872456))
        results.append(Recommendation(sourceName: "Source1", targetName: "Source1", sourceAttribute: "Source2 Attribute 2", targetAttribute: "Target Attribute 2", score: 0.954568))
        results.append(Recommendation(sourceName: "Source2", targetName: "Source1", sourceAttribute: "Source2 Attribute 2", targetAttribute: "Target Attribute 2", score: 0.9145656))
        results.append(Recommendation(sourceName: "Source2", targetName: "Source1", sourceAttribute: "A long name of a Source2 Attribute 3", targetAttribute: "A lengthy name of Target Attribute 3", score: 0.91))
        results.append(Recommendation(sourceName: "Source2", targetName: "Source1", sourceAttribute: "A long name of a Source2 Attribute 3", targetAttribute: "PARTICIPANT_ID", score: 0.97))
        results.append(Recommendation(sourceName: "Source2", targetName: "Source1", sourceAttribute: "A long name of a Source2 Attribute 3", targetAttribute: "PREGNANCY_TEST", score: 0.97))

        let localRecommendationsGrouped = Dictionary(grouping: results, by: {$0.targetAttribute}).mapValues { targetRecommendations in
            targetRecommendations.sorted(by: {$0.score > $1.score})
                .enumerated()
                .map { (idx, item) in
                    if idx == 0 {
                        var newEntity = item
                        newEntity.isSelected = true
                        return newEntity
                    } else {
                        return item
                    }
                }
        }
            .sorted(by: {$0.key.lowercased() < $1.key.lowercased()})
            .flatMap { $0.value }

        results = localRecommendationsGrouped
        return results
    }
}

#Preview {
    JoinMappingView(erdViewModel: ERDViewModel.preview)
}
