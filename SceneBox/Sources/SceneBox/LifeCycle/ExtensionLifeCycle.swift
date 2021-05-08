//
//  ExtensionLifeCycle.swift
//  
//
//  Created by LumiaSaki on 2021/3/21.
//

import Foundation

public protocol ExtensionLifeCycle {
    
    func extensionDidMount()
}

public extension ExtensionLifeCycle {
    
    func extensionDidMount() { }
}
