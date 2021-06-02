//
//  SceneBox.swift
//  SceneBox
//
//  Created by Lumia_Saki on 2021/3/21.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation
import UIKit

/// It's a mechanism what really helpful and suitable for those processes which can not be interrupted, fully decoupled, might be reordered in the future, contains a lot of states need to be shared.
/// You can create `SceneBox`s to launch a series of your processes.
public final class SceneBox {
    
    public typealias EntryBlock = (_ scene: Scene, _ sceneBox: SceneBox) -> Void
    public typealias ExitBlock = (_ sceneBox: SceneBox) -> Void
    
    public typealias SceneConstructionBlock = () -> Scene
    
    /// Configuration of current `SceneBox`, contains any necessary information needed by `SceneBox` executing.
    public let configuration: Configuration
    
    /// The unique identifier of `SceneBox`.
    public let identifier: UUID = UUID()
        
    /// Navigation controller drive the transition between `Scene`s.
    public private(set) var navigationController: UINavigationController?
    
    /// Return the current active `Scene` instance, nil before executing.
    public private(set) weak var activeScene: Scene?
    
    /// The Map of state of scenes and their corresponding identifiers, assigned from `Configuration`.
    public private(set) var stateSceneIdentifierTable: [Int : UUID] = Dictionary()
    
    /// Enabled extensions, set from `Configuration`.
    public private(set) var extensions: [String : Extension] = Dictionary()
    
    /// Entry block, you can customize any further within the entry block to implement your own logics.
    public private(set) var entryBlock: EntryBlock
    
    /// Exit block, you can make any clean up stuffs in the block.
    public private(set) var exitBlock: ExitBlock
    
    // MARK: - Private Properties
        
    private var scenesIdentifierMap: [UUID : Scene] = Dictionary()
    private var lazySceneConstructors: [UUID : SceneConstructionBlock] = Dictionary()
    
    private lazy var eventBus: EventBus = EventBus()
    
    init(configuration: Configuration, entry: @escaping EntryBlock, exit: @escaping ExitBlock) {
        self.configuration = configuration
        self.entryBlock = entry
        self.exitBlock = exit
    }
    
    /// Lazily add a scene with a construction block and the identifier.
    /// - Parameters:
    ///   - identifier: Unique identifier of the scene. Notice: the identifier plays different roles than the state of scene. The state should be relative with your business logic.
    ///   - sceneBuilder: You should return an instance of `Scene` in the closure.
    public func lazyAdd(identifier: UUID, sceneBuilder: @escaping SceneConstructionBlock) {
        precondition(Thread.isMainThread)
        
        lazySceneConstructors[identifier] = sceneBuilder
    }
    
    /// Lazily add a scene with a construction block and the identifier, the only difference with above is `@autoclosure` this version.
    /// - Parameters:
    ///   - identifier: Unique identifier of the scene.
    ///   - sceneBuilder: `Autoclosure` version of construction block.
    public func lazyAdd(identifier: UUID, sceneBuilder: @autoclosure @escaping SceneConstructionBlock) {
        precondition(Thread.isMainThread)
        
        lazySceneConstructors[identifier] = sceneBuilder
    }
    
    /// Launch the process of `SceneBox`, the `EntryBlock` will be invoked, give you a chance to customize anything, setup the context for entry scene, inject any reserved shared state into the shared store, etc. Once you `execute` the `SceneBox`, the process acts as a box from outside aspect, all navigations and state sharing within the box.
    /// You can call this function manually, but if you do that you need to manage the life-cycle of `SceneBox` manually as well, we recommend you to use `Executor` to `execute` a instance of `SceneBox`.
    /// - Throws: `SBXError.Scene.cantFindEntryScene` if box can not find the entry scene from your `scenesIdentifierMap`.
    /// - Throws: `SBXError.Scene.navigationControllerNil` if navigation controller is nil when executing.
    public func execute() throws {
        processConfiguration()
        
        guard let entryTuple = findEntryScene(from: stateSceneIdentifierTable) else {
            throw SBXError.Scene.cantFindEntryScene
        }
        
        guard let _ = navigationController else {
            throw SBXError.Scene.navigationControllerNil
        }
        
        markSceneAsActive(scene: entryTuple.identifier)
        
        entryBlock(entryTuple.scene, self)
    }
    
    // MARK: - Private Methods
    
    private func processConfiguration() {
        navigationController = configuration.navigationController
        stateSceneIdentifierTable = configuration.stateSceneIdentifierTable
        
        setUpExtensions()
    }
    
    private func setUpExtensions() {
        extensions = configuration.extensions
        extensions.values.forEach { [weak self] in
            $0.sceneBox = self
            $0.extensionDidMount()
        }
    }
    
    private func findEntryScene(from table: [Int : UUID]) -> (identifier: UUID, scene: Scene)? {
        guard let candidate = table.first(where: {
            return $0.key == NavigationExtension.entry
        }) else {
            return nil
        }
        
        guard let sceneIdentifier = stateSceneIdentifierTable[candidate.key] else {
            return nil
        }
            
        let entryScene = initiateSceneIfNeeded(from: sceneIdentifier)
        
        return (sceneIdentifier, entryScene)
    }
    
