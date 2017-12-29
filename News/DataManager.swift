//
//  DataManager.swift
//  News
//
//  Created by Max Reshetey on 27/12/2017.
//  Copyright © 2017 Max Reshetey. All rights reserved.
//

import Foundation
import CoreData

fileprivate let kDataModelName = "ItemsDataModel"
fileprivate let kItemEntityName = "Item"
fileprivate let kContentEntityName = "Content"

fileprivate let kBaseUrl = "https://api.tinkoff.ru/v1"
fileprivate let kPageSize = 20

class DataManager
{
	private let persistentContainer = NSPersistentContainer(name: kDataModelName)
	private var context: NSManagedObjectContext { return persistentContainer.viewContext }

	var fetchedResultsController: NSFetchedResultsController<Item>!

	var items: [Item]? {
		return self.fetchedResultsController.sections![0].objects as? [Item]
	}

	init(completion: @escaping (DataManager) -> ())
	{
		persistentContainer.loadPersistentStores() { (description, error) in
			if let error = error {
				fatalError("Failed to load Core Data stack: \(error)")
			}

			let request = NSFetchRequest<Item>(entityName: kItemEntityName)
			let sort = NSSortDescriptor(key: "timestamp", ascending: false)
			request.sortDescriptors = [sort]

			self.fetchedResultsController = NSFetchedResultsController<Item>(fetchRequest: request, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)

			completion(self)
		}
	}

	// TODO: How do we know if the last page has been fetched?
	// TODO: If got 0 items, consider that as a last page and stop next fetches
	func fetchNextItems(initialFetch: Bool, completion: @escaping (Bool) -> Void)
	{
		// TODO: Reduce
		let numberOfCachedItems = fetchedResultsController.sections![0].numberOfObjects

		let first = initialFetch ? 0 : numberOfCachedItems
		let last = first + kPageSize

		let url = URL(string: kBaseUrl + "/" + "news?first=\(first)&last=\(last)")!

		print("Network: Fetching items \(first) ... \(last-1)")

		DispatchQueue.global(qos: .background).async {

			let data = try? Data(contentsOf: url)

			DispatchQueue.main.async { [unowned self] in

				guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject] else { completion(false); return }

				let resultCode = json["resultCode"] as! String
				guard resultCode == "OK" else { completion(false); return }
				guard let rawItems = json["payload"] as? [[String: AnyObject]] else { completion(false); return }

				print("Network: Fetched \(rawItems.count) items")

				self.createItems(from: rawItems, initialFetch: initialFetch)

				completion(true)
			}
		}
	}

	private func createItems(from rawItems: [[String: AnyObject]], initialFetch: Bool)
	{
		let numberOfCachedItems = fetchedResultsController.sections![0].numberOfObjects

		for itemJson in rawItems
		{
			guard let text = itemJson["text"] as? String,
				let idStr = itemJson["id"] as? String,
				let id = Int64(idStr),
				let publicationDateJson = itemJson["publicationDate"] as? [String: Int64],
				let timestamp = publicationDateJson["milliseconds"]
				else { continue }

			if initialFetch && numberOfCachedItems > 0
			{
				let mostRecentItem = self.items!.first!

				if timestamp > mostRecentItem.timestamp
				{
					self.createItem(id: id, text: text, timestamp: timestamp)
				}
			}
			else
			{
				self.createItem(id: id, text: text, timestamp: timestamp)
			}
		}

		self.save()
	}

	private func createItem(id: Int64, text: String, timestamp: Int64)
	{
		let item = NSEntityDescription.insertNewObject(forEntityName: kItemEntityName, into: context) as! Item
		item.id = id
		item.text = text.htmlDecodedLight()
		item.timestamp = timestamp
		item.contentViewCount = 0
	}

	// TODO: Reduce body
	func fetchContent(for itemId: Int64, completion: @escaping (String?) -> Void)
	{
		print("Storage: Fetching content for itemId = \(itemId)")

		let item = items!.filter { $0.id == itemId }.first!

		if let content = item.content
		{
			print("Storage: Found content for itemId = \(itemId)")

			completion(content.text)

			// I'm assuming the news content doesn't change and so no need to refetch
			return
		}

		print("Storage: No content found for itemId = \(itemId)")

		let url = URL(string: kBaseUrl + "/" + "news_content?id=\(itemId)")!

		print("Network: Fetching content for itemId = \(itemId)")

		DispatchQueue.global(qos: .background).async {

			let data = try? Data(contentsOf: url)

			DispatchQueue.main.async {

				guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject] else { completion(nil); return }

				let resultCode = json["resultCode"] as! String
				guard resultCode == "OK" else { completion(nil); return }
				guard let itemJson = json["payload"] as? [String: AnyObject] else { completion(nil); return }
				guard let text = itemJson["content"] as? String else { completion(nil); return }

				print("Network: Fetched content for itemId = \(itemId)")

				// May place this in background, but feels speedy for now
				let decodedText = text.htmlDecodedLight()

				self.persistContent(text: decodedText, for: itemId)

				completion(decodedText)
			}
		}
	}

	private func persistContent(text: String, for itemId: Int64)
	{
		let item = items!.filter { $0.id == itemId }.first!
		item.content = createContent(text: text)

		save()
	}

	private func createContent(text: String?) -> Content
	{
		let content = NSEntityDescription.insertNewObject(forEntityName: kContentEntityName, into: context) as! Content
		content.text = text
		return content
	}

	// MARK: - Persistent store related
	func save()
	{
		do
		{
			try context.save()
		}
		catch
		{
			print("DataManager: Failed to persist data!")
			return
		}
		
		print("DataManager: Data persisted.")
	}
}
