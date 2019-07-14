//
//  NetworkManager.swift
//  Crawl
//
//  Created by Justin Kaufman on 3/23/17.
//  Copyright © 2017 Justin Kaufman. All rights reserved.
//

import Foundation
import AppKit
import Cocoa

class NetworkManager: NSObject {
    func fetchItems(for keywords: [String]? = nil, _ completion: @escaping (_ items: [NewsItem]) -> Void) {
        fetchItemData(keywords) { [unowned self] data in
            guard let data = data else { return completion([]) }
            self.parseItems(from: data) { items in
                self.fetchImages(for: items) { imagedItems in
                    completion(
                        imagedItems.sorted(by: { $0.imageURL.count > $1.imageURL.count })
                    )
                }
            }
        }
    }

    func fetchImages(for items: [NewsItem], _ completion: @escaping (_ imagedItems: [NewsItem]) -> Void) {
        guard !items.isEmpty else { return completion(items) }

        var imagedItems: [NewsItem] = []
        var index: Int = 0

        for var item in items {
            downloadImage(from: item.imageURL) { image in
                item.image = image
                imagedItems.append(item)
                index += 1
                if index == items.count { completion(imagedItems) }
            }
        }
    }
}

private extension NetworkManager {
    func fetchItemData(_ keywords: [String]? = nil, _ completion: @escaping (_ data: Data?) -> Void) {
        URLSession.shared.dataTask(
            with: URLRequest(url: Constants.queryURL(with: keywords)),
            completionHandler: { (data, response, error) -> Void in
                guard let data = data as Data? else { return completion(nil) }
                completion(data)
            }
        ).resume()
    }

    func parseItems(from data: Data, _ completion: @escaping (_ items: [NewsItem]) -> Void) {
        let parser = CrawlDataParser(with: data)
        parser.parseData { (success) -> Void in
            guard success else { return completion([]) }
            completion(parser.items)
        }
    }

    func downloadImage(from urlString: String, _ completion: @escaping (_ image: NSImage?) -> Void) {
        guard urlString.contains("https") else {
            return completion(NSImage(named: "newsIcon"))
        }

        URLSession.shared.dataTask(
            with: URLRequest(url: URL(string: urlString)!),
            completionHandler: { (data, response, error) -> Void in
                guard let data = data as Data? else { return completion(nil) }
                return completion(NSImage(data: data))
            }
        ).resume()
    }
}

private extension NetworkManager {
    struct Constants {
        static let googleNewsArticleDateFormat = "EEE, d MMM yyyy HH:mm:ss Z"
        static let imageTagRegex = "<img src=[^>]+>"
        static let imageTagUrlRegex = "\"//(.*?)\""

        static func queryURL(with keywords: [String]?) -> URL {
            let urlString: String = "https://news.google.com/" +
                ((keywords != nil) ? "news/feeds?q=\(keywords!.joined(separator: "%20"))&output=rss" : "?output=rss")
            return URL(string: urlString)!
        }
    }
}
