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

    weak var appViewModel: AppViewModel?

    @Published var columnMapping = [Recommendation]()
    @Published var joinMapping = [Recommendation]()

    func updateView(){
        self.objectWillChange.send()
    }

    init(entities: [Entity], appViewModel: AppViewModel? = nil) {
        self.entities = entities
        self.appViewModel = appViewModel
    }
    
    private init () {
        self.entities = [.previewPerson, .previewCar, .previewFamily]
        self.columnMapping = Recommendation.columnMappingMock()
        self.joinMapping = Recommendation.joinMappingMock()
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
        switch selectionType {
            case .none: return true
            case .source: return entities.count(where: {$0.entityType == .source}) > 0
            case .target: return entities.count(where: {$0.entityType == .target}) == 1
        }
    }

    func generateColumnMappings() async {
        var localRecommendations = [Recommendation]()
        guard let tgt = entities.filter({$0.entityType == .target}).first else { return }
        for targetAttribute in tgt.attributes {
            for src in entities.filter({$0.entityType == .source}) {
                for sourceAttribute in src.attributes {
                    let sourceEmbedding = src.embeddings[sourceAttribute]
                    let targetEmbedding = tgt.embeddings[targetAttribute]
                    if let similarity = cosineSimilarity(sourceEmbedding, targetEmbedding) {
                        if similarity >= recommendationThreshold {
                            localRecommendations.append(
                                Recommendation(
                                    sourceName: src.name,
                                    targetName: tgt.name,
                                    sourceAttribute: sourceAttribute,
                                    targetAttribute: targetAttribute,
                                    score: similarity
                                )
                            )
                        }
                    }
                }
            }
        }

        // sort the recommendations
        let localRecommendationsGrouped = Dictionary(grouping: localRecommendations, by: {$0.targetAttribute}).mapValues { targetRecommendations in
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
            .sorted(by: {$0.key.lowercased() > $1.key.lowercased()})
            .flatMap { $0.value }

        await MainActor.run { [localRecommendationsGrouped] in
            columnMapping = localRecommendationsGrouped
            updateView()
        }
    }

    func generateJoinMappings() async {
        var localRecommendations = [Recommendation]()
        for (srcIdx1, src1) in entities.filter({$0.entityType == .source}).sorted(by: {$0.name < $1.name}).enumerated() {
            for (srcIdx2, src2) in entities.filter({$0.entityType == .source}).sorted(by: {$0.name < $1.name}).enumerated() where srcIdx2 > srcIdx1 {
                for sourceAttribute1 in src1.attributes {
                    for sourceAttribute2 in src2.attributes {
                        let sourceEmbedding1 = src1.embeddings[sourceAttribute1]
                        let sourceEmbedding2 = src2.embeddings[sourceAttribute2]
                        if let similarity = cosineSimilarity(sourceEmbedding1, sourceEmbedding2) {
                            if similarity >= recommendationThreshold {
                                localRecommendations.append(
                                    Recommendation(
                                        sourceName: src2.name,
                                        targetName: src1.name,
                                        sourceAttribute: sourceAttribute2,
                                        targetAttribute: sourceAttribute1,
                                        score: similarity
                                    )
                                )
                            }
                        }
                    }
                }
            }
        }

        // sort the recommendations
        let localRecommendationsGrouped = Dictionary(grouping: localRecommendations, by: {$0.targetAttribute}).mapValues { targetRecommendations in
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
            .sorted(by: {$0.key.lowercased() > $1.key.lowercased()})
            .flatMap { $0.value }

        await MainActor.run { [localRecommendationsGrouped] in
            joinMapping = localRecommendationsGrouped
            updateView()
        }
    }
}



struct Recommendation: Identifiable {
    let id = UUID()
    let sourceName: String
    let targetName: String
    let sourceAttribute: String
    let targetAttribute: String
    let score: Double
    var isSelected: Bool = false
}
