//
//  SBXErrors.swift
//  SceneBox
//
//  Created by Lumia_Saki on 2021/4/30.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation

/// Errors in SceneBox.
public enum SBXError {
    
    public enum Extension: Swift.Error {
        
        /// Throwing when you set an extension twice to configuration.
        case extensionAlreadyExists
        
        /// Throwing when you enhancing capability of `Scene` by extending `SceneCapabilityWrapper` and try to get your custom extension from the `SceneBox`.
        case cantFindExtension(extensionName: String)
    }
    
    public enum Scene: Swift.Error {
        
        /// Throwing when `SceneBox` can not find the entry scene from the table in configuration.
        case cantFindEntryScene
        
        /// Throwing when trying to execute `SceneBox` without navigation controller.
        case navigationControllerNil
    }
}
