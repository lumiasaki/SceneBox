//
//  SharedStateTestKey.swift
//  SceneBox
//
//  Created by Lumia_Saki on 2021/7/27.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation
import SceneBox

struct TimestampKey: SharedStateKey {

    static var currentValue: TimeInterval?
}

extension SharedStateValues {
    
    var timestamp: TimeInterval? {
        get { Self[TimestampKey.self] }
        set { Self[TimestampKey.self] = newValue }
    }
}

struct CarKey: SharedStateKey {
    
    static var currentValue: Car?
}

extension SharedStateValues {
    
    var car: Car? {
        get { Self[CarKey.self] }
        set { Self[CarKey.self] = newValue }
    }
}
