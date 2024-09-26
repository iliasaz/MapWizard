//
//  WizardView.swift
//  MapWizard
//
//  Created by Ilia Sazonov on 9/21/24.
//

import SwiftUI

struct WizardView: View {
    @ObservedObject var viewModel: ERDViewModel
//    @State private var path: NavigationPath = .init()
        var body: some View {
            NavigationStack(path: $viewModel.path){
                SourceEntitiesView(viewModel: viewModel, path: $viewModel.path)
                    .navigationDestination(for: ViewOptions.self) { option in
                        option.view($viewModel.path)
                    }
            }
        }

    // Create an `enum` so you can define your options
    enum ViewOptions: Hashable {

        var hashValue: Int {
            switch self {
                case .sourceSelection: return 1
                case .targetSelection: return 2
                case .mapView: return 3
            }
        }

        static func == (lhs: WizardView.ViewOptions, rhs: WizardView.ViewOptions) -> Bool {
            lhs.hashValue == rhs.hashValue
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(hashValue)
        }
        
        case sourceSelection(viewModel: ERDViewModel)
        case targetSelection(viewModel: ERDViewModel)
        case mapView(viewModel: ERDViewModel)

        //Assign each case with a `View`
        @ViewBuilder func view(_ path: Binding<NavigationPath>) -> some View{
            switch self{
                case .sourceSelection(let viewModel):
                    SourceEntitiesView(viewModel: viewModel, path: path)
                case .targetSelection(let viewModel):
                    TargetEntitiesView(viewModel: viewModel, path: path)
                case .mapView(let viewModel):
//                    MapViewGraphViz(viewModel: viewModel, path: path)
                    MapView(viewModel: viewModel, path: path)
            }
        }
    }
}

#Preview {
    WizardView(viewModel: ERDViewModel.preview)
        .frame(width: 800, height: 600)
}
