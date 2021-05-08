//
//  File.swift
//  
//
//  Created by zhutianren on 2021/5/6.
//

import Foundation

public struct LoggerMessage {
    
    public var content: String
    
    public init(content: String) {
        self.content = content
    }
}

public extension EventBus.EventName {
    
    static let loggerMessage: EventBus.EventName = EventBus.EventName(rawValue: "LoggerMessage")
}

public final class LoggerExtension: Extension {
    
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
