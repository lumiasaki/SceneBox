//
//  SceneBoxLifeCycle.swift
//  
//
//  Created by LumiaSaki on 2021/3/21.
//

import Foundation

public protocol SceneBoxLifeCycle {
    
    func sceneBoxWillTerminate()
}

public extension SceneBoxLifeCycle {
    
    func sceneBoxWillTerminate() { }
}
