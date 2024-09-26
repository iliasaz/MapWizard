//
//  Graphviz.swift
//  MapWizard
//
//  Created by Ilia Sazonov on 9/22/24.
//

import Foundation
import GraphViz

/// This is an experiment with displaying the column recommendations as a graph using GraphViz library

public struct HashableEdge: Equatable, CustomStringConvertible, Hashable {
    let from: String
    let to: String
    public var description: String { "from: \(from) to \(to)" }
}

class GraphBuilder {
    var dot: Graph

    init() {
        dot = Graph(directed: true)
    }

    func addNode(_ nodeName: String) {
        if dot.nodes.contains(where: {$0.id == nodeName} ) { return }
        var node = Node(nodeName)
        node[keyPath: \.label] = nodeName
        node[keyPath: \.shape] = .rectangle
        dot.append(node)
    }

    func addEdge(from fromNodeName: String, to toNodeName: String, value: Double) {
        let fromNode = dot.nodes.first(where: {$0.id == fromNodeName} )!.id
        let toNode = dot.nodes.first(where: {$0.id == toNodeName} )!.id
        var edge = Edge(from: fromNode, to: toNode, direction: .forward)
        edge[keyPath: \.weight] = value
        dot.append(edge)
    }
}
