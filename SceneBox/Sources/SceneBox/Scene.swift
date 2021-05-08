//
//  Scene.swift
//  
//
//  Created by LumiaSaki on 2021/3/21.
//

import Foundation
import UIKit

public protocol Scene: SceneLifeCycle, SceneBoxLifeCycle, UIViewController {
        
    var sceneIdentifier: UUID! { get set }
}

private struct AssociatedObjectKey {
    
    static var sceneBoxKey: Void?
}

extension Scene {
    
    internal var sceneBox: SceneBox? {
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectKey.sceneBoxKey) as? SceneBox
        }
        
        set {
            objc_setAssociatedObject(self, &AssociatedObjectKey.sceneBoxKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

public struct SceneBoxSceneAbilityWrapper {
    
    public var scene: Scene
    private var sceneBox: SceneBox?
    
    init(sceneBox: SceneBox?, scene: Scene) {
        self.sceneBox = sceneBox
        self.scene = scene
    }
    
    public func _getExtension<T>(by type: T.Type) throws -> T {
        guard let ext = sceneBox?.extensions[String(describing: type)] as? T else {
            throw SBXError.Extension.cantFindExtension(extensionName: String(describing: type))
        }
        
        return ext
    }
}

extension Scene {
    
    public var sbx: SceneBoxSceneAbilityWrapper { SceneBoxSceneAbilityWrapper(sceneBox: sceneBox, scene: self) }
}
