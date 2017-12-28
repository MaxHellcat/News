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

class DataManager
{
	private let persistentContainer = NSPersistentContainer(name: kDataModelName)
	var context: NSManagedObjectContext { return persistentContainer.viewContext }

	var items = Array<Item>()

	private let kBaseUrl = "https://api.tinkoff.ru/v1"
	private let kPageSize = 20
	private var currentPage = 0

	weak var mostRecentLocalItem: Item? = nil

	init(completion: @escaping (DataManager) -> ())
	{
		persistentContainer.loadPersistentStores() { (description, error) in
			if let error = error
			{
				fatalError("Failed to load Core Data stack: \(error)")
			}

			print("Data Manager: Data store loaded OK.")

			completion(self)
		}
	}

	// TODO: Reduce body
	// TODO: How do we know if the last page has been fetched?
	func fetchNextItems(completion: @escaping (Bool) -> Void)
	{
		let first = currentPage * kPageSize
		let last = first + kPageSize

		print("Storage: Fetching items \(first) ... \(last-1)")

		let request = NSFetchRequest<Item>(entityName: kItemEntityName)
		let sort = NSSortDescriptor(key: "id", ascending: false)
		request.sortDescriptors = [sort]

		request.fetchOffset = first
		request.fetchLimit = kPageSize

		if let items = try? context.fetch(request), items.count > 0
		{
			if first == 0 {
				mostRecentLocalItem = items.first
			}

			self.items += items

			print("Storage: Fetched \(items.count) items")

			completion(true)

			currentPage += 1

			// When we have local data for given range, only fetch from network to find
			// recently added that are not in cache yet
			if first != 0 {
				return
			}
		}
		else
		{
			print("Storage: Nothing found for range \(first) ... \(last-1)")
		}

		
		let url = URL(string: kBaseUrl + "/" + "news?first=\(first)&last=\(last)")!

		print("Network: Fetching items \(first) ... \(last-1)")

		DispatchQueue.global(qos: .background).async {

			let data = try? Data(contentsOf: url)

			DispatchQueue.main.async { [unowned self] in

				guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject] else { completion(false); return }

				// Any other codes we need to handle?
				let resultCode = json["resultCode"] as! String
				guard resultCode == "OK" else { completion(false); return }
				guard let rawItems = json["payload"] as? [[String: AnyObject]] else { completion(false); return }

				let findDelta = first == 0 && self.mostRecentLocalItem != nil

				let items = self.itemsFromRawItems(findDelta: findDelta, rawItems) // This inserts into context!
				self.persist()

				self.items += items

				print("Network: Fetched \(items.count) items")

				completion(true)
				
				self.currentPage += 1
			}
		}
	}

	func resetFetching()
	{
		currentPage = 0
	}

	// TODO: Reduce body
	func fetchItemContent(itemId: Int, completion: @escaping (String?) -> Void)
	{
		print("Storage: Fetching content for itemId = \(itemId)")

		let thatItem = self.items.filter({ (item) -> Bool in
			item.id == itemId
		}).first!

		if let content = thatItem.content
		{
			print("Storage: Fetched content for itemId = \(itemId)")

			completion(content.text)

			// I'm assuming the news content doesn't change and so no need to refetch frotm the server
			return
		}


		print("Storage: No content found for itemId = \(itemId)")


		let url = URL(string: kBaseUrl + "/" + "news_content?id=\(itemId)")!

		print("Network: Fetching content for itemId = \(itemId)")

		DispatchQueue.global(qos: .background).async {

			let data = try? Data(contentsOf: url)

			DispatchQueue.main.async {

				guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject] else {
					completion(nil)
					return
				}

				let resultCode = json["resultCode"] as! String
				guard resultCode == "OK" else { completion(nil); return }
				guard let itemJson = json["payload"] as? [String: AnyObject] else { completion(nil); return }
				guard let text = itemJson["content"] as? String else { completion(nil); return }
				

				
				let thatItem = self.items.filter({ (item) -> Bool in
					item.id == itemId
				}).first!

				let content = Content(context: self.context)
				content.text = text

				thatItem.content = content
				self.persist()

				print("Network: Fetched content for itemId = \(itemId)")

				completion(text)
			}
		}
	}

	// MARK: - Private methods
	private func itemsFromRawItems(findDelta: Bool, _ json: [[String: AnyObject]]) -> Array<Item>
	{
		var items = Array<Item>()
		items.reserveCapacity(json.count)

		for itemJson in json
		{
			guard let text = itemJson["text"] as? String,
				let idStr = itemJson["id"] as? String,
				let id = Int64(idStr) else { continue }

			if findDelta, let mostRecentLocalItem = mostRecentLocalItem
			{
				if id > mostRecentLocalItem.id
				{
					let item = createItem(id: id, text: text, contentViewCount: 0)
					items.append(item)

					self.mostRecentLocalItem = item
				}
			}
			else
			{
				let item = createItem(id: id, text: text, contentViewCount: 0)
				items.append(item)
			}
		}

		return items
	}

	// MARK: - Persistent store related
	private func createItem(id: Int64, text: String, contentViewCount: Int64) -> Item
	{
//		let item = NSEntityDescription.insertNewObject(forEntityName: kItemEntityName, into: context) as! Item
		let item = Item(context: context)

		item.id = id
		item.text = text
		item.contentViewCount = contentViewCount

		return item
	}
	
	func persist()
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
