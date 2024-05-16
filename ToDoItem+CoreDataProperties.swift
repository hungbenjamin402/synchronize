//
//  ToDoItem+CoreDataProperties.swift
//  synchronize
//
//  Created by benjamin on 5/5/24.
//
//

import Foundation
import CoreData


extension ToDoItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ToDoItem> {
        return NSFetchRequest<ToDoItem>(entityName: "ToDoItem")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var name: String?


}

extension ToDoItem : Identifiable {

}
