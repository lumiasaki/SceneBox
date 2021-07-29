//
//  ExtensionLifeCycle.swift
//  SceneBox
//
//  Created by Lumia_Saki on 2021/3/21.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation

/// Life cycle hooks for an extension.
public protocol ExtensionLifeCycle {
    
    /// The function will be called when an extension is initialized in SceneBox during the `execute` phase, called once the extension has been set up well.
    func extensionDidMount()
}

public extension ExtensionLifeCycle {
    
    func extensionDidMount() { }    
}
