//
//  LoggerExtension.swift
//  SceneBox
//
//  Created by Lumia_Saki on 2021/5/6.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation

/// Data structure for built-in simply Logger extension.
public struct LoggerMessage {
    
    /// The content about the log message.
    public var content: String
    
    /// Initializer for `LoggerMessage`.
    /// - Parameter content: The content you want to pass to the logger extension.
    public init(content: String) {
        self.content = content
    }
}

public extension EventBus.EventName {
    
    /// The event name for built-in logger extension, once the extension receive the event it will print the content from the message.
    static let loggerMessage: EventBus.EventName = EventBus.EventName(rawValue: "LoggerMessage")
}

public final class LoggerExtension: Extension {
    
    // MARK: - Extension
    
    /// Associated SceneBox, should always be weak.
    public weak var sceneBox: SceneBox?
    
    public func extensionDidMount() {
        sceneBox?.watch(on: .loggerMessage, messageType: LoggerMessage.self, next: { message in
            guard let message = message else {
                return
            }
            
            print(message)
        })
    }
}
