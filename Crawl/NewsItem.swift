//
//  NewsItem.swift
//  Crawl
//
//  Created by Justin Kaufman on 3/23/17.
//  Copyright © 2017 Justin Kaufman. All rights reserved.
//

import Foundation
import Cocoa

struct NewsItem: Equatable, Hashable {
    let title: String
    let description: String
    let imageURL: String
    let date: Date
    let url: String
    var image: NSImage?
}

extension NewsItem {
    var crawlItem: CrawlViewModel {
        return CrawlViewModel(
            title: title,
            url: URL(string: url) ?? URL(string: "https://news.google.com")!,
            image: image
        )
    }
}
