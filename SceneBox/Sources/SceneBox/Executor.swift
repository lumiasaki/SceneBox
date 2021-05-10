//
//  Executor.swift
//  SceneBox
//
//  Created by Lumia_Saki on 2021/3/21.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation

/// An executor to help managing a set of SceneBoxes. The executor is not required component for SceneBox, you want to retain the instance of SceneBox as well, but we recommend you to use `Executor` to make the code cleaner.
public final class Executor {
    
    /// Singleton executor of `Executor`.
    public static let shared: Executor = Executor()
    
    // MARK - Private Property
    
    private lazy var boxes: [UUID : SceneBox] = Dictionary()
    
    // MARK: - Public
    
    /// Execute a box, the box will be retained by `Executor` until the box meets `termination` state. Function should be called on the main queue.
    /// - Parameter box: An instance of `SceneBox`.
    /// - Throws: Same as errors from `box.execute()`.
    public func execute(box: SceneBox) throws {
        precondition(Thread.isMainThread)
        
        let executorExtension = _ExecutorHelperExtension(executor: self)
        try! box.configuration.setExtension(executorExtension)
        
        boxes[box.identifier] = box
        
        try box.execute()
    }
    
    // MARK: - Private Method
    
    fileprivate func terminateBoxProcess(_ box: SceneBox) {
        precondition(Thread.isMainThread)
        
        boxes.removeValue(forKey: box.identifier)
    }
}

/// A helper extension for `Executor`, call `terminateBoxProcess` when relevant life-cycles of extension has been invoked.
private final class _ExecutorHelperExtension: Extension {
    
    // MARK: - Extension
    
    /// Associated SceneBox, should always be weak.
    weak var sceneBox: SceneBox?
    
    var executor: Executor
    
    init(executor: Executor) {
        self.executor = executor
    }
    
    // MARK: - SceneBoxLifeCycle
    
    func sceneBoxWillTerminate() {
        guard let sceneBox = sceneBox else {
            return
        }
                
        executor.terminateBoxProcess(sceneBox)
    }
}
