//
//  Extension.swift
//  
//
//  Created by LumiaSaki on 2021/3/21.
//

import Foundation

public protocol Extension: ExtensionLifeCycle, SceneBoxLifeCycle, AnyObject {                
    
    /// weak scene box
    var sceneBox: SceneBox? { set get }
}

extension Extension {
    
    public func logger(content: String) {
        sceneBox?.dispatch(event: EventBus.EventName.loggerMessage, message: LoggerMessage(content: content))
    }
}
