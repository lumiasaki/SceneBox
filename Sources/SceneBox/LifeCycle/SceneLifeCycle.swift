//
//  SceneLifeCycle.swift
//  SceneBox
//
//  Created by Lumia_Saki on 2021/3/21.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation

/// Life cycle for a scene.
public protocol SceneLifeCycle {
    
    /// Notify scene itself will be on the screen soon.
    func sceneDidLoaded()
    
    /// Notify scene itself will be unloaded and transit to another state of scenes.
    func sceneWillUnload()
}

public extension SceneLifeCycle {
    
    func sceneDidLoaded() { }
    func sceneWillUnload() { }
}
