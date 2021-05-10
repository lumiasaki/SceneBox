//
//  SceneBoxCapabilityOutlet.swift
//  SceneBox
//
//  Created by Lumia_Saki on 2021/4/29.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation

/// `SceneBox` provides some very fundamental `API`s for `Extension`s to use.
public protocol SceneBoxCapabilityOutlet {
    
    /// Return current `stateIdentifierStateMap` to caller.
    func stateIdentifierStateMap() -> [Int : UUID]
    
    /// Maintaining and keeping sync of state of the active scene is the job of `NavigationExtension` ( no matter the built-in one or your custom extensions ).
    /// - Parameter scene: The identifier of an instance of `Scene`.
    func markSceneAsActive(scene: UUID)
        
    /// Navigate from one scene to another, by using the identifier of scene. `Extension`s are inaccessible to the real `Scene` instance, what all they can do is building a shadow DOM tree based on identifiers of `Scene`s.
    /// - Parameter scene: The identifier of an instance of `Scene`.
    func navigate(to scene: UUID)    
    
    /// Ask `SceneBox` to be terminated, `SceneBox` will take over any internal cleanup works, call relative life-cycle functions, remove any unnecessary stuffs from memory, call `exitBlock` at last.
    func terminateBox()
}
