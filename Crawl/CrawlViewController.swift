//
//  CrawlViewController.swift
//  Crawl
//
//  Created by Justin Kaufman on 3/23/17.
//  Copyright © 2017 Justin Kaufman. All rights reserved.
//

import Cocoa
import Foundation
import AppKit
import QuartzCore
import CoreLocation

class CrawlViewController: NSViewController {
    @IBOutlet weak var crawlField: MarqueeLabel!
    @IBOutlet weak var crawlImageButton: NSButton!

    private var dataSource: CrawlDataSource!

    override func viewDidLoad() {
        super.viewDidLoad()

        crawlField.stringValue = CrawlViewModel.syncModel.title
        crawlImageButton.image = CrawlViewModel.syncModel.image
        crawlField.scrollDelegate = self

        //let keyword: String? = getKeyword()
        dataSource = CrawlDataSource(keyword: "healthcare")

        loadNextItem()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        guard let window = view.window else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.titleVisibility = .hidden
    }

    @IBAction func clickCrawlImage(_ sender: AnyObject?) {
        NSWorkspace.shared.open(dataSource.currentItem.url)
    }

    func loadNextItem() {
        dataSource.nextItem { [weak self] item in
            self?.show(item)
        }
    }

    func show(_ item: CrawlViewModel) {
        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = 1.0
            self?.crawlField.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            guard let self = self else { return }

            self.crawlImageButton.image = item.image
            self.crawlField.stringValue = " " + item.title

            NSAnimationContext.runAnimationGroup({ [weak self] _ in
                NSAnimationContext.current.duration = 0.75
                self?.crawlField.animator().alphaValue = 1.0
            }, completionHandler: {})
        })
    }
}

extension CrawlViewController: MarqueeLabelDelegate {
    func didFinishScrolling(_ string: String) {
        loadNextItem()
    }
}

private extension CrawlViewController {
    func getKeyword() -> String {
        let alert = NSAlert()
        alert.messageText = "Crawl Keyword"
        alert.informativeText = "Enter a keyword or leave blank for general results"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Submit")

        let keywordField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        keywordField.placeholderString = "Keyword"
        alert.accessoryView = keywordField
        alert.runModal()

        return keywordField.stringValue
    }
}
