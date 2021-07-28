//
//  Configuration.swift
//  SceneBox
//
//  Created by Lumia_Saki on 2021/3/21.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation
import UIKit

/// Configuration of SceneBox, you must create a valid configuration before you initialize the SceneBox.
public final class Configuration {
        
    /// State of scenes and the identifiers of scenes configuration table, the table constructs a map of your scenes, once it done, you can transit from a scene to another one without knowing any details about the peer.
    public let stateSceneIdentifierTable: [Int : UUID]
    
    /// Navigating between scenes driven by navigation controller, you need to assign a navigation controller for the SceneBox.
    public var navigationController: UINavigationController?
    
    /// Extensions have been set to configuration.
    public private(set) lazy var extensions: [String : Extension] = Dictionary()
        
    /// Initializer for Configuration
    /// - Parameter stateSceneIdentifierTable: Table for state of scenes and the corresponding identifiers.
    public init(stateSceneIdentifierTable: [Int : UUID]) {
        self.stateSceneIdentifierTable = stateSceneIdentifierTable
    }
    
    /// Enable an extension to the configuration.
    /// - Parameter ext: Custom extension which conforms to the `Extension` protocol.
    /// - Throws: `SBXError.Extension.extensionAlreadyExists` if you set an extension twice.
    public func setExtension(_ ext: Extension) throws {
        let typeName = String(describing: type(of: ext))
        
        guard extensions[typeName] == nil else {
            throw SBXError.Extension.extensionAlreadyExists
        }
        
        extensions[typeName] = ext
    }
}

public extension Configuration {
    
    /// A convenience function to enable SceneBox built-in navigation extension.
    /// - Returns: `Self` to make the chained calls possible.
    func withBuiltInNavigationExtension() -> Self {
        try? setExtension(NavigationExtension())
        return self
    }
    
    /// A convenience function to enable SceneBox built-in shared state extension.
    /// If `stateValue` is nil, you can not use key path variant APIs.
    /// - Returns: `Self` to make the chained calls possible.
    func withBuiltInSharedStateExtension(stateValue: AnyObject? = nil) -> Self {
        try? setExtension(SharedStateExtension(stateValue: stateValue))
        return self
    }
}
