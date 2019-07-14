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
    private var element = ""
    private var itemTitle = ""
    private var itemDescription = ""
    private var itemImageURL = ""
    private var itemDate = ""
    private var itemURL = ""
    var items: [NewsItem] = []

    init(with data: Data) {
        super.init()
        parser = XMLParser(data: data)
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
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch self.element {
        case "title": self.itemTitle += string
        case "description": self.itemDescription += string
        case "link": self.itemURL += string
        case "pubDate": self.itemDate += string
        default: break
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
                description: stringByStrippingHTML(itemDescription),
                imageURL: getLinkFromImageTag(itemDescription),
                date: date(from: itemDate),
                url: itemURL,
                image: nil
            )
        )
    }
}

private extension CrawlDataParser {
    func stringByStrippingHTML(_ input: String) -> String {
        let stringlength = input.count
        var newString = ""

        do {
            let regex = try NSRegularExpression(
                pattern: "<[^>]+>",
                options: NSRegularExpression.Options.caseInsensitive
            )

            newString = regex.stringByReplacingMatches(
                in: input,
                options: NSRegularExpression.MatchingOptions.reportCompletion,
                range: NSMakeRange(0, stringlength),
                withTemplate: ""
            )
        } catch {
            print("Error stripping HTML from input string: \(error)")
        }

        return newString
    }

    func getLinkFromImageTag(_ input: String) -> String {
        do {
            let regex = try NSRegularExpression(
                pattern: Constants.imageTagRegex,
                options: NSRegularExpression.Options.caseInsensitive
            )

            let results = regex.matches(
                in: input,
                options: NSRegularExpression.MatchingOptions.reportCompletion,
                range: NSMakeRange(0, input.count)
            )

            if let match = results.first as NSTextCheckingResult? {
                let str = input as NSString
                let imgTag = str.substring(with: match.range)

                do {
                    let imgRegex = try NSRegularExpression(
                        pattern: Constants.imageTagUrlRegex,
                        options: NSRegularExpression.Options.caseInsensitive
                    )

                    let imgResults = imgRegex.matches(
                        in: imgTag,
                        options: NSRegularExpression.MatchingOptions.reportCompletion,
                        range: NSMakeRange(0, imgTag.count)
                    )

                    if let imgMatch = imgResults.first as NSTextCheckingResult? {
                        let tagStr = imgTag as NSString
                        let imgURL = "http:" + tagStr
                            .substring(with: imgMatch.range)
                            .replacingOccurrences(of: "\"", with: "")

                        return imgURL
                    }

                } catch {
                    print("Error parsing URL from <img> tag: \(error)")
                }
            }
        } catch {
            print("Error parsing <img> tag: \(error)")
        }

        return ""
    }

    func date(from string: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.dateFormat
        guard let date = dateFormatter.date(from: string) else { return Date() }
        return date
    }
}

private extension CrawlDataParser {
    struct Constants {
        static let dateFormat = "EEE, d MMM yyyy HH:mm:ss Z"
        static let imageTagRegex = "<img src=[^>]+>"
        static let imageTagUrlRegex = "\"//(.*?)\""
    }
}
