//
//  MapWizardApp.swift
//  MapWizard
//
//  Created by Ilia Sazonov on 6/16/24.
//

import SwiftUI
import SwiftData

@main
struct MapWizardApp: App {
    @State private var appViewModel = AppViewModel.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appViewModel.fileViewModel)
        }

        // Define a new window for displaying file columns
        Window("ERD", id: "erd") {
            WizardView(viewModel: appViewModel.erdViewModel)
        }
        .defaultSize(width: 800, height: 1000)
    }
}

class AppViewModel: ObservableObject {
    @Published var fileViewModel: FileViewModel
    @Published var erdViewModel: ERDViewModel = .init(entities: [.previewCar, .previewFamily, .previewPerson])

    private init () {
        self.erdViewModel = .init(entities: [])
        self.fileViewModel = FileViewModel(appViewModel: nil)
    }

    static var shared: AppViewModel {
        let app = AppViewModel.init()
        app.fileViewModel.appViewModel = app
        app.erdViewModel.appViewModel = app
        return app
    }
}
