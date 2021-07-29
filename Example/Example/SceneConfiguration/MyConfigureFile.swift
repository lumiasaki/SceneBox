//
//  MyConfigureFile.swift
//  Example
//
//  Created by Lumia_Saki on 2021/7/12.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation
import SceneBox

/// Configuration file for this example project.
struct MyConfigureFile: ConfigurationFile {
    
    static var sceneStates: Set<Int> = Set([
        ExampleSceneState.home.rawValue,
        ExampleSceneState.detail.rawValue
    ])
    
    static var extensions: [Extension] = [
        NavigationExtension(),
        SharedStateExtension(stateValue: SceneData())
    ]
}
