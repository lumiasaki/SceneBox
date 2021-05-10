//
//  SceneBoxTestSceneViewController.swift
//  SceneBox
//
//  Created by Lumia_Saki on 2021/5/6.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
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
