//  emrechatApp.swift
//  emrechat
//
//  Created by Emre Aşcı on 12.11.2024.
//
import SwiftUI
@main
struct emrechatApp: App {
    var body: some Scene {
        WindowGroup {
            MainView(currentUserId: "user2")
                            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            
            
            
        }
    }
}
