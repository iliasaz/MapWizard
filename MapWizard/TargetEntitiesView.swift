//
//  TargetEntitiesView.swift
//  MapWizard
//
//  Created by Ilia Sazonov on 9/21/24.
//

import SwiftUI

struct TargetEntitiesView: View {

    @ObservedObject var viewModel: ERDViewModel
    @Binding var path: NavigationPath

    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    @State private var isShowingInvalidSelectionAlert = false

    var body: some View {
        VStack {
            Text("Select Target Entity")
            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                    ForEach(
                        $viewModel.entities
                            .filter { $0.entityType == .none || $0.entityType == .target },
                        id: \.self) { $entity in
                        EntityView(entity: $entity, mode: .target)
                    }
                }
                .padding()
            }
            .frame(minWidth: 150, minHeight: 300)

            Button {
                if !viewModel.isValidSelection(of: .target) {
                    isShowingInvalidSelectionAlert.toggle()
                    return
                }
//                viewModel.markSelected(as: .target)
                path.append(WizardView.ViewOptions.mapView(viewModel: viewModel))
            } label: {
                Text("Next >")
            }
            .alert("Invalid Selection", isPresented: $isShowingInvalidSelectionAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please select exactly one target entity.")
            }
            .dialogSeverity(.critical)
        }
        .padding()
        .navigationTitle("Target Entity")
    }
}

#Preview {
    TargetEntitiesView(viewModel: ERDViewModel.preview, path: .constant(NavigationPath.init()))
        .frame(width: 800, height: 600)
}


extension Binding where Value: MutableCollection, Value: RangeReplaceableCollection, Value.Element: Identifiable {
    func filter(_ isIncluded: @escaping (Value.Element)->Bool) -> Binding<[Value.Element]> {
        return Binding<[Value.Element]>(
            get: {
                // The binding returns a filtered subset of the original wrapped collection.
                self.wrappedValue.filter(isIncluded)
            },
            set: { newValue in
                // Assignments to the binding's wrapped value are compared with IDs in the original biding's collection.
                // If they match, they are replaced.
                // If no match is found, they are appended.
                newValue.forEach { newItem in
                    guard let i = self.wrappedValue.firstIndex(where: { $0.id == newItem.id }) else {
                        self.wrappedValue.append(newItem)
                        return
                    }
                    self.wrappedValue[i] = newItem
                }
            }
        )
    }
}
