//
//  File.swift
//  
//
//  Created by zhutianren on 2021/5/8.
//

import Foundation

public protocol InternalMessageSupport {
    
    func dispatch<T>(event: EventBus.EventName, message: T?)
    func watch<T>(on event: EventBus.EventName, messageType: T.Type, next: ((T?) -> Void)?)
}
