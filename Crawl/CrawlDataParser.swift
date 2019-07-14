//
//  CrawlDataParser.swift
//  Crawl
//
//  Created by Justin Kaufman on 3/23/17.
//  Copyright © 2017 Justin Kaufman. All rights reserved.
//

import Foundation
import AppKit
import Cocoa

class CrawlDataParser: NSObject {
    private var parser: XMLParser!
    private var element: String = ""
    private var itemTitle: String = ""
    private var itemDescription: String = ""
    private var itemImageURL: String = ""
    private var itemDate: String = ""
    private var itemURL: String = ""

    var items: [NewsItem] = []

    init(with data: Data) {
        super.init()
        parser = XMLParser(data: data)
        parser.shouldResolveExternalEntities = true
        parser.delegate = self
    }

    func parseData(_ completion: @escaping (_ success: Bool) -> Void) {
        guard parser.parse() else { return completion(false) }

        NetworkManager().fetchImages(for: items) { [unowned self] (imagedItems) -> Void in
            self.items = imagedItems
            completion(true)
        }
    }
}

extension CrawlDataParser: XMLParserDelegate {
    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String: String]) {
        element = elementName

        if element == "item" {
            itemTitle = ""
            itemDescription = ""
            itemImageURL = ""
            itemDate = ""
            itemURL = ""
        } else if ["media:content", "media:thumbnail"].contains(element) {
            if let url = attributeDict["url"] {
                itemImageURL = url
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch self.element {
        case "title":
            itemTitle += string
        case "description":
            itemDescription += string
        case "link":
            itemURL += string
        case "pubDate":
            itemDate += string
        default:
            break
        }
    }

    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        guard elementName == "item",
            !itemTitle.isEmpty,
            !itemDescription.isEmpty else {
                return
        }

        items.append(
            NewsItem(
                title: itemTitle,
                description: itemDescription.stripSymbols,
                imageURL: itemImageURL,
                date: itemDate.date,
                url: itemURL,
                image: nil
            )
        )
    }
}

private extension CrawlDataParser {
    struct Constants {
        static let dateFormat = "EEE, d MMM yyyy HH:mm:ss Z"
    }
}

fileprivate extension String {
    var date: Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = CrawlDataParser.Constants.dateFormat
        guard let date = dateFormatter.date(from: self) else { return Date() }
        return date
    }

    var stripSymbols: String {
        let length: Int = self.count
        var result: String = ""

        do {
            let regex = try NSRegularExpression(
                pattern: "<[^>]+>",
                options: NSRegularExpression.Options.caseInsensitive
            )

            result = regex.stringByReplacingMatches(
                in: self,
                options: NSRegularExpression.MatchingOptions.reportCompletion,
                range: NSMakeRange(0, length),
                withTemplate: ""
            )
        } catch {
            print("Error stripping symbols from string '\(self)': \(error)")
        }

        return result
    }
}
