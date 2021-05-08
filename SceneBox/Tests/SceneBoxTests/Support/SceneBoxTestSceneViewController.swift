//
//  File.swift
//  
//
//  Created by zhutianren on 2021/5/6.
//

import Foundation
import UIKit
import SceneBox

public final class SceneBoxTestSceneViewController: UIViewController, Scene {
    
    public var sceneIdentifier: UUID!
    
    var isActiveScene: Bool { sbx.currentIsActiveScene() }
    var sceneDidLoadedBlock: (() -> Void)?
    var sceneWillUnloadedBlock: (() -> Void)?
    var sceneBoxWillTerminateBlock: (() -> Void)?
    
    public func sceneDidLoaded() {
        sceneDidLoadedBlock?()
    }
    
    public func sceneWillUnload() {
        sceneWillUnloadedBlock?()
    }
    
    public func sceneBoxWillTerminate() {
        sceneBoxWillTerminateBlock?()
    }
    
}
