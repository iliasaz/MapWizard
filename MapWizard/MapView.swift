//
//  MapView.swift
//  MapWizard
//
//  Created by Ilia Sazonov on 9/23/24.
//

import SwiftUI

struct MapView: View {
    @ObservedObject var viewModel: ERDViewModel
    @Binding var path: NavigationPath

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Section("Column Mappings") {
                ColumnMappingView(erdViewModel: viewModel)
                    .frame(minWidth: 100, maxWidth: .infinity, minHeight: 100, maxHeight: 600)
            }
            Section("Join Mappings") {
                JoinMappingView(erdViewModel: viewModel)
                    .frame(minWidth: 100, maxWidth: .infinity, minHeight: 50, maxHeight: 200)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Mapping Recommendations")
        .task {
            await viewModel.generateColumnMappings()
            await viewModel.generateJoinMappings()
        }
    }
}

#Preview {
    MapView(viewModel: ERDViewModel.preview, path: .constant(NavigationPath.init()))
        .frame(width: 800, height: 800)
}
