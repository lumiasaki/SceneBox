//
//  SceneBoxNavigationExtension.swift
//  
//
//  Created by LumiaSaki on 2021/3/29.
//

import Foundation
import UIKit

public struct NavigationMessage {
    
    public var from: Int?
    public var to: Int?
    public var scenes: [Int]?
    
    public init(from: Int?, to: Int?, scenes: [Int]? = nil) {
        self.from = from
        self.to = to
        self.scenes = scenes
    }
}

public extension EventBus.EventName {
    
    static let navigationTrack: EventBus.EventName = .init(rawValue: "EventTrack")
    static let getStatesRequest: EventBus.EventName = .init(rawValue: "GetScenesRequest")
    static let getStatesResponse: EventBus.EventName = .init(rawValue: "GetScenesResponse")
}

/// Built-in navigation extension for SceneBox, manages the transition state trance inside, manipulate transition between scenes
public final class NavigationExtension: NSObject, Extension {
    
    /// Entry state of navigation, when you execute a scenebox, it will try to find the entry one.
    public static let entry: Int = .min
    
    /// Termination state of navigation, transit to this state when you try to terminate the scenebox.
    public static let termination: Int = .max
    
    // MARK: - Extension
    
    /// Associated scenebox, should always be weak.
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
            self.sceneBox?.dispatch(event: EventBus.EventName.getStatesResponse, message: NavigationMessage(from: nil, to: nil, scenes: stateTrace))
        })
    }
    
    // MARK: - private
    
    fileprivate func transit(to state: Int) {
        precondition(Thread.isMainThread)
        
        if stateTrace.count > 0 {
            sceneBox?.dispatch(event: EventBus.EventName.navigationTrack, message: NavigationMessage(from: currentState, to: state))
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

extension SceneBoxSceneAbilityWrapper {
    
    public func transit(to state: Int) {
        guard let ext = try? _getExtension(by: NavigationExtension.self) else {
            return
        }
        
        ext.transit(to: state)
    }
    
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
