// PersistenceController.swift - Yeni dosya oluşturun
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "ChatMessage") // ChatMessage.xcdatamodeld dosyanızın adı
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data store failed to load: \(error.localizedDescription)")
            }
        }
    }
}