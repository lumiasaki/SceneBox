//
//  File.swift
//  
//
//  Created by zhutianren on 2021/5/6.
//

import Foundation

public final class EventBus {        
    
    public struct EventName: RawRepresentable, Equatable, Hashable {
        
        public var rawValue: String
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
    
    private struct NextActionContainer {
        
        var inner: Any?
    }
    
    private var workerQueue: DispatchQueue = DispatchQueue.init(label: "com.scenebox.eventbus.queue")
    private var eventNameNextMap: [EventBus.EventName : [(queue: DispatchQueue, next: NextActionContainer)]] = Dictionary()
    
    public func dispatch<T>(event: EventName, userInfo: T?) {
        workerQueue.async {
            guard let nexts = self.eventNameNextMap[event] else {
                return
            }
            
            nexts.forEach { tuple in
                if let next = tuple.next.inner as? (T?) -> Void {
                    tuple.queue.async {
                        next(userInfo)
                    }
                }
            }
        }
    }
    
    public func watch<T>(on event: EventName, queue: DispatchQueue = .global(), type: T.Type, next: ((T?) -> Void)?) {
        workerQueue.async {
            self.eventNameNextMap[event] = self.eventNameNextMap[event] ?? []
            self.eventNameNextMap[event]?.append((queue, NextActionContainer(inner: next)))
        }
    }
}
