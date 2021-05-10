//
//  EventBus.swift
//  SceneBox
//
//  Created by Lumia_Saki on 2021/5/6.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation

/// A simple and workable event bus for dispatching and watching events between Extensions of SceneBox, for decoupling between different extensions.
public final class EventBus {        
    
    /// Name for watching and dispatching event, can be extended by the user.
    public struct EventName: RawRepresentable, Equatable, Hashable {
        
        /// Raw value for the event name, the user can extend event name just like `static let log = EventName(rawValue: "Log")`.
        public var rawValue: String
        
        /// Initializer for event name.
        /// - Parameter rawValue: Event name literally.
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
    
    fileprivate struct NextActionContainer {
        
        fileprivate var inner: Any?
    }
    
    private var workerQueue: DispatchQueue = DispatchQueue.init(label: "com.scenebox.event-bus.queue")
    private var eventNameNextMap: [EventBus.EventName : [(queue: DispatchQueue, next: NextActionContainer)]] = Dictionary()
    
    /// Dispatch an event, with necessary information within a generic type message.
    /// - Parameters:
    ///   - event: Event name of the event, should be one of instances of EventBus.EventName.
    ///   - message: The additional information you want to pass to the receiver.
    public func dispatch<T>(event: EventName, message: T?) {
        workerQueue.async {
            guard let nexts = self.eventNameNextMap[event] else {
                return
            }
            
            nexts.forEach { tuple in
                if let next = tuple.next.inner as? (T?) -> Void {
                    tuple.queue.async {
                        next(message)
                    }
                }
            }
        }
    }
    
    /// Watching on an event, for receiving `next` callback when the event occurred asynchronously.
    /// - Parameters:
    ///   - event: Event name of the event, should be one of instances of EventBus.EventName.
    ///   - queue: The `next` closure be called on which queue, the default is global queue in order to avoid dead-lock situation when using `semaphore` to make some functionalities sync.
    ///   - messageType: Message type for letting compiler knows the actual type in `next` closure.
    ///   - next: A callback called when the event being dispatched.
    public func watch<T>(on event: EventName, queue: DispatchQueue = .global(), messageType: T.Type, next: ((T?) -> Void)?) {
        workerQueue.async {
            self.eventNameNextMap[event] = self.eventNameNextMap[event] ?? []
            self.eventNameNextMap[event]?.append((queue, NextActionContainer(inner: next)))
        }
    }
}
