//
//  ContentViewController.swift
//  News
//
//  Created by Max Reshetey on 28/12/2017.
//  Copyright © 2017 Max Reshetey. All rights reserved.
//

import UIKit

class ContentViewController: UIViewController
{
	@IBOutlet weak var textLabel: UILabel!
	let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)

	var dataManager: DataManager!
	var itemId: Int64!

	// MARK: - View lifecycle
    override func viewDidLoad()
	{
        super.viewDidLoad()

		fetchNewsContent()
    }

	// MARK: - Business logic
	private func fetchNewsContent()
	{
		showActivityIndicator()

		dataManager.fetchContent(for: itemId) { [weak self] (text) in

			guard let weakSelf = self else { return }

			weakSelf.hideActivityIndicator()

			guard let text = text else { weakSelf.presentErrorAlert("Failed to fetch content."); return }

			weakSelf.textLabel.text = text
		}
	}

	// MARK: - Helper methods
	private func showActivityIndicator()
	{
		view.addSubview(activityIndicator)
		activityIndicator.centerInSuperview()

		activityIndicator.startAnimating()
	}

	private func hideActivityIndicator()
	{
		activityIndicator.stopAnimating()

		activityIndicator.removeFromSuperview()
	}

	// MARK: - Memory management
    override func didReceiveMemoryWarning()
	{
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
