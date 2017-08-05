//
//  SynchroScrollView.swift
//  TextViewTests
//
//  Created by Alex Moffat on 7/29/17.
//  Copyright © 2017 Zanthan. All rights reserved.
//

import AppKit
import Foundation

class SynchroScrollView: NSScrollView {
    
    weak var synchronizedView: NSScrollView?
    
    var paused = false
    
    func setSynchronziedScrollView(view: NSScrollView) {
        
        stopSynchronizing()
        
        synchronizedView = view
        
        let contentView = view.contentView
        
        contentView.postsBoundsChangedNotifications = true
        
        NotificationCenter.default.addObserver(forName: Notification.Name.NSViewBoundsDidChange, object: contentView, queue: nil, using: synchroViewContentBoundsDidChange)
    }
    
    func stopSynchronizing() {
        
        if let contentView = synchronizedView?.contentView {
            NotificationCenter.default.removeObserver(self, name: Notification.Name.NSViewBoundsDidChange, object: contentView)
            synchronizedView = nil
        }
    }
    
    func synchroViewContentBoundsDidChange(notification: Notification) {
        if !paused {            
            synchroViewContentBoundsDidChange(notifyingView: notification.object as! NSClipView)
        }
    }
    
    func synchroViewContentBoundsDidChange(notifyingView: NSClipView) {    
        let changedBoundsOrigin = notifyingView.documentVisibleRect.origin
        
        let currentOffset = contentView.bounds.origin
        
        if !NSEqualPoints(currentOffset, changedBoundsOrigin) {
            var newOffset = currentOffset
            newOffset.y = changedBoundsOrigin.y

            contentView.scroll(to: newOffset)
            
            reflectScrolledClipView(contentView)
        }
    }
}
