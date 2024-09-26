//
//  ERDView.swift
//  MapWizard
//
//  Created by Ilia Sazonov on 9/19/24.
//

import SwiftUI

struct ERDView: View {
    @ObservedObject var viewModel: ERDViewModel
    var body: some View {
        GeometryReader { geometry in

            ZStack {
                Color.white
                    .edgesIgnoringSafeArea(.all)

                ForEach($viewModel.entities, id: \.self) { $entity in
                    DraggableEntityView(entity: $entity, parentSize: geometry.size, mode: .none)
                }
            }
            .onAppear {
                // Arrange entities when the view appears
                viewModel.arrangeEntities(in: geometry.size)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: { Task { await viewModel.appViewModel?.fileViewModel.computeEmbeddings() }}) {
                        Label("Map it", systemImage: "brain.head.profile")
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    ERDView(viewModel: ERDViewModel.preview)
        .frame(width: 400, height: 600)
}
