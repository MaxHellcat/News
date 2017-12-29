//
//  String+Decoding.swift
//  News
//
//  Created by Max Reshetey on 28/12/2017.
//  Copyright © 2017 Max Reshetey. All rights reserved.
//

import Foundation
import UIKit

extension String
{
	func htmlDecodedLight() -> String
	{
		var str = self

		// First entities, limit by the most frequent ones
		let entities = [
			// Headers
			"&amp;"     : "&",
			"&nbsp;"     : "\u{00A0}",
			"&laquo;"    : "\u{00AB}",
			"&raquo;"    : "\u{00BB}",
			"&rsquo;"    : "\u{2019}",
			"&mdash;"    : "\u{2014}",
			
			// Content
			"&ldquo;"    : "\u{201C}",
			"&bdquo;"    : "\u{201E}",
			"&ndash;"    : "\u{2013}",
		]

		for (name, value) in entities {
			str = str.replacingOccurrences(of: name, with: value)
		}

		// Then tags
		str = str.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)

		return str
	}
}
