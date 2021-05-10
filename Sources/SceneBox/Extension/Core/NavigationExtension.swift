//
//  NavigationExtension.swift
//  SceneBox
//
//  Created by Lumia_Saki on 2021/3/29.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation
import UIKit

/// Message data structure for built-in navigation extension, be used for exchanging navigation trace information between extensions.
public struct NavigationTraceMessage {
    
    /// The source scene state.
    public var from: Int?
    
    /// The destination scene state.
    public var to: Int?
    
    /// Initializer for NavigationTraceMessage.
    /// - Parameters:
    ///   - from: The source scene state.
    ///   - to: The destination scene state.
    public init(from: Int?, to: Int?) {
        self.from = from
        self.to = to
    }
}

/// Message data structure for built-in navigation extension, be used for exchanging all scene states among the extensions.
public struct NavigationGetScenesMessage {
    
    /// The exist scene states, in appear order.
    public var scenes: [Int]?
    
    /// Initializer for NavigationGetScenesMessage.
    /// - Parameter scenes: Scene states.
    public init(scenes: [Int]?) {
        self.scenes = scenes
    }
}

public extension EventBus.EventName {
    
    /// Event name for taking a look to navigation trace.
    static let navigationTrack: EventBus.EventName = .init(rawValue: "EventTrack")
    
    /// The name for requesting the scene states.
    static let getStatesRequest: EventBus.EventName = .init(rawValue: "GetScenesRequest")
    
    /// The name for responding the scene states when receiving the `getStatesRequest` event.
    static let getStatesResponse: EventBus.EventName = .init(rawValue: "GetScenesResponse")
}

/// Built-in navigation extension for SceneBox, manages the transition state trance inside, manipulate transition between scenes. Assuming all scene state in `Int` format.
public final class NavigationExtension: NSObject, Extension {
    
    /// Entry state of navigation, when you execute a SceneBox, it will try to find the entry one.
    public static let entry: Int = .min
    
    /// Termination state of navigation, transit to this state when you try to terminate the SceneBox.
    public static let termination: Int = .max
    
    // MARK: - Extension
    
    /// Associated SceneBox, should always be weak.
    public weak var sceneBox: SceneBox?
    
    private var stateTrace: [Int] = Array()
    private var currentState: Int? { stateTrace.last }
    private var previousNavigationControllerDelegate: UINavigationControllerDelegate?
    
    public func extensionDidMount() {
        // insert entry into state trace
        stateTrace.append(Self.entry)
        
        previousNavigationControllerDelegate = sceneBox?.navigationController?.delegate
        sceneBox?.navigationController?.delegate = self
        
        sceneBox?.watch(on: EventBus.EventName.getStatesRequest, messageType: Void.self, next: { [unowned self] _ in
            self.sceneBox?.dispatch(event: EventBus.EventName.getStatesResponse, message: NavigationGetScenesMessage(scenes: stateTrace))
        })
    }
    
    // MARK: - Private
    
    fileprivate func transit(to state: Int) {
        precondition(Thread.isMainThread)
        
        if stateTrace.count > 0 {
            sceneBox?.dispatch(event: EventBus.EventName.navigationTrack, message: NavigationTraceMessage(from: currentState, to: state))
            logger(content: "scene navigate from \(String(describing: currentState)) to \(state)")
        }
        
        if let indexOfStateInTrace = stateTrace.firstIndex(of: state) {
            stateTrace.removeSubrange(indexOfStateInTrace.advanced(by: 1) ..< stateTrace.endIndex)
        } else {
            stateTrace.append(state)
        }
        
        if state == Self.termination {
            sceneBox?.terminateBox()
            
            return
        }
        
        if let identifier = sceneBox?.stateSceneIdentifierTable[state] {
            sceneBox?.navigate(to: identifier)
            sceneBox?.markSceneAsActive(scene: identifier)
        }
    }
    
    fileprivate func sceneIsActiveScene(_ scene: Scene) -> Bool {        
        guard let sceneBox = sceneBox else {
            return false
        }
        
        return scene === sceneBox.activeScene
    }
}

extension SceneCapabilityWrapper {
    
    /// Transit to another state of scene, the state is set in the configuration of SceneBox.
    /// - Parameter state: The state navigated to.
    public func transit(to state: Int) {
        guard let ext = try? _getExtension(by: NavigationExtension.self) else {
            return
        }
        
        ext.transit(to: state)
    }
    
    /// Return true if the current scene is the active one. `Active` means the caller scene is on the scene as the latest scene in the stack.
    /// - Returns: The result of testing.
    public func currentIsActiveScene() -> Bool {
        guard let ext = try? _getExtension(by: NavigationExtension.self) else {
            return false
        }
        
        return ext.sceneIsActiveScene(scene)
    }
}

extension NavigationExtension: UINavigationControllerDelegate {
    
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        guard let scene = viewController as? Scene else {
            return
        }
        
        let identifier = scene.sceneIdentifier!
        sceneBox?.navigate(to: identifier)
        sceneBox?.markSceneAsActive(scene: identifier)
        
        // call the original one
        previousNavigationControllerDelegate?.navigationController?(navigationController, didShow: viewController, animated: animated)
    }
}
