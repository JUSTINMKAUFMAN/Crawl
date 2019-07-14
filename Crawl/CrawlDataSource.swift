//
//  CrawlDataSource.swift
//  Crawl
//
//  Created by Justin Kaufman on 3/23/17.
//  Copyright © 2017 Justin Kaufman. All rights reserved.
//

import Foundation
import Cocoa
import AppKit

class CrawlDataSource: NSObject {
    private let networkManager = NetworkManager()
    private var keywords: [String]?
    private var items: [NewsItem] = []
    private var index: Int = 0

    var currentItem: CrawlViewModel = CrawlViewModel.syncModel

    init(keywords: [String]? = nil) {
        self.keywords = keywords
        super.init()
    }

    func nextItem(_ completion: @escaping (_ item: CrawlViewModel) -> Void) {
        if !items.isEmpty && index < (items.count - 1) {
            index += 1
            completion(items[index].crawlItem)
        } else {
            networkManager.fetchItems(for: keywords) { [unowned self] items in
                if items.isEmpty {
                    if !self.items.isEmpty {
                        self.index += 1
                        if self.index > self.items.count - 1 { self.index = 0 }
                        completion(self.items[self.index].crawlItem)
                    } else {
                        completion(CrawlViewModel.syncModel)
                    }
                } else {
                    self.index = 1
                    self.items = items
                    completion(items[0].crawlItem)
                }
            }
        }
    }
}
