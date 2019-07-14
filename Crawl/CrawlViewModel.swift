//
//  CrawlViewModel.swift
//  Crawl
//
//  Created by Justin Kaufman on 3/23/17.
//  Copyright © 2017 Justin Kaufman. All rights reserved.
//

import Foundation
import Cocoa

struct CrawlViewModel {
    let title: String
    let url: URL
    let image: NSImage?
}

extension CrawlViewModel {
    static let syncModel: CrawlViewModel = CrawlViewModel(
        title: "Synchronizing...",
        url: URL(string: "https://news.google.com")!,
        image: NSImage(named: "newsIcon")!
    )
}
