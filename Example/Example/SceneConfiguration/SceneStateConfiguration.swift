//
//  SceneStateConfiguration.swift
//  Example
//
//  Created by Lumia_Saki on 2021/7/12.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation

/// Configuration of SceneBox for this submission.
struct SceneStateConfiguration {
    
    private(set) var sceneStates: [ExampleSceneState]
    private(set) var currentSceneStateMap: [Int : UUID]
    
    init(sceneStates: [ExampleSceneState]) {
        self.sceneStates = sceneStates
        self.currentSceneStateMap = sceneStates.reduce([:]) {
            $0.merging([$1.rawValue : UUID()]) { $1 }
        }
    }
    
    /// Get identifier to `lazyAdd` the scene to SceneBox.
    /// - Parameter state: State declared in `GithubDMSceneState`
    /// - Returns: Auto-generated identifier for a scene, aka view controller.
    func identifier(with state: ExampleSceneState) -> UUID {
        guard let identifier = currentSceneStateMap[state.rawValue] else {
            fatalError("can not find identifier for \(state)")
        }
        
        return identifier
    }
}
