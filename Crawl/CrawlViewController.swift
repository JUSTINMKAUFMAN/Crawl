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
    private var keywords: [String] = ["technology"]

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = CrawlDataSource(keywords: keywords)
        let keywords: [String]? = getKeywords()
        setupSubviews()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        
        guard let window = view.window else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.titleVisibility = .hidden
        window.makeKeyAndOrderFront(self)

        loadNextItem()
    }

    @IBAction func clickCrawlImage(_ sender: AnyObject?) {
        NSWorkspace.shared.open(dataSource.currentItem.url)
    }
}

private extension CrawlViewController {
    func setupSubviews() {
        crawlField.stringValue = CrawlViewModel.syncModel.title
        crawlImageButton.image = CrawlViewModel.syncModel.image
        crawlField.scrollDelegate = self
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

            self.crawlImageButton.image = item.image ?? NSImage(named: "newsIcon")!
            self.crawlImageButton.displayIfNeeded()
            self.crawlField.stringValue = " " + item.title

            NSAnimationContext.runAnimationGroup({ [weak self] _ in
                NSAnimationContext.current.duration = 0.75
                self?.crawlField.animator().alphaValue = 1.0
            }, completionHandler: {})
        })
    }

    func getKeywords() -> [String]? {
        let alert = NSAlert()
        alert.messageText = "Crawl Keywords"
        alert.informativeText = "Enter keywords separated by spaces or leave blank for general results"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Submit")

        let keywordField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        keywordField.placeholderString = "Ex: technology apple"
        alert.accessoryView = keywordField
        alert.runModal()
        let value = keywordField.stringValue
        guard !value.isEmpty && value != " " else { return nil }
        return value.contains(" ") ? value.components(separatedBy: " ") : [value]
    }
}

extension CrawlViewController: MarqueeLabelDelegate {
    func didFinishScrolling(_ string: String) {
        loadNextItem()
    }
}
