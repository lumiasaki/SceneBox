//
//  SceneBox.swift
//
//
//  Created by LumiaSaki on 2021/3/21.
//

import Foundation
import UIKit

public final class SceneBox {
    
    public typealias EntryBlock = (_ scene: Scene, _ sceneBox: SceneBox) -> Void
    public typealias ExitBlock = (_ sceneBox: SceneBox) -> Void
    
    public typealias SceneConstructionBlock = () -> Scene
    
    public let configuration: Configuration
    public let identifier: UUID = UUID()
    
    public private(set) var navigationController: UINavigationController?
    public private(set) var activeScene: Scene?
    public private(set) var stateSceneIdentifierTable: [Int : UUID] = Dictionary()
    public private(set) var extensions: [String : Extension] = Dictionary()
    
    public private(set) var entryBlock: EntryBlock
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
    
    public func lazyAdd(identifier: UUID, sceneBuilder: @escaping SceneConstructionBlock) {
        precondition(Thread.isMainThread)
        
        lazySceneConstructors[identifier] = sceneBuilder
    }
    
    public func lazyAdd(identifier: UUID, sceneBuilder: @autoclosure @escaping SceneConstructionBlock) {
        precondition(Thread.isMainThread)
        
        lazySceneConstructors[identifier] = sceneBuilder
    }
    
    public func execute() throws {
        processConfiguration()
        
        guard let entryTuple = findEntryScene(from: stateSceneIdentifierTable) else {
            throw SBXError.Scene.cantFindEntryScene
        }
        
        guard let _ = navigationController else {
            throw SBXError.Scene.navigationControllerNil
        }
        
        markSceneAsActive(scene: entryTuple.0)
        
        entryBlock(entryTuple.1, self)
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
    
    private func findEntryScene(from table: [Int : UUID]) -> (UUID, Scene)? {
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

extension SceneBox: SceneBoxPublicAbility {
    
    public func stateIdentifierStateMap() -> [Int : UUID] {
        return stateSceneIdentifierTable
    }
    
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
            
            let candidates = scenesIdentifierMap.values.filter {
                if viewControllers.contains($0) {
                    return true
                }
                
                if let parent = $0.parent, viewControllers.contains(parent) {
                    return true
                }
                
                return false
            }
            .map { $0.sceneIdentifier }
            
            candidates.forEach { scenesIdentifierMap.removeValue(forKey: $0!) }
            
            return
        }
        
        navigationController?.pushViewController(targetScene, animated: true)
    }
    
    public func markSceneAsActive(scene: UUID) {
        precondition(Thread.isMainThread)
        
        let targetScene = initiateSceneIfNeeded(from: scene)
        
        activeScene?.sceneWillUnload()
        targetScene.sceneDidLoaded()
        
        activeScene = targetScene
    }
    
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
    
    public func dispatch<T>(event: EventBus.EventName, message: T?) {
        eventBus.dispatch(event: event, userInfo: message)
    }
    
    public func watch<T>(on event: EventBus.EventName, messageType: T.Type, next: ((T?) -> Void)?) {
        eventBus.watch(on: event, type: messageType, next: next)
    }
    
}
