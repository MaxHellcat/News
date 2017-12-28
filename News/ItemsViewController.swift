//
//  ItemsViewController.swift
//  News
//
//  Created by Max Reshetey on 27/12/2017.
//  Copyright © 2017 Max Reshetey. All rights reserved.
//

import UIKit

// TODO: Decode html entities in background in data manager
// TODO: Try prefetching
// TODO: Cache cells' height to avoid jerking while scrolling
class ItemsViewController: UITableViewController
{
	private var dataManager: DataManager!

	let footerView: UIView = {
		let view = UIView()
		view.bounds.size.height = 44.0
//		view.backgroundColor = UIColor.brown

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

//		tableView.rowHeight = UITableViewAutomaticDimension
//		tableView.estimatedRowHeight = 120.0

		self.dataManager = DataManager() { [unowned self] manager in
			self.dataManager = manager
			self.fetchNextNews()
		}
    }

    // MARK: - UITableViewDataSource related
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
        return dataManager.items.count
    }

	// https://stackoverflow.com/questions/27996438/jerky-scrolling-after-updating-uitableviewcell-in-place-with-uitableviewautomati
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

		updateCell(cell, at: indexPath)

		// Of course some other loading decision can be used, just sticking to a classic approach here
		if indexPath.item == dataManager.items.count-1 {
			fetchNextNews()
		}

        return cell
    }

	// MARK: - UITableViewDelegate related
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		performSegue(withIdentifier: "PushContentPage", sender: self)
	}

	// MARK: - Action handlers
	@IBAction func refreshTriggered(_ sender: Any)
	{
		dataManager.resetFetching()
		self.dataManager.context.reset()
		self.dataManager.items = []
		
		fetchNextNews()
	}

	// MARK: - Business logic
	private func fetchNextNews()
	{
		tableView.tableFooterView = self.footerView

		self.dataManager.fetchNextItems(){  (success) in

			self.tableView.tableFooterView = nil

			// If we've pulled refresh, remove all data and cells first
			if self.tableView.refreshControl!.isRefreshing
			{
				self.tableView.refreshControl!.endRefreshing()

//				let indexPaths = (0..<self.dataManager.items.count).map() {
//					return IndexPath(item: $0, section: 0)
//				}
//
//				self.dataManager.items = [] // TODO: Incapsulate
//				self.tableView.deleteRows(at: indexPaths, with: .none)
				
//				self.dataManager.items = []
//				self.dataManager.context.reset()
				self.tableView.reloadData()
			}

			if !success {
				self.presentErrorAlert("Failed to fetch news.");
				return
			}

			// TODO: Need lastFetchedItems here
//			let indexPaths = (0..<items.count).map() {
//				return IndexPath(item: self.items.count - items.count + $0, section: 0)
//			}
//
//			UIView.performWithoutAnimation {
//				self.tableView.insertRows(at: indexPaths, with: .none)
//			}

			// Just reloading seems to be less jerky
			self.tableView.reloadData()
		}
	}

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
	{
		if segue.identifier == "PushContentPage"
		{
			let viewController = segue.destination as! ContentViewController

			let indexPath = tableView.indexPathForSelectedRow! // Ever nil here? Assuming not

			let item = dataManager.items[indexPath.row]

			item.contentViewCount += 1
			dataManager.persist()

			let cell = tableView.cellForRow(at: indexPath)! // Ever nil here? Assuming not
			updateCell(cell, at: indexPath)

			// Kick in the trivial dependency injection
			viewController.dataManager = dataManager
			viewController.itemId = Int(item.id)
		}
    }

	private func updateCell(_ cell: UITableViewCell, at indexPath: IndexPath)
	{
		let item = dataManager.items[indexPath.row]

		let text = item.text!.htmlDecodedLight()
		cell.textLabel!.text = text

		cell.detailTextLabel!.text = "\(item.contentViewCount)"
	}

	// MARK: - Memory management
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}
