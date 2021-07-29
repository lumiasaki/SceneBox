//
//  SceneState.swift
//  SceneBox
//
//  Created by Lumia_Saki on 2021/7/29.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation
import SceneBox

struct SceneState: RawRepresentable, Hashable, Equatable {
            
    var rawValue: Int
    
    static let page1 = SceneState(rawValue: NavigationExtension.entry)
    static let page2 = SceneState(rawValue: 1)    
}
