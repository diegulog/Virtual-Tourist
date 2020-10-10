//
//  DataController.swift
//  Virtual Tourist
//
//  Created by Diego on 07/10/2020.
//
import Foundation
import CoreData

class DataController {
    let persistentContainer: NSPersistentContainer
  
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    let backgroudContext:NSManagedObjectContext!
    
    init(modelName:String) {
        persistentContainer = NSPersistentContainer(name: modelName)
        backgroudContext = persistentContainer.newBackgroundContext()

    }
    
    func save() {
        if viewContext.hasChanges {
            try? viewContext.save()
        }
    }
    
    func configureContext() {
        viewContext.automaticallyMergesChangesFromParent = true
        backgroudContext.automaticallyMergesChangesFromParent = true
        
        backgroudContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    func load(completion: (() -> Void)? = nil ) {
        persistentContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.configureContext()
            completion?()
        }
        
    }
}
