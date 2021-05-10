//
//  InternalMessageSupport.swift
//  SceneBox
//
//  Created by Lumia_Saki on 2021/5/8.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation

/// Deliver messages between extensions within the `SceneBox` system, for decoupling extensions purpose.
public protocol InternalMessageSupport {
    
    associatedtype EventName
    
    /// Dispatch an event, with necessary information within a generic type message.
    /// - Parameters:
    ///   - event: Event name of the event, with generic EvenName type.
    ///   - message: The additional information you want to pass to the receiver.
    func dispatch<T>(event: EventName, message: T?)
    
    /// Watching on an event, for receiving `next` callback when the event occurred asynchronously.
    /// - Parameters:
    ///   - event: The name of event, with generic EventName type.
    ///   - messageType: The type of message, will be a hint for compiler to know which actual type of message in `next` closure.
    ///   - next: A callback called when the event being dispatched.
    func watch<T>(on event: EventName, messageType: T.Type, next: ((T?) -> Void)?)
}
