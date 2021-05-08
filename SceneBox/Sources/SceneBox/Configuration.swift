//
//  Configuration.swift
//  
//
//  Created by LumiaSaki on 2021/3/21.
//

import Foundation
import UIKit

public final class Configuration {
            
    public let stateSceneIdentifierTable: [Int : UUID]
    public var navigationController: UINavigationController?
    public private(set) lazy var extensions: [String : Extension] = Dictionary()
    
    init(stateSceneIdentifierTable: [Int : UUID]) {
        self.stateSceneIdentifierTable = stateSceneIdentifierTable
    }
    
    func setExtension(_ ext: Extension) throws {
        let typeName = String(describing: type(of: ext))
        
        guard extensions[typeName] == nil else {
            throw SBXError.Extension.extensionAlreadyExists
        }
        
        extensions[typeName] = ext
    }
}

public extension Configuration {
    
    func withBuiltInNavigationExtension() -> Self {
        try? setExtension(NavigationExtension())
        return self
    }
    
    func withBuiltInSharedStateExtension() -> Self {
        try? setExtension(SharedStateExtension())
        return self
    }
}
