//
//  MapView.swift
//  MapWizard
//
//  Created by Ilia Sazonov on 9/21/24.
//

import SwiftUI

struct MapViewGraphViz: View {
    @ObservedObject var viewModel: ERDViewModel
    @Binding var path: NavigationPath
    @State var nsImg: NSImage = NSImage(size: NSSize(width: 1000, height: 1000))

    var body: some View {
        VStack {
            Text("Hello")
            Button {
                Task {
                    await viewModel.generateRecommendations()
                    await MainActor.run {
                        viewModel.getGraph().dot.render(using: .dot, to: .png) { result in
                            self.nsImg = try! NSImage(data: result.get())!
                        }
                    }
                }
            }
            label: { Text("Get Recommendations") }

            Image(nsImage: nsImg)
                .resizable()
                .padding()
//                .frame(width: 1000, height: 1000)
//                .aspectRatio(contentMode: .fit)
        }
    }
}

#Preview {
    MapViewGraphViz(viewModel: ERDViewModel.preview, path: .constant(NavigationPath.init()))
        .frame(width: 800, height: 600)
}
