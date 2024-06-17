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
    @StateObject private var fileViewModel = FileViewModel()
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fileViewModel)
        }
        .modelContainer(sharedModelContainer)

        // Define a new window for displaying file columns
        Window("File Columns", id: "file-columns") {
            FileColumnsWindow()
                .environmentObject(fileViewModel)
        }
        .defaultSize(width: 400, height: 300)
    }
}
