//
//  AppDelegate.swift
//  Borkle
//
//  Created by markd on 9/10/20.
//  Copyright © 2020 Borkware. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        
        let documentController = NSDocumentController.shared
        
        if let mostRecentDocument = documentController.recentDocumentURLs.first {
            documentController.openDocument(withContentsOf: mostRecentDocument, 
                display: true, 
                completionHandler: { (document, documentWasAlreadyOpen, errorWhileOpening) in
                    Swift.print("Error restoring document \(String(describing: errorWhileOpening))")
                })
            return false
        } else {
            return true
        }
    }
}

