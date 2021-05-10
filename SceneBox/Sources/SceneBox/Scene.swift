//
//  Scene.swift
//  SceneBox
//
//  Created by Lumia_Saki on 2021/3/21.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation
import UIKit

/// `Scene` acts as a vital role in `SceneBox`, any subclasses of `UIViewController` can conform to `Scene` protocol to enable the capabilities from the `SceneBox`. `Scene` will be notified when meets life-cycles of `SceneBox` and `Scene` itself.
public protocol Scene: SceneLifeCycle, SceneBoxLifeCycle, UIViewController {
        
    /// The unique identifier of a scene, the identifier will be attached by `SceneBox` during the execute phase, you should never set identifier to a scene manually.
    var sceneIdentifier: UUID! { get set }
}

private struct AssociatedObjectKey {
    
    static var sceneBoxKey: Void?
}

extension Scene {
    
    /// In order to hide the the associated `SceneBox` and make it inaccessible directly from the aspect of `Scene`, retain it by using `objc_setAssociatedObject`. The reason for doing this is letting `Scene` can only use the exposed capabilities from `SceneCapabilityWrapper`.
    internal var sceneBox: SceneBox? {
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectKey.sceneBoxKey) as? SceneBox
        }
        
        set {
            objc_setAssociatedObject(self, &AssociatedObjectKey.sceneBoxKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

/// A point for extending new capabilities to `Scene`, any functions be extended to this wrapper will be exposed to `Scene`.
public struct SceneCapabilityWrapper {
    
    /// Access the associated scene in the wrapper.
    public var scene: Scene
    
    /// For retrieving the extensions from the `SceneBox`.
    private var sceneBox: SceneBox?
        
    /// Initializer of `SceneCapabilityWrapper`
    /// - Parameters:
    ///   - sceneBox: Instance of `SceneBox`
    ///   - scene: The associated `Scene` of the wrapper.
    init(sceneBox: SceneBox?, scene: Scene) {
        self.sceneBox = sceneBox
        self.scene = scene
    }
    
    /// For connecting the capabilities to your custom extension behind the curtain, you need to get extension from the `SceneBox`.
    /// - Parameter type: The type of `Extension`
    /// - Throws: SBXError.Extension.cantFindExtension(extensionName: String)
    /// - Returns: The instance has been set to `SceneBox` by `Configuration`.
    public func _getExtension<T>(by type: T.Type) throws -> T {
        guard let ext = sceneBox?.extensions[String(describing: type)] as? T else {
            throw SBXError.Extension.cantFindExtension(extensionName: String(describing: type))
        }
        
        return ext
    }
}

extension Scene {
    
    /// Namespace for `Scene` to retrieve capabilities from `Extension`s.
    public var sbx: SceneCapabilityWrapper { SceneCapabilityWrapper(sceneBox: sceneBox, scene: self) }
}
