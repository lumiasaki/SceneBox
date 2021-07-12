//
//  DetailViewModel.swift
//  Example
//
//  Created by Lumia_Saki on 2021/7/12.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation
import UIKit
import SceneBox

final class DetailViewModel {
    
    weak var scene: Scene? {
        willSet {
            _color.configure(scene: newValue)
        }
    }
    
    @SceneBoxSharedStateInjected(key: SceneDataSharingKey.color)
    private var color: Color?
    
    // MARK: - Public
    var backgroundColor: UIColor { color?.concreteColor() ?? .clear }
}
