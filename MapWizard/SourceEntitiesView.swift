//
//  SourceEntitiesView.swift
//  MapWizard
//
//  Created by Ilia Sazonov on 9/21/24.
//

import SwiftUI

struct SourceEntitiesView: View {

    @ObservedObject var viewModel: ERDViewModel
    @Binding var path: NavigationPath
    @State private var isShowingInvalidSelectionAlert = false

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack {
            Text("Select Source Entities")
            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                    ForEach(
                        $viewModel.entities.filter {
                            $0.entityType == .none || $0.entityType == .source },
                        id: \.self) { $entity in
                        EntityView(entity: $entity, mode: .source)
                    }
                }
                .padding()
            }
            .frame(minWidth: 150, minHeight: 300)
            
            Button {
                if !viewModel.isValidSelection(of: .source) {
                    isShowingInvalidSelectionAlert.toggle()
                    return
                }
                path.append(WizardView.ViewOptions.targetSelection(viewModel: viewModel))
            } label: {
                Text("Next >")
            }
            .alert("Invalid Selection", isPresented: $isShowingInvalidSelectionAlert) {
                Button("OK", role: .cancel) {  }
            } message: {
                Text("Please select one or more source entities.")
            }
            .dialogSeverity(.critical)
        }
        .padding()
        .navigationTitle("Source Entities")
    }
}

#Preview {
    SourceEntitiesView(viewModel: ERDViewModel.preview, path: .constant(NavigationPath.init()))
        .frame(width: 800, height: 600)
}
