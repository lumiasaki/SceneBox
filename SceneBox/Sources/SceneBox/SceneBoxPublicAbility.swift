//
//  SceneBoxPublicAbility.swift
//  
//
//  Created by LumiaSaki on 2021/4/29.
//

import Foundation

public protocol SceneBoxPublicAbility {
    
    func stateIdentifierStateMap() -> [Int : UUID]
    func markSceneAsActive(scene: UUID)
    func navigate(to scene: UUID)
    func terminateBox()
}
