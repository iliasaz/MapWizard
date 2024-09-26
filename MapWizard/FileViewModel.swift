//
//  FileVM.swift
//  MapWizard
//
//  Created by Ilia Sazonov on 6/16/24.
//

import Foundation
import SwiftUI
import NaturalLanguage
import OSLog

let logger = Logger(subsystem: "com.mapwizard", category: "FileVM")

struct Embedding {
    let vector: [Double]
    let magnitude: Double

    init(vector: [Double]) {
        self.vector = vector
        let magnitude = vector.map { $0 * $0 }.reduce(0.0, +)
        self.magnitude = magnitude.squareRoot()
    }
}

struct FileData: Identifiable, Hashable {
    let id: UUID
    let url: URL
    let content: String
    let fileName: String
    let header: [String]
    let rows: [[String]]
    var embeddings: [String: Embedding] = [:] // Property to store embeddings
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

    func computeEmbeddings() -> [String: Embedding] {
        var localEmbeddings: [String: Embedding] = [:]
        guard let embedding = NLEmbedding.sentenceEmbedding(for: .english) else {
            logger.error("Failed to load embedding model")
            return localEmbeddings
        }

        for column in header {
            let concatenatedColumnData = rows.shuffled().prefix(10).compactMap { row in
                if let index = header.firstIndex(of: column), index < row.count {
                    return row[index]
                }
                return nil
            }.joined(separator: ",")

            if let embeddingVector = embedding.vector(for: concatenatedColumnData), embeddingVector.count > 0 {
                localEmbeddings[column] = Embedding(vector: embeddingVector)
            } else {
                logger.error("failed to compute an embedding vector for \(concatenatedColumnData)")
                localEmbeddings[column] = Embedding(vector: [])
            }
        }
        return localEmbeddings
    }

    static func == (lhs: FileData, rhs: FileData) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@Observable class FileViewModel {
    var files: [FileData] = []
    var selectedFile: FileData? = nil
    var isComputing: Bool = false // Track if computation is ongoing

    weak var appViewModel: AppViewModel?

    init(appViewModel: AppViewModel? = nil) {
        self.appViewModel = appViewModel
    }

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
                    logger.error("Failed to load content of \(url.lastPathComponent): \(error)")
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
//        await MainActor.run {
//            isComputing = true
//        }
        logger.debug("starting the task group")
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
            logger.debug("fnished embedding computation in the task group")

            // now calculate the distances
            // mapped cols
//            var mappedCols: [String: [String: Color]] = [:] // file : column : color
//            for fileIndex1 in files.indices {
//                for fileIndex2 in files.index(after: fileIndex1) ..< files.endIndex {
//                    let file1Name = files[fileIndex1].fileName
//                    let file2Name = files[fileIndex2].fileName
//                    logger.debug("***************\n  \(file1Name) - \(file2Name)\n-------------")
//                    for col1 in files[fileIndex1].embeddings.keys {
//                        for col2 in files[fileIndex2].embeddings.keys {
//                            if let v1 = files[fileIndex1].embeddings[col1], let v2 = files[fileIndex2].embeddings[col2] {
//                                if let cosineDistance = cosineSimilarity(vector1: v1, vector2: v2), cosineDistance > 0.89 {
//                                    logger.debug("\(col1) - \(col2) = \(cosineDistance)")
//                                    if let color = mappedCols[file1Name]?[col1] ?? mappedCols[file2Name]?[col2] {
//                                        mappedCols[file1Name, default: [col1:Color.gray.opacity(0.1)]][col1] = color
//                                        mappedCols[file2Name, default: [col2:Color.gray.opacity(0.1)]][col2] = color
//                                    } else {
//                                        let randomIndex = Int.random(in: distinctColors.startIndex ..< distinctColors.endIndex)
//                                        let color = distinctColors.remove(at: randomIndex)
//                                        mappedCols[file1Name, default: [col1:Color.gray.opacity(0.1)]][col1] = color
//                                        mappedCols[file2Name, default: [col2:Color.gray.opacity(0.1)]][col2] = color
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//            logger.debug("fnished distance calculation")
//            let mappedColsReadonly = mappedCols
//            await MainActor.run {
//                for fileIndex in files.indices {
//                    if let mapped = mappedColsReadonly[files[fileIndex].fileName] {
//                        files[fileIndex].mappedColumns = mapped
//                    }
//                }
//            }
            logger.debug("finished updating the model")
        }
        // update the UI
        await MainActor.run {
            self.isComputing = false
        }
    }
}

func cosineSimilarity(vector1: [Double], vector2: [Double]) -> Double? {
    guard vector1.count == vector2.count else {
        logger.error("Vectors have different dimensions: \(vector1.count), \(vector2.count)")
        return nil
    }

    let dotProduct = zip(vector1, vector2).map(*).reduce(0, +)
    let magnitude1 = sqrt(vector1.map { $0 * $0 }.reduce(0, +))
    let magnitude2 = sqrt(vector2.map { $0 * $0 }.reduce(0, +))

    guard magnitude1 != 0, magnitude2 != 0 else {
        logger.error("One of the vectors has zero magnitude")
        return nil
    }

    return dotProduct / (magnitude1 * magnitude2)
}

func cosineSimilarity(_ emb1: Embedding?, _ emb2: Embedding?) -> Double? {
    guard let emb1, let emb2 else {
        logger.error("One of the embeddings is nil")
        return nil
    }
    
    guard emb1.vector.count == emb2.vector.count else {
        logger.error("Vectors have different dimensions: \(emb1.vector.count), \(emb2.vector.count)")
        return nil
    }

    guard emb1.magnitude != 0, emb2.magnitude != 0 else {
        logger.error("One of the vectors has zero magnitude")
        return nil
    }

    let dotProduct = zip(emb1.vector, emb2.vector).map(*).reduce(0.0, +)
    return dotProduct / emb1.magnitude / emb2.magnitude
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
