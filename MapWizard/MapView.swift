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
        VStack {
            Button {
                Task {
                    await viewModel.generateRecommendations()
                }
            }
            label: { Text("Get Recommendations") }

            RecommendationsView(erdViewModel: viewModel)
        }
        .padding()
        .navigationTitle("Mapping Recommendations")
    }
}

#Preview {
    MapView(viewModel: ERDViewModel.preview, path: .constant(NavigationPath.init()))
        .frame(width: 800, height: 600)
}
