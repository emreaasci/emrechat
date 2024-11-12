//
//  PersistenceController.swift
//  emrechat
//
//  Created by Emre Aşcı on 12.11.2024.
//


import CoreData

struct PersistenceController {
    static let shared = PersistenceController() // Singleton instance
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "ChatMessage")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data store failed to load: \(error.localizedDescription)")
            }
        }
    }
}
