//
//  HomeViewModel.swift
//  Example
//
//  Created by Lumia_Saki on 2021/7/12.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation
import SceneBox

final class HomeViewModel {        
    
    weak var scene: Scene?
    
    func choose(color: Color) {
        scene?.sbx.putSharedState(by: SceneDataSharingKey.color, sharedState: color)
        scene?.sbx.transit(to: ExampleSceneState.detail.rawValue)
    }
}
