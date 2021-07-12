//
//  Color.swift
//  Example
//
//  Created by Lumia_Saki on 2021/7/12.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation
import UIKit

enum Color {
    
    case red
    case green
    
    func concreteColor() -> UIColor {
        switch self {
        case .red:
            return UIColor(red: 219 / 255, green: 61 / 255, blue: 61 / 255, alpha: 1)
        case .green:
            return UIColor(red: 50 / 255, green: 168 / 255, blue: 168 / 255, alpha: 1)
        }
    }
}
