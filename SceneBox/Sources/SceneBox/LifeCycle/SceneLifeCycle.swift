//
//  SceneLifeCycle.swift
//  
//
//  Created by LumiaSaki on 2021/3/21.
//

import Foundation

public protocol SceneLifeCycle {
    
    func sceneDidLoaded()
    func sceneWillUnload()
}

public extension SceneLifeCycle {
    
    func sceneDidLoaded() { }
    func sceneWillUnload() { }
}
