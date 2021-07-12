//
//  SharedStateExtension.swift
//  SceneBox
//
//  Created by Lumia_Saki on 2021/4/30.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation

@propertyWrapper
public class SceneBoxSharedStateInjected<T> {
    
    private let key: AnyHashable
    private var scene: Scene?
    
    public init(key: AnyHashable) {
        self.key = key
    }
    
    public func configure(scene: Scene?) {
        self.scene = scene
    }
    
    public var wrappedValue: T? {
        get {
            guard let scene = scene else {
                fatalError("configure scene firstly")
            }
                        
            return scene.sbx.getSharedState(by: key) as? T
        }
        
        set {
            guard let scene = scene else {
                fatalError("configure scene firstly")
            }
            
            scene.sbx.putSharedState(by: key, sharedState: newValue)
        }
    }
}

/// Message data structure for shared state extension to exchange information with other extensions in the SceneBox.
public struct SharedStateMessage {
    
    /// The key of a shared state tuple.
    public var key: AnyHashable?
    
    /// The value of a shared state tuple.
    public var state: Any?
    
    /// Initializer of the SharedStateMessage.
    /// - Parameters:
    ///   - key: The key of the shared state.
    ///   - state: The value of the shared state.
    public init(key: AnyHashable?, state: Any?) {
        self.key = key
        self.state = state
    }
}

public extension EventBus.EventName {
    
    /// The event name of shared state changes event.
    static let sharedStateChanges: EventBus.EventName = EventBus.EventName(rawValue: "SharedStateChanges")
}

/// The built-in extension for supporting data fetching and putting between scenes, without passing data scene by scene.
public final class SharedStateExtension: Extension {
    
    // MARK: - Extension
    
    /// Associated SceneBox, should always be weak.
    public weak var sceneBox: SceneBox?
    
    // MARK: - Private
    
    private let workerQueue = DispatchQueue(label: "com.scenebox.shared-state.queue", attributes: .concurrent)
    private var state: [AnyHashable : Any] = Dictionary()
    
    fileprivate func querySharedState(by key: AnyHashable) -> Any? {
        var result: Any?
        
        workerQueue.sync {
            result = state[key]
        }
        
        return result
    }
    
    fileprivate func setSharedState(_ sharedState: Any?, on key: AnyHashable) {
        workerQueue.async(flags: .barrier) {
            self.state[key] = sharedState
            
            self.sceneBox?.dispatch(event: EventBus.EventName.sharedStateChanges, message: SharedStateMessage(key: key, state: sharedState))
            self.logger(content: "shared state changes: key: \(key), state: \(String(describing: sharedState))")
        }
    }
    
}

extension SceneCapabilityWrapper {
    
    /// Receiving a shared state from the shared store if it exists.
    /// - Parameter key: The key of the data you want to fetch from the store.
    /// - Returns: The shared state stored in the extension. Nil if the data not exists with the provided key.
    public func getSharedState(by key: AnyHashable) -> Any? {
        guard let ext = try? _getExtension(by: SharedStateExtension.self) else {
            return nil
        }
        
        return ext.querySharedState(by: key)
    }
    
    /// Putting a shared state to the shared store.
    /// - Parameters:
    ///   - key: The key of the data you want to put into the store.
    ///   - sharedState: The shared state you want to save. Nil if you want to remove the data from the store.
    public func putSharedState(by key: AnyHashable, sharedState: Any?) {
        guard let ext = try? _getExtension(by: SharedStateExtension.self) else {
            return
        }
        
        ext.setSharedState(sharedState, on: key)
    }
}
