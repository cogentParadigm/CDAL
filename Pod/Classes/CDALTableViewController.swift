//
//  CDALTableViewController.swift
//  Pods
//
//  Created by Ali Gangji on 5/18/16.
//
//

import UIKit
import CoreData

public class CDALTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var results:NSFetchedResultsController?
    let context:NSManagedObjectContext
    
    public init(moc:NSManagedObjectContext) {
        context = moc
        super.init(style: .Plain)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }
    
    public func configureTableView() {
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "DefaultCell")
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public func configureCell(cell:UITableViewCell, indexPath:NSIndexPath) {
        //override to configure cell
    }
    
    public func query(cdQuery:CDALQuery, sectionKey:String?) {
        results = NSFetchedResultsController(fetchRequest: cdQuery.build(), managedObjectContext: context, sectionNameKeyPath: sectionKey, cacheName: "rootCache")
        results!.delegate = self
        fetch()
    }
    
    public func fetch() {
        do {
            try results?.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
    }
    
    // MARK: - Table view data source
    
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = results?.sections {
            return sections.count
        }
        return 0
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = results?.sections {
            return sections[section].numberOfObjects
        }
        return 0
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("DefaultCell", forIndexPath: indexPath)
        
        self.configureCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    public func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    public func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Move:
            break
        case .Update:
            break
        }
    }
    
    public func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            if let insertIndexPath = newIndexPath {
                tableView.insertRowsAtIndexPaths([insertIndexPath], withRowAnimation: .Fade)
            }
        case .Delete:
            if let deleteIndexPath = indexPath {
                tableView.deleteRowsAtIndexPaths([deleteIndexPath], withRowAnimation: .Fade)
            }
        case .Update:
            if let updateIndexPath = indexPath, let cell = self.tableView.cellForRowAtIndexPath(updateIndexPath) {
                configureCell(cell, indexPath: updateIndexPath)
            }
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        }
    }
    
    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }


}
