//
//  File.swift
//  
//
//  Created by zhutianren on 2021/5/6.
//

import Foundation

internal final class UnitTestExtension: Extension {
    
    public weak var sceneBox: SceneBox?
    
    internal var sceneBoxWillTerminateBlock: (() -> Void)?
    internal var extensionDidMountBlock: (() -> Void)?
    internal var navigationTrackBlock: ((_ from: Int, _ to: Int) -> Void)?
    internal var sharedStateChangedBlock: ((_ key: String, _ object: Any?) -> Void)?
    
    public func extensionDidMount() {
        extensionDidMountBlock?()
        
        sceneBox?.watch(on: EventBus.EventName.navigationTrack, messageType: NavigationMessage.self, next: { [unowned self] message in
            guard let message = message, let from = message.from, let to = message.to else {
                return
            }
            
            self.navigationTrackBlock?(from, to)
        })
        
        sceneBox?.watch(on: EventBus.EventName.sharedStateChanges, messageType: SceneBoxSharedStateMessage.self, next: { [unowned self] message in
            guard let message = message, let key = message.key, let state = message.state else {
                return
            }
            
            self.sharedStateChangedBlock?(key, state)
        })
    }
    
    public func sceneBoxWillTerminate() {
        sceneBoxWillTerminateBlock?()
    }
    
    func getSceneStates() -> [Int]? {
        var result: [Int]? = Array()
        
        let semaphore: DispatchSemaphore = DispatchSemaphore.init(value: 0)
        sceneBox?.watch(on: EventBus.EventName.getStatesResponse, messageType: NavigationMessage.self, next: { message in
            guard let message = message, let sceneStates = message.scenes else {
                semaphore.signal()
                return
            }
            
            result = sceneStates
            semaphore.signal()
        })
        
        sceneBox?.dispatch(event: EventBus.EventName.getStatesRequest, message: ())
        
        semaphore.wait()
        
        return result
    }
    
}
