//
//  PaneView.swift
//  News
//
//  Created by Max Reshetey on 27/12/2017.
//  Copyright © 2017 Max Reshetey. All rights reserved.
//

import UIKit

fileprivate let kPaneSize = CGSize(width: 150.0, height: 150.0)

class PaneView: UIView
{
	var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
	var textLabel = UILabel()

	override init(frame: CGRect)
	{
		super.init(frame: frame)

		configure()
		configureIndicatorView()
		configureLabelView()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func showWithText(text: String, in view: UIView)
	{
		activityIndicator.stopAnimating()
		textLabel.isHidden = false

		textLabel.text = text

		showInView(view: view)
	}

	func showIndicatorInSuperview(superview: UIView)
	{
		textLabel.isHidden = true
		activityIndicator.startAnimating()

		showInView(view: superview)
	}

	func dismiss()
	{
		removeFromSuperview()
	}

	// MARK: - Aux methods
	fileprivate func showInView(view: UIView)
	{
		view.addSubview(self)
		
		view.addConstraint(widthAnchor.constraint(equalToConstant: kPaneSize.width))
		view.addConstraint(heightAnchor.constraint(equalToConstant: kPaneSize.height))
		
		centerInSuperview()
	}

	fileprivate func configure()
	{
		translatesAutoresizingMaskIntoConstraints = false
		backgroundColor = UIColor.lightGray
		layer.cornerRadius = 14.0
	}

	fileprivate func configureIndicatorView()
	{
		addSubview(activityIndicator)
		activityIndicator.centerInSuperview()
	}

	fileprivate func configureLabelView()
	{
		addSubview(textLabel)
		textLabel.centerInSuperview()
	}
}
