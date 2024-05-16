//
//  TodoViewController.swift
//  synchronize
//
//  Created by benjamin on 3/29/24.
//

import Foundation
import UIKit
import CoreData


class TodoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    let customSC = UISegmentedControl(items: ["All", "Completed", "Incomplete"])
    
    let tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self,
                       forCellReuseIdentifier: "cell")
        return table
    }()
    
    private var models = [ToDoItem]()
    var showCounts = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "To-do"
        setupSegmentedControl()
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTask))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchTask))
    }
    
    private func setupSegmentedControl() {
        let titles = ["Completed", "All", "Incomplete"]
        let segmentControl = UISegmentedControl(items: titles)

        // Setting the appearance
//        segmentControl.backgroundColor = .gray
        segmentControl.selectedSegmentTintColor = .white

        // Setting the width of each segment
        for index in 0..<titles.count {
            segmentControl.setWidth(90, forSegmentAt: index)
        }

        // Adding the target action for value change
        segmentControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)

        // Setting default selected index
        segmentControl.selectedSegmentIndex = 1

        // Trigger the action event manually to handle initial selection
        segmentChanged(segmentControl)  // Manually calling the segment changed method

        // Setting the segmented control as the navigation item's title view
        navigationItem.titleView = segmentControl
    }
    
    @objc func segmentChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            // Handle "All" selection
            getCompletedItems()
            print("Completed is selected")
        case 1:
            getAllItems()
            print("All is selected")
        case 2:
            // Handle "Missed" selection
            getIncompleteItems()
            print("Incomplete is selected")
        default:
            break
        }
    }
    
    @objc private func addTask() {
        let alert = UIAlertController(title: "Add New To-do", message: "Enter new to-do event", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: nil)
        
        alert.addAction(UIAlertAction(title: "Submit", style: .cancel, handler: { [weak self] _ in
            guard let field = alert.textFields?.first, let text = field.text, !text.isEmpty else {
                return
            }
            
            self?.createItem(name: text)
        }))
        
        present(alert, animated: true)
    }
    
    @objc private func searchTask() {
        let alert = UIAlertController(title: "Add New To-do", message: "Enter new to-do event", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: nil)
        
        alert.addAction(UIAlertAction(title: "Submit", style: .cancel, handler: { [weak self] _ in
            guard let field = alert.textFields?.first, let text = field.text, !text.isEmpty else {
                return
            }
            
            self?.createItem(name: text)
        }))
        
        present(alert, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return showCounts ? models.count + 1 : models.count
        }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showCounts && indexPath.row == 0 {
            // Create a cell to display counts
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.textLabel?.text = "Summary"
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 32)
            cell.detailTextLabel?.text = "Completed: \(completedTaskCount()), Incomplete: \(incompleteTaskCount()), Total: \(allTaskCount())"
            return cell
        } else {
            // Adjust index if counts are shown
            let adjustedIndex = showCounts ? indexPath.row - 1 : indexPath.row
            let model = models[adjustedIndex]
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = model.name
            cell.accessoryType = model.isCompleted ? .checkmark : .none
            return cell
        }
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if showCounts && indexPath.row == 0 {
            // Do nothing when the summary cell is tapped
            tableView.deselectRow(at: indexPath, animated: true)
        } else {
            // Adjust index if counts are shown
            let adjustedIndex = showCounts ? indexPath.row - 1 : indexPath.row
            let item = models[adjustedIndex]

            item.isCompleted.toggle()

            do {
                try context.save()
                tableView.reloadRows(at: [indexPath], with: .automatic)  // Refresh the cell
                tableView.reloadData()
            } catch {
                print("Error saving context after toggling completion: \(error)")
            }
        }
    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        if showCounts && indexPath.row == 0 {
            // No actions for the summary row
            return nil
        } else {
            // Adjust index if counts are shown
            let adjustedIndex = showCounts ? indexPath.row - 1 : indexPath.row
            let item = models[adjustedIndex]

            // Edit action
            let editAction = UIContextualAction(style: .normal, title: "Edit", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
                let alert = UIAlertController(title: "Edit to-do", message: "Enter new to-do", preferredStyle: .alert)
                alert.addTextField(configurationHandler: nil)
                alert.textFields?.first?.text = item.name
                alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] _ in
                    guard let field = alert.textFields?.first, let newName = field.text, !newName.isEmpty else {
                        return
                    }
                    self?.updateItem(item: item, newName: newName)
                    tableView.reloadRows(at: [indexPath], with: .automatic)  // Refresh the cell
                }))
                self.present(alert, animated: true)
                success(true)
            })
            editAction.backgroundColor = .blue  // Updated color for better visibility

            // Delete action
            let deleteAction = UIContextualAction(style: .destructive, title: "Delete", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
                self.deleteItem(item: item)
                if let index = self.models.firstIndex(where: {$0 === item}) {
                    self.models.remove(at: index)  // Remove the item from the data source
                    tableView.deleteRows(at: [indexPath], with: .automatic)  // Animate removal
                }
                print("Delete action ...")
                success(true)
            })
            deleteAction.backgroundColor = .red  // Usually, delete actions are red

            return UISwipeActionsConfiguration(actions: [editAction, deleteAction])
        }
    }

    
    // MARK: Get specified Core Data
    func getAllItems() {
        do {
            models = try context.fetch(ToDoItem.fetchRequest())// query all items in DB
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        catch {
            print("Error fetching data from context: \(error)")
        }
    }
    
    func getCompletedItems() {
        let request: NSFetchRequest<ToDoItem> = ToDoItem.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == %@", NSNumber(value: true))
        
        do {
            models = try context.fetch(request)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            print("Error fetching completed items: \(error)")
        }
    }
    
    func getIncompleteItems() {
        let request: NSFetchRequest<ToDoItem> = ToDoItem.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == %@", NSNumber(value: false))

        do {
            models = try context.fetch(request)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            print("Error fetching incomplete items: \(error)")
        }
    }
    
    // Function to count all tasks
    func allTaskCount() -> Int {
        let request: NSFetchRequest<ToDoItem> = ToDoItem.fetchRequest()
        do {
            let count = try context.count(for: request)
            return count
        } catch {
            print("Error counting all tasks: \(error)")
            return 0
        }
    }

    // Function to count completed tasks
    func completedTaskCount() -> Int {
        let request: NSFetchRequest<ToDoItem> = ToDoItem.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == %@", NSNumber(value: true))
        do {
            let count = try context.count(for: request)
            return count
        } catch {
            print("Error counting completed tasks: \(error)")
            return 0
        }
    }

    // Function to count incomplete tasks
    func incompleteTaskCount() -> Int {
        let request: NSFetchRequest<ToDoItem> = ToDoItem.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == %@", NSNumber(value: false))
        do {
            let count = try context.count(for: request)
            return count
        } catch {
            print("Error counting incomplete tasks: \(error)")
            return 0
        }
    }
    
    
    // MARK: Core Data
    func createItem(name: String) {
        let newItem = ToDoItem(context: context)
        newItem.name = name
        newItem.createdAt = Date()
        newItem.isCompleted = false
        
        do {
            try context.save()
            getAllItems()
            
        }
        catch {
            
        }
    }
    
    func deleteItem(item: ToDoItem) {
        context.delete(item)
        
        do {
            try context.save()
            getAllItems()
        }
        catch {
            
        }
    }
    
    func updateItem(item: ToDoItem, newName: String) {
        item.name = newName
        
        do {
            try context.save()
            getAllItems()
        }
        catch {
            
        }
    }
}