    private func initiateSceneIfNeeded(from identifier: UUID) -> Scene {
        guard let targetScene = scene(by: identifier) else {
            if let scene = lazySceneConstructors[identifier]?() {
                // set the real scene to scenes dictionary
                scenesIdentifierMap[identifier] = scene
                
                // associate scenebox to scene
                scene.sceneBox = self
                
                // fill identifier
                attachSceneIdentifier(to: scene, identifier: identifier)
                
                return scene
            }
            
            fatalError("can't get scene from identifier")
        }
        
        return targetScene
    }
    
    private func scene(by identifier: UUID) -> Scene? {
        return scenesIdentifierMap[identifier]
    }
    
    private func attachSceneIdentifier(to scene: Scene, identifier: UUID) {
        scene.sceneIdentifier = identifier
    }
}

extension SceneBox: SceneBoxCapabilityOutlet {
    
    /// For retrieving current `stateIdentifierStateMap`.
    /// - Returns: Current `stateIdentifierStateMap`.
    public func stateIdentifierStateMap() -> [Int : UUID] {
        return stateSceneIdentifierTable
    }
    
    /// Navigate from one scene to another, by using the identifier of scene. `Extension`s are inaccessible to the real `Scene` instance, what all they can do is building a shadow DOM tree based on identifiers of `Scene`s.
    /// - Parameter scene: The identifier of an instance of `Scene`.
    public func navigate(to scene: UUID) {
        precondition(Thread.isMainThread)
        
        guard let viewControllers = navigationController?.viewControllers else {
            return
        }
        
        func tryToFindChildViewControllerIfExists(scene: Scene) -> Bool {
            for viewController in viewControllers {
                if viewController.children.contains(scene) {
                    return true
                }
            }
            
            return false
        }
        
        let targetScene = initiateSceneIfNeeded(from: scene)
        
        if viewControllers.contains(targetScene) || tryToFindChildViewControllerIfExists(scene: targetScene) {
            if !viewControllers.contains(targetScene), let parent = targetScene.parent {
                navigationController?.popToViewController(parent, animated: true)
            } else {
                navigationController?.popToViewController(targetScene, animated: true)
            }
            
            if let viewControllers = navigationController?.viewControllers {
                let candidates = scenesIdentifierMap.values.filter {
                    if viewControllers.contains($0) {
                        return false
                    }
                    
                    if let parent = $0.parent, viewControllers.contains(parent) {
                        return false
                    }
                    
                    return true
                }
                .map { $0.sceneIdentifier }
                
                candidates.forEach { scenesIdentifierMap.removeValue(forKey: $0!) }
            }
            
            return
        }
        
        navigationController?.pushViewController(targetScene, animated: true)
    }
    
    /// Maintaining and keeping sync of state of the active scene is the job of `NavigationExtension` ( no matter the built-in one or your custom extensions ).
    /// - Parameter scene: The identifier of an instance of `Scene`.
    public func markSceneAsActive(scene: UUID) {
        precondition(Thread.isMainThread)
        
        let targetScene = initiateSceneIfNeeded(from: scene)
        
        activeScene?.sceneWillUnload()
        targetScene.sceneDidLoaded()
        
        activeScene = targetScene
    }
    
    /// Ask `SceneBox` to be terminated, `SceneBox` will take over any internal cleanup works, call relative life-cycle functions, remove any unnecessary stuffs from memory, call `exitBlock` at last.
    public func terminateBox() {
        precondition(Thread.isMainThread)
        
        // notify last scene will be unloaded
        if let activeScene = activeScene {
            activeScene.sceneWillUnload()
        }
        
        // notify scenes
        scenesIdentifierMap.values.forEach { $0.sceneBoxWillTerminate() }
        
        // notify extensions
        extensions.values.forEach { $0.sceneBoxWillTerminate() }
        
        exitBlock(self)
    }
    
}

extension SceneBox: InternalMessageSupport {
    
    /// `Extension` can extend capability of `SceneBox`, in some scenarios, extensions need exchange information between themselves.
    /// Dispatching a message with an event name.
    /// - Parameters:
    ///   - event: The name of the event.
    ///   - message: The message instance.
    public func dispatch<T>(event: EventBus.EventName, message: T?) {
        eventBus.dispatch(event: event, message: message)
    }
    
    /// Watching on a message with its name.
    /// - Parameters:
    ///   - event: The name of the event.
    ///   - messageType: The type of the message, it will be a hint for the compiler to know what the actual type is in `next` closure.
    ///   - next: The closure which will be invoked when the message been dispatched.
    public func watch<T>(on event: EventBus.EventName, messageType: T.Type, next: ((T?) -> Void)?) {
        eventBus.watch(on: event, messageType: messageType, next: next)
    }
    
}
