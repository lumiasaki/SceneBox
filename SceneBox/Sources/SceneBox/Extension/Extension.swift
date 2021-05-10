//
//  Extension.swift
//  SceneBox
//
//  Created by Lumia_Saki on 2021/3/21.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation

/// Extension is a type for extending SceneBox capabilities, which can rely on the capabilities exposed by the SceneBox in `SceneBoxCapabilityOutlet`.
public protocol Extension: ExtensionLifeCycle, SceneBoxLifeCycle, AnyObject {                
    
    /// Associated SceneBox, should always be weak.
    var sceneBox: SceneBox? { get set }
}

extension Extension {
    
    /// A convenience function for logging messages in extension, the log action will be delegated to `LoggerExtension`.
    /// - Parameter content: Content of message.
    public func logger(content: String) {
        sceneBox?.dispatch(event: EventBus.EventName.loggerMessage, message: LoggerMessage(content: content))
    }
}
