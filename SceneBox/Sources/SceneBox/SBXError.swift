//
//  SceneBoxErrors.swift
//  
//
//  Created by LumiaSaki on 2021/4/30.
//

import Foundation

public enum SBXError {
    
    public enum Extension: Swift.Error {
        
        case extensionAlreadyExists
        case cantFindExtension(extensionName: String)
    }
    
    public enum Scene: Swift.Error {
             
        case cantFindEntryScene
        case navigationControllerNil
    }
}
