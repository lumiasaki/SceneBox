//
//  Executor.swift
//  
//
//  Created by LumiaSaki on 2021/3/21.
//

import Foundation

public final class Executor {
    
    public static let shared: Executor = Executor()
    
    private lazy var boxes: [UUID : SceneBox] = Dictionary()
    
    public func execute(box: SceneBox) throws {
        precondition(Thread.isMainThread)
        
        let executorExtension = _SceneBoxExecutorHelperExtension(executor: self)
        try box.configuration.setExtension(executorExtension)
        
        boxes[box.identifier] = box
        
        try box.execute()
    }
    
    // MARK: - private
    
    fileprivate func terminateBoxProcess(_ box: SceneBox) {
        precondition(Thread.isMainThread)
        
        boxes.removeValue(forKey: box.identifier)
    }
}

private final class _SceneBoxExecutorHelperExtension: Extension {
        
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
