//
//  ERDViewModel.swift
//  MapWizard
//
//  Created by Ilia Sazonov on 9/19/24.
//

import SwiftUI

class ERDViewModel: ObservableObject {
    @Published var entities: [Entity] = []
    @Published var recommendationThreshold: Double = 0.9
    @Published var path: NavigationPath = .init()

    // Flag to ensure initial arrangement happens only once
    private var isArranged = false
//    private var graphBuilder: GraphBuilder

    weak var appViewModel: AppViewModel?

    @Published var recommendations = [Recommendation]()

    func updateView(){
        self.objectWillChange.send()
    }

    init(entities: [Entity], appViewModel: AppViewModel? = nil) {
        self.entities = entities
        self.appViewModel = appViewModel
//        self.graphBuilder = GraphBuilder()
    }
    
    private init () {
        self.entities = [.previewPerson, .previewCar, .previewFamily]
//        self.graphBuilder = GraphBuilder()
        self.recommendations = Recommendation.mock()
    }
    
    func populate(from files: [FileData]) {
        self.entities.removeAll()
        for file in files {
            let entity = Entity(name: file.fileName, attributes: file.header, embeddings: file.embeddings)
            self.entities.append(entity)
        }
        path = .init()
    }
    
    static var preview: ERDViewModel { .init() }
    
    // Method to arrange entities in a grid
    func arrangeEntities(in windowSize: CGSize) {
        // Prevent rearranging if already arranged
        guard !isArranged else { return }
        isArranged = true
        
        // Define layout constants
        let entityWidth = LayoutConstants.entityWidth
        let entityHeight = LayoutConstants.entityHeight
        let horizontalSpacing = LayoutConstants.horizontalSpacing
        let verticalSpacing = LayoutConstants.verticalSpacing
        let padding = LayoutConstants.padding
        
        // Calculate the number of columns that can fit in the window
        let availableWidth = windowSize.width - (2 * padding)
        let totalEntityWidth = entityWidth + horizontalSpacing
        let columns = max(Int(availableWidth / totalEntityWidth), 1)
        
        // Iterate through entities and assign positions
        for (index, _) in entities.enumerated() {
            let row = index / columns
            let column = index % columns
            
            let xPosition = padding + (CGFloat(column) * totalEntityWidth) + (entityWidth / 2)
            let yPosition = padding + (CGFloat(row) * (entityHeight + verticalSpacing)) + (entityHeight / 2)
            
            // Ensure the entity stays within the window bounds
            let adjustedX = min(max(xPosition, entityWidth / 2 + padding), windowSize.width - (entityWidth / 2 + padding))
            let adjustedY = min(max(yPosition, entityHeight / 2 + padding), windowSize.height - (entityHeight / 2 + padding))
            
            // Update the entity's position
            DispatchQueue.main.async {
                self.entities[index].position = CGPoint(x: adjustedX, y: adjustedY)
            }
        }
    }

    func clearSelection(for entityType: EntityType) {
        for entity in entities {
            if entity.entityType == entityType {
                entity.entityType = .none
            }
        }
    }
    
    func clearMarked(as entityType: EntityType) {
        for entity in entities {
            if entity.entityType == entityType {
                entity.entityType = .none
            }
        }
    }
    
    func isValidSelection(of selectionType: EntityType) -> Bool {
        print("selectionType: \(selectionType)")
        print("entities: \(entities.map(\.entityType))")
        switch selectionType {
            case .none: return true
            case .source: return entities.count(where: {$0.entityType == .source}) > 0
            case .target: return entities.count(where: {$0.entityType == .target}) == 1
        }
    }

    func generateRecommendations() async {
        var localRecommendations = [Recommendation]()
        let tgt = entities.filter({$0.entityType == .target})[0]
        for src in entities.filter({$0.entityType == .source}) {
            for sourceAttribute in src.attributes {
                for targetAttribute in tgt.attributes {
                    let sourceEmbedding = src.embeddings[sourceAttribute]
                    let targetEmbedding = tgt.embeddings[targetAttribute]
                    if let similarity = cosineSimilarity(sourceEmbedding, targetEmbedding) {
                        if similarity >= recommendationThreshold {
//                            graphBuilder.addNode("\(src.name).\(sourceAttribute)")
//                            graphBuilder.addNode("\(tgt.name).\(targetAttribute)")
//                            graphBuilder.addEdge(from: "\(src.name).\(sourceAttribute)", to: "\(tgt.name).\(targetAttribute)", value: similarity)

                            localRecommendations.append(
                                Recommendation(
                                    sourceName: src.name,
                                    targetName: tgt.name,
                                    sourceAttribute: sourceAttribute,
                                    targetAttribute: targetAttribute,
                                    score: similarity
                                )
                            )
                            logger.debug("\(src.name).\(sourceAttribute) and \(tgt.name).\(targetAttribute) look similar: \(similarity)")
                        }
                    }
                }
            }
        }

        await MainActor.run { [localRecommendations] in
            print("local recommendations: \(localRecommendations.count)")
            recommendations = localRecommendations
            updateView()
        }
    }

    // returns a graphviz object to MapViewGraphViz view
//    func getGraph() -> GraphBuilder {
//        print("node count: \(graphBuilder.dot.nodes.count)")
//        print("edge count: \(graphBuilder.dot.edges.count)")
//        return graphBuilder
//    }
}



struct Recommendation: Identifiable {
    let id = UUID()
    let sourceName: String
    let targetName: String
    let sourceAttribute: String
    let targetAttribute: String
    let score: Double
    var isSelected: Bool = false

    static func mock() -> [Recommendation] {
        var results = [Recommendation]()
        for i in 0..<10 {
            let r = Recommendation(
                    sourceName: "Source \(i)",
                    targetName: "Target \(i)",
                    sourceAttribute: "Source Attribute \(i)",
                    targetAttribute: "Target Attribute \(i)",
                    score: Double.random(in: 0..<100)
                )
            results.append(r)
        }
        return results
    }
}
