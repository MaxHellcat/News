//
//  ItemsViewController.swift
//  News
//
//  Created by Max Reshetey on 27/12/2017.
//  Copyright © 2017 Max Reshetey. All rights reserved.
//

import UIKit
import CoreData

fileprivate let kShowContentSegueId = "PushContentPage"
fileprivate let kTableFooterHeight: CGFloat = 44.0
fileprivate let kCellIdentifier = "Cell"

class ItemsViewController: UITableViewController, NSFetchedResultsControllerDelegate
{
	private var dataManager: DataManager!
	
	let cache = Array<CGFloat>()

	let footerView: UIView = {
		let view = UIView()
		view.bounds.size.height = kTableFooterHeight

		let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
		view.addSubview(activityIndicator)
		activityIndicator.centerInSuperview()
		activityIndicator.startAnimating()

		return view
	}()

	// MARK: - View lifecycle
    override func viewDidLoad()
	{
        super.viewDidLoad()

		self.title = "Тинькофф Новости"

		self.dataManager = DataManager() { [unowned self] manager in
			self.dataManager = manager

			self.dataManager.fetchedResultsController.delegate = self
			try! self.dataManager.fetchedResultsController.performFetch() // Feeling lucky?

			self.fetchNextNews(initialFetch: true)
		}
    }

    // MARK: - UITableViewDataSource related
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return dataManager.fetchedResultsController.sections![section].numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
        let cell = tableView.dequeueReusableCell(withIdentifier: kCellIdentifier, for: indexPath)

		let item = dataManager.fetchedResultsController!.object(at: indexPath)

		let text = item.text!
		cell.textLabel!.text = text
		cell.detailTextLabel!.text = "\(item.contentViewCount)"
//		cell.detailTextLabel!.text = "\(indexPath.row) / \(item.id) / \(item.timestamp)"

		// Of course some other loading decision can be used, just sticking to the classic approach here
		if indexPath.item == dataManager.fetchedResultsController.sections![0].numberOfObjects-1 {
			fetchNextNews(initialFetch: false)
		}

        return cell
    }
	
	let attributes = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16.0)]

	// MARK: - UITableViewDelegate related
	
	// Long battle against totally weird behavior of cells during insertion, keep their height constant for now
#if false
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
	{
		let item = dataManager.fetchedResultsController!.object(at: indexPath)

		let textMaxWidth = tableView.bounds.size.width - 16.0 - 16.0

		let constraintRect = CGSize(width: textMaxWidth, height: CGFloat.greatestFiniteMagnitude)

		let rect = item.text!.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)

		let height = 5.0 + rect.size.height + 19.0

		return height
	}
#endif

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		performSegue(withIdentifier: kShowContentSegueId, sender: self)
	}

	// MARK: - NSFetchedResultsControllerDelegate related
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
	{
		tableView.beginUpdates()
	}

	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
	{
		switch type
		{
		case .insert:
				tableView.insertRows(at: [newIndexPath!], with: .none)
		case .delete:
				tableView.deleteRows(at: [indexPath!], with: .none) // Ever called?
		case .update:
				tableView.reloadRows(at: [indexPath!], with: .none)
		case .move:
			// Somehow sporadically called along with insertRows for the same indexPath
//			tableView.moveRow(at: indexPath!, to: newIndexPath!)
			break
		}
	}

	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
	{
		tableView.endUpdates()
	}

	// MARK: - Action handlers
	@IBAction func refreshTriggered(_ sender: Any)
	{
		fetchNextNews(initialFetch: true)
	}

	// MARK: - Business logic
	private func fetchNextNews(initialFetch: Bool)
	{
		tableView.tableFooterView = self.footerView

		dataManager.fetchNextItems(initialFetch: initialFetch){ (success) in

			self.tableView.tableFooterView = nil

			if self.tableView.refreshControl!.isRefreshing {
				self.tableView.refreshControl!.endRefreshing()
			}

			if !success {
				self.presentErrorAlert("Failed to fetch news.");
			}
		}
	}

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
	{
		if segue.identifier == kShowContentSegueId
		{
			let viewController = segue.destination as! ContentViewController

			let indexPath = tableView.indexPathForSelectedRow! // Ever nil here? Assuming not

			let item = dataManager.fetchedResultsController!.object(at: indexPath)

			// TODO: Decrement later if we actually don't see the content
			item.contentViewCount += 1
			dataManager.save()

			// Kick in the trivial dependency injection
			viewController.dataManager = dataManager
			viewController.itemId = item.id
		}
    }

	// MARK: - Memory management
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}
