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
    private var keyword: String?
    private var items: [NewsItem] = []
    private var index: Int = 0

    var currentItem: CrawlViewModel = CrawlViewModel.syncModel

    init(keyword: String? = nil) {
        self.keyword = keyword
        super.init()
    }

    func nextItem(_ completion: @escaping (_ item: CrawlViewModel) -> Void) {
        if !items.isEmpty && index < (items.count - 1) {
            index += 1
            completion(items[index].crawlItem)
        } else {
            networkManager.fetchItems(for: keyword) { [unowned self] items in
                guard !items.isEmpty else { return }
                self.items = items
                self.index = 1
                completion(items[0].crawlItem)
            }
        }
    }
}
