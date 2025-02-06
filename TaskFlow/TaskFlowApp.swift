//
//  TaskFlowApp.swift
//  TaskFlow
//
//  Created by Miguel Mercado on 3/2/25.
//

import SwiftUI

@main
struct TaskFlowApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            LoginView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
