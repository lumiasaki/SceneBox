//
//  MyConfigurationFile.swift
//  SceneBox
//
//  Created by Lumia_Saki on 2021/7/29.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation
import SceneBox

struct MyConfigurationFile: ConfigurationFile {
    
    static var sceneStates: Set<Int> = Set([
        SceneState.page1.rawValue,
        SceneState.page2.rawValue
    ])
    
    static var extensions: [Extension] = [
        NavigationExtension(),
        SharedStateExtension(stateValue: MyState())
    ]
}
