//
//  SharedStateExtension.swift
//  SceneBox
//
//  Created by Lumia_Saki on 2021/4/30.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "Use `SharedStateInjected<T>` instead.")
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

/// Property wrapper for helping developers to simplify state sharing among different `Scene`s, the principle of it is similar to `Environment` in SwiftUI, all `Scene`s share same source of truth through the `SharedStateExtension`, use this property wrapper will make developer to manipulate variables as normal properties, the only difference is that this one is backed by `SharedStateExtension` in static-type ( key path ) way.
/// Notice: Because the property wrapper needs an instance of `Scene` to get capability from it, since that, you need to configure it before using it by calling `configure(scene:)` in a proper place.
@propertyWrapper
public struct SharedStateInjected<T> {
    
    private var scene: Scene?
    
    private let keyPath: WritableKeyPath<SharedStateValues, T?>
    
    public mutating func configure(scene: Scene?) {
        self.scene = scene
    }
    
    public var wrappedValue: T? {
        get {
            guard let scene = scene else {
                fatalError("configure scene firstly")
            }
                        
            return scene.sbx.getSharedState(by: keyPath)
        }
        
        set {
            guard let scene = scene else {
                fatalError("configure scene firstly")
            }
            
            scene.sbx.putSharedState(by: keyPath, sharedState: newValue)
        }
    }
    
    public init(_ keyPath: WritableKeyPath<SharedStateValues, T?>) {
        self.keyPath = keyPath
    }
}

/// This is an entry point for your custom keys.
/// A case about how to create a custom key for your logic:
/// ```swift
/// struct TimestampKey: SharedStateKey {
///
///   // this will give compiler a hint about concrete type.
///   static var currentValue: TimeInterval?
/// }
/// ```
public protocol SharedStateKey {
    
    associatedtype ValueType
    
    static var currentValue: ValueType? { get set }
}

/// This is an entry point for extending your values.
/// A case about how to create a key path for your value as below:
/// ```swift
/// extension SharedStateValues {
///
///   // this will generate a key path for `timestamp` variable.
///   var timestamp: TimeInterval? {
///     get { Self[TimestampKey.self] }
///     set { Self[TimestampKey.self] = newValue }
///   }
/// }
/// ```
public struct SharedStateValues {
    
    public static var current = SharedStateValues()
    
    public static subscript<K: SharedStateKey>(key: K.Type) -> K.ValueType? {
        get { key.currentValue }
        set { key.currentValue = newValue }
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
    
    @available(*, deprecated, message: "Use `stateValue` instead.")
    private var state: [AnyHashable : Any] = Dictionary()
    
    private var stateValue: SharedStateValues = SharedStateValues()
    
    fileprivate func setSharedState<T>(_ sharedState: T?, on keyPath: WritableKeyPath<SharedStateValues, T?>) {
        workerQueue.async(flags: .barrier) {
            self.stateValue[keyPath: keyPath] = sharedState
            
            self.sceneBox?.dispatch(event: EventBus.EventName.sharedStateChanges, message: SharedStateMessage(key: keyPath, state: sharedState))
            self.logger(content: "shared state changes: key: \(keyPath), state: \(String(describing: sharedState))")
        }
    }
    
    fileprivate func querySharedState<T>(by keyPath: WritableKeyPath<SharedStateValues, T?>) -> T? {
        var result: T?
        
        workerQueue.sync {
            result = stateValue[keyPath: keyPath]
        }
        
        return result
    }
}

extension SceneCapabilityWrapper {
    
    /// Receiving a shared state from the shared store if it exists.
    /// - Parameter key: The key of the data you want to fetch from the store.
    /// - Returns: The shared state stored in the extension. Nil if the data not exists with the provided key.
    @available(*, deprecated, message: "Use `getSharedState<T>(by keyPath: WritableKeyPath<SharedStateValues, T?>) -> T?` instead.")
    public func getSharedState(by key: AnyHashable) -> Any? {
        guard let ext = try? _getExtension(by: SharedStateExtension.self) else {
            return nil
        }
        
        return ext.querySharedState(by: key)
    }
    
    /// Receiving a shared state from the shared store if it exists.
    /// - Parameter keyPath: Key path to the value by extending `SharedStateValues`.
    /// - Returns: The shared state stored in the extension. Nil if the data not exists with the provided key path.
    public func getSharedState<T>(by keyPath: WritableKeyPath<SharedStateValues, T?>) -> T? {
        guard let ext = try? _getExtension(by: SharedStateExtension.self) else {
            return nil
        }
        
        return ext.querySharedState(by: keyPath)
    }
    
    /// Putting a shared state to the shared store.
    /// - Parameters:
    ///   - key: The key of the data you want to put into the store.
    ///   - sharedState: The shared state you want to save. Nil if you want to remove the data from the store.
    @available(*, deprecated, message: "Use `putSharedState<T>(by keyPath: WritableKeyPath<SharedStateValues, T?>, sharedState: T?)` instead.")
    public func putSharedState(by key: AnyHashable, sharedState: Any?) {
        guard let ext = try? _getExtension(by: SharedStateExtension.self) else {
            return
        }
        
        ext.setSharedState(sharedState, on: key)
    }
    
    /// Putting a shared state to the shared store.
    /// - Parameters:
    ///   - keyPath: Key path to the value by extending `SharedStateValues`.
    ///   - sharedState: The shared state you want to save. Nil if you want to remove the data from the store.
    public func putSharedState<T>(by keyPath: WritableKeyPath<SharedStateValues, T?>, sharedState: T?) {
        guard let ext = try? _getExtension(by: SharedStateExtension.self) else {
            return
        }
        
        ext.setSharedState(sharedState, on: keyPath)
    }
}

// MARK: - Deprecated

extension SharedStateExtension {
    
    @available(*, deprecated, message: "Use `querySharedState<T>(by keyPath: WritableKeyPath<SharedStateValues, T?>) -> T?` instead.")
    fileprivate func querySharedState(by key: AnyHashable) -> Any? {
        var result: Any?
        
        workerQueue.sync {
            result = state[key]
        }
        
        return result
    }
    
    @available(*, deprecated, message: "Use `setSharedState<T>(_ sharedState: T?, on keyPath: WritableKeyPath<SharedStateValues, T?>)` instead.")
    fileprivate func setSharedState(_ sharedState: Any?, on key: AnyHashable) {
        workerQueue.async(flags: .barrier) {
            self.state[key] = sharedState
            
            self.sceneBox?.dispatch(event: EventBus.EventName.sharedStateChanges, message: SharedStateMessage(key: key, state: sharedState))
            self.logger(content: "shared state changes: key: \(key), state: \(String(describing: sharedState))")
        }
    }
}
