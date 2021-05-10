//
//  SceneBoxLifeCycle.swift
//  SceneBox
//
//  Created by Lumia_Saki on 2021/3/21.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation

/// Life cycle of the a scene box.
public protocol SceneBoxLifeCycle {
    
    /// Called when transit to the `terminate` state, the scene box will be terminated.
    func sceneBoxWillTerminate()
}

public extension SceneBoxLifeCycle {
    
    func sceneBoxWillTerminate() { }
}
