//
//  EntityView.swift
//  testERD
//
//  Created by Ilia Sazonov on 9/18/24.
//

import SwiftUI

enum EntityType: String, Hashable {
    case source, target, none
}

@Observable class Entity: Hashable, Identifiable {
    let name: String
    let attributes: [String]
    var position: CGPoint = CGPoint(x: 0.0, y: 0.0)
    var entityType: EntityType = .none
    var embeddings: [String: Embedding] = [:] // Property to store embeddings for the attributes

    var isSelected: Bool {
        get { entityType != .none }
    }

    var isSource: Bool {
        get {
            entityType == .source
        } set {
            entityType = newValue ? .source : .none
        }
    }

    var isTarget: Bool {
        get {
            entityType == .target
        } set {
            entityType = newValue ? .target : .none
        }
    }

    static var previewPerson: Entity {
        .init(
            name: "Person",
            attributes: ["age", "sex", "firstName", "lastName"],
            position: CGPoint(x: 100, y: 100)
        )
    }
    static var previewCar: Entity {
        .init(
            name: "Car",
            attributes: ["age", "model", "brand", "make"],
            position: CGPoint(x: 200, y: 200)
        )
    }
    static var previewFamily: Entity {
        .init(
            name: "Family",
            attributes: ["mom", "dad", "son", "daughter"],
            position: CGPoint(x: 300, y: 300)
        )
    }

    var frameSize: CGSize {
        // Assuming minWidth: 100, maxWidth: 200, minHeight: 200, maxHeight: 400
        // We'll use an average size or a fixed size within the constraints
        return CGSize(width: 75, height: 100)
    }

    init(name: String, attributes: [String], position: CGPoint = CGPoint.zero, embeddings: [String: Embedding] = [:]) {
        self.name = name
        self.attributes = attributes
        self.position = position
        self.embeddings = embeddings
    }

    static func == (lhs: Entity, rhs: Entity) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

struct EntityView: View {
    @Binding var entity: Entity
    private let cornerRadius = 20.0
    var mode: EntityType

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { // Remove spacing between header and attributes
                                                  // Header Section
            Text(entity.name)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity) // Ensure header spans the full width
                .background(
                    entity.isSelected ?
                    LinearGradient(
                        gradient: Gradient(colors: [Color.green.opacity(0.5), Color.green]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing)
                    : LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.indigo]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing)
                )

            Divider()
                .background(Color.blue)

            // Attributes Section
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(entity.attributes, id: \.self) { attribute in
                        Text(attribute)
                            .font(.subheadline) // Slightly smaller font for attributes
                            .foregroundColor(.primary)
                            .padding(.horizontal, 15)
                    }
                }
                .padding(10) // Reduce padding for a more compact look
            }

            Divider()

            VStack(alignment: .center) {
                HStack {
                    Spacer()
                    Button { toggleSelection() } label: {
                        if entity.isSelected {
                            Text("Clear") } else {
                                Text("Select")
                            }
                    }
                    Spacer()
                }
            }
            .padding()
        }
        .frame(
            minWidth: LayoutConstants.entityWidth,
            maxWidth: LayoutConstants.entityWidth,
            minHeight: LayoutConstants.entityHeight,
            maxHeight: LayoutConstants.entityHeight
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(entity.isSelected ? Color.green : Color.blue, lineWidth: 2)
                .shadow(radius: 5)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .contentShape(Rectangle())
        .onTapGesture {
            toggleSelection()
        }
    }

    func toggleSelection() {
        switch entity.entityType {
            case mode: entity.entityType = .none
            case .none: entity.entityType = mode
            default: break
        }
    }
}

// DraggableEntityView handles the drag gesture and positioning
struct DraggableEntityView: View {
    @Binding var entity: Entity
    let parentSize: CGSize
    var mode: EntityType

    @GestureState private var dragOffset = CGSize.zero

    var body: some View {
        EntityView(entity: $entity, mode: mode)
            .position(x: entity.position.x + dragOffset.width,
                      y: entity.position.y + dragOffset.height)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        // Calculate new position with boundary constraints
                        let newX = min(
                            max(entity.position.x + value.translation.width, LayoutConstants.entityWidth / 2 + LayoutConstants.padding),
                            parentSize.width - LayoutConstants.entityWidth / 2 - LayoutConstants.padding
                        )

                        let newY = min(
                            max(entity.position.y + value.translation.height, LayoutConstants.entityHeight / 2 + LayoutConstants.padding),
                            parentSize.height - LayoutConstants.entityHeight / 2 - LayoutConstants.padding
                        )

                        // Update the entity's position
                        entity.position = CGPoint(x: newX, y: newY)
                    }
            )
    }
}


#Preview {
    EntityView(entity: .constant(Entity.previewPerson), mode: .source)
        .frame(width: 200, height: 400)
}
