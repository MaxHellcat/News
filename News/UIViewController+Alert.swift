//
//  UIViewController+Alert.swift
//  News
//
//  Created by Max Reshetey on 28/12/2017.
//  Copyright © 2017 Max Reshetey. All rights reserved.
//

import UIKit

extension UIViewController
{
	func presentErrorAlert(_ text: String)
	{
		let alert = UIAlertController(title: "Error", message: text, preferredStyle: .alert)

		let action = UIAlertAction(title: "OK", style: .default) { action in }
		alert.addAction(action)

		present(alert, animated: true, completion: nil)
	}
}
