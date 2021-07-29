//
//  ExampleSceneState.swift
//  Example
//
//  Created by Lumia_Saki on 2021/7/12.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation
import SceneBox

///// Scene states used by configuration of SceneBox framework. Scene state acts as a tag in router.
struct ExampleSceneState: RawRepresentable, Hashable, Equatable {

    var rawValue: Int

    static let home = ExampleSceneState(rawValue: NavigationExtension.entry)
    static let detail = ExampleSceneState(rawValue: 1)
}
