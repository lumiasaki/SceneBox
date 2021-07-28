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
    
    weak var scene: Scene? {
        willSet {
            _color.configure(scene: newValue)
        }
    }
    
    @SharedStateInjected(\SceneData.color)
    private var color: Color?
    
    func choose(color: Color) {
        self.color = color
        
        scene?.sbx.transit(to: ExampleSceneState.detail.rawValue)
    }
}
