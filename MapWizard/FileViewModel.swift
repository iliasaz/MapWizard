//
//  FileVM.swift
//  MapWizard
//
//  Created by Ilia Sazonov on 6/16/24.
//

import Foundation
import SwiftUI
import NaturalLanguage


struct FileData: Identifiable, Hashable {
    let id: UUID
    let url: URL
    let content: String
    let fileName: String
    let header: [String]
    let rows: [[String]]
    var embeddings: [String: [Double]] = [:] // Property to store embeddings
    var mappedColumns: [String: Color] = [:] // Property to store mapped columns and their respective color

    init(url: URL) throws {
        self.id = UUID()
        self.url = url
        self.content = try String(contentsOf: url, encoding: .utf8)
        self.fileName = url.lastPathComponent
        let parsed = Self.parseContent(content)
        self.header = parsed.header
        self.rows = parsed.rows
    }

    static func parseContent(_ content: String) -> (header: [String], rows: [[String]]) {
        // Handle various line endings
        let lines = content.replacingOccurrences(of: "\r\n", with: "\n")
                           .replacingOccurrences(of: "\r", with: "\n")
                           .split(separator: "\n").map { String($0) }

        guard let firstLine = lines.first else {
            return ([], [])
        }

        // Determine delimiter (comma or tab)
        let delimiter = firstLine.contains("\t") ? "\t" : ","

        let header = firstLine.split(separator: Character(delimiter), omittingEmptySubsequences: false).map { String($0) }
        let rows = lines.dropFirst().map { line in
            line.split(separator: Character(delimiter), omittingEmptySubsequences: false).map { String($0) }
        }

        return (header, rows)
    }

    func computeEmbeddings() -> [String: [Double]] {
        var lcoalEmbeddings: [String: [Double]] = [:]
        guard let embedding = NLEmbedding.sentenceEmbedding(for: .english) else {
            print("Failed to load embedding model")
            return lcoalEmbeddings
        }

        for column in header {
            let concatenatedColumnData = rows.compactMap { row in
                if let index = header.firstIndex(of: column), index < row.count {
                    return row[index]
                }
                return nil
            }.joined(separator: " ")

            if let embeddingVector = embedding.vector(for: concatenatedColumnData) {
                lcoalEmbeddings[column] = embeddingVector
            } else {
                lcoalEmbeddings[column] = []
            }
        }
        return lcoalEmbeddings
    }

    static func == (lhs: FileData, rhs: FileData) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class FileViewModel: ObservableObject {
    @Published var files: [FileData] = []
    @Published var selectedFile: FileData? = nil
    @Published var isComputing: Bool = false // Track if computation is ongoing

    private var distinctColors: [Color] = generateDistinctColors()

    static func generateDistinctColors(count: Int = 50) -> [Color] {
        var colors: [Color] = []

        for i in 0..<count {
            let hue = Double(i) / Double(count)
            let color = Color(hue: hue, saturation: 0.75, brightness: 0.75, opacity: 0.5)
            colors.append(color)
        }
        return colors
    }


    func openFiles() {
        if let urls = selectFiles() {
            files = urls.compactMap { url in
                do {
                    return try FileData(url: url)
                } catch {
                    print("Failed to load content of \(url.lastPathComponent): \(error)")
                    return nil
                }
            }
            if let firstFile = files.first {
                selectedFile = firstFile // Automatically select the first file
            }
        }
    }

    func computeEmbeddings() async {
        guard !files.isEmpty else { return }
        await MainActor.run {
            isComputing = true
        }
        await withTaskGroup(of: Void.self) { group in
            for index in files.indices {
                group.addTask { [weak self] in
                    guard let self = self else { return }
                    let embeddings = self.files[index].computeEmbeddings()
                    await MainActor.run {
                        self.files[index].embeddings = embeddings
                    }
                }
            }
            // wait for all embedding threads to finish
            await group.waitForAll()
            // now calculate the distances
            // mapped cols
            var mappedCols: [String: [String: Color]] = [:] // file : column : color
            for fileIndex1 in files.indices {
                for fileIndex2 in files.index(after: fileIndex1) ..< files.endIndex {
                    let file1Name = files[fileIndex1].fileName
                    let file2Name = files[fileIndex2].fileName
                    print("***************\n  \(file1Name) - \(file2Name)\n-------------")
                    for col1 in files[fileIndex1].embeddings.keys {
                        for col2 in files[fileIndex2].embeddings.keys {
                            if let v1 = files[fileIndex1].embeddings[col1], let v2 = files[fileIndex2].embeddings[col2] {
                                if let cosineDistance = cosineSimilarity(vector1: v1, vector2: v2), cosineDistance > 0.85 {
                                    print("\(col1) - \(col2) = \(cosineDistance)")
                                    if let color = mappedCols[file1Name]?[col1] ?? mappedCols[file2Name]?[col2] {
                                        mappedCols[file1Name, default: [col1:Color.gray.opacity(0.1)]][col1] = color
                                        mappedCols[file2Name, default: [col2:Color.gray.opacity(0.1)]][col2] = color
                                    } else {
                                        let randomIndex = Int.random(in: distinctColors.startIndex ..< distinctColors.endIndex)
                                        let color = distinctColors.remove(at: randomIndex)
                                        mappedCols[file1Name, default: [col1:Color.gray.opacity(0.1)]][col1] = color
                                        mappedCols[file2Name, default: [col2:Color.gray.opacity(0.1)]][col2] = color
                                    }
                                }
                            }
                        }
                    }
                }
            }
            let mappedColsReadonly = mappedCols
            await MainActor.run {
                for fileIndex in files.indices {
                    if let mapped = mappedColsReadonly[files[fileIndex].fileName] {
                        files[fileIndex].mappedColumns = mapped
                    }
                }
            }
        }
        // update the UI
        await MainActor.run {
            self.isComputing = false
        }
    }
}

func cosineSimilarity(vector1: [Double], vector2: [Double]) -> Double? {
    guard vector1.count == vector2.count else {
        print("Vectors have different dimensions: \(vector1.count), \(vector2.count)")
        return nil
    }

    let dotProduct = zip(vector1, vector2).map(*).reduce(0, +)
    let magnitude1 = sqrt(vector1.map { $0 * $0 }.reduce(0, +))
    let magnitude2 = sqrt(vector2.map { $0 * $0 }.reduce(0, +))

    guard magnitude1 != 0, magnitude2 != 0 else {
        print("One of the vectors has zero magnitude")
        return nil
    }

    return dotProduct / (magnitude1 * magnitude2)
}

func selectFiles() -> [URL]? {
    let dialog = NSOpenPanel()

    dialog.title = "Choose your files"
    dialog.showsResizeIndicator = true
    dialog.showsHiddenFiles = false
    dialog.canChooseFiles = true
    dialog.canChooseDirectories = false
    dialog.allowsMultipleSelection = true
    dialog.allowedFileTypes = ["csv", "tsv", "txt"]

    if dialog.runModal() == NSApplication.ModalResponse.OK {
        return dialog.urls
    } else {
        return nil
    }
}
