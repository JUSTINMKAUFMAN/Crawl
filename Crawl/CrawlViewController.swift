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
    private var keywords: [String]? = ["technology", "software"]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        setupDataSource()
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
    }

    @IBAction func clickCrawlImage(_ sender: AnyObject?) {
        NSWorkspace.shared.open(dataSource.currentItem.url)
    }
}

private extension CrawlViewController {
    func setupSubviews() {
        crawlField.scrollDelegate = self
        crawlField.stringValue = CrawlViewModel.syncModel.title
        crawlImageButton.image = CrawlViewModel.syncModel.image
    }

    func setupDataSource() {
        dataSource = CrawlDataSource(keywords: keywords)
        loadNextItem()
    }

    func loadNextItem() {
        dataSource.nextItem { [weak self] item in
            guard let self = self else { return }
            self.show(item)
        }
    }

    func show(_ item: CrawlViewModel) {
        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = 0.75
            self?.crawlField.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            guard let self = self else { return }

            self.crawlImageButton.image = item.image ?? NSImage(named: "newsIcon")!
            self.crawlImageButton.displayIfNeeded()
            self.crawlField.stringValue = " " + item.title
            self.crawlField.scrollTextField()

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
