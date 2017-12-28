//
//  UIView+Constraints.swift
//  News
//
//  Created by Max Reshetey on 27/12/2017.
//  Copyright © 2017 Max Reshetey. All rights reserved.
//

import UIKit

extension UIView
{
	func centerInSuperview()
	{
		guard let superview = superview else { return }

		if translatesAutoresizingMaskIntoConstraints == true {
			translatesAutoresizingMaskIntoConstraints = false
		}

		superview.addConstraint(centerXAnchor.constraint(equalTo: superview.centerXAnchor))
		superview.addConstraint(centerYAnchor.constraint(equalTo: superview.centerYAnchor))
	}

	func snapToSuperview()
	{
		guard let superview = superview else { return }
		
		if translatesAutoresizingMaskIntoConstraints == true {
			translatesAutoresizingMaskIntoConstraints = false
		}

		superview.addConstraint(widthAnchor.constraint(equalTo: superview.widthAnchor))
		superview.addConstraint(heightAnchor.constraint(equalTo: superview.heightAnchor))
	}
}

