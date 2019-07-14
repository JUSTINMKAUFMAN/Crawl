//
//  AppDelegate.swift
//  LiveCrawl
//
//  Created by Justin Kaufman on 3/23/17.
//  Copyright © 2017 Justin Kaufman. All rights reserved.
//

import Cocoa
import AppKit
import Foundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var window: NSWindow!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window.isOpaque = false
        window?.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.titleVisibility = NSWindow.TitleVisibility.hidden
        window.backgroundColor = NSColor.clear
        window.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
        window.contentViewController = CrawlViewController()
    }
}
