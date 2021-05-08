//
//  SharedStateExtension.swift
//  
//
//  Created by LumiaSaki on 2021/4/30.
//

import Foundation

public struct SceneBoxSharedStateMessage {
    
    public var key: String?
    public var state: Any?
    
    public init(key: String?, state: Any?) {
        self.key = key
        self.state = state
    }
}

public extension EventBus.EventName {
    
    static let sharedStateChanges: EventBus.EventName = EventBus.EventName(rawValue: "SharedStateChanges")
}

public final class SharedStateExtension: Extension {
    
    // MARK: - Extension
    
    public weak var sceneBox: SceneBox?
    
    // MARK: - private
    
    private let workerQueue = DispatchQueue(label: "com.scenebox.sharedstate.queue", attributes: .concurrent)
    private var state: [String : Any] = Dictionary()
    
    fileprivate func querySharedState(by key: String) -> Any? {
        var result: Any?
        
        workerQueue.sync {
            result = state[key]
        }
        
        return result
    }
    
    fileprivate func setSharedState(_ sharedState: Any?, on key: String) {
        workerQueue.async(flags: .barrier) {
            self.state[key] = sharedState
            
            self.sceneBox?.dispatch(event: EventBus.EventName.sharedStateChanges, message: SceneBoxSharedStateMessage(key: key, state: sharedState))
            self.logger(content: "shared state changes: key: \(key), state: \(String(describing: sharedState))")
        }
    }
    
}

extension SceneBoxSceneAbilityWrapper {
    
    public func getSharedState(by key: String) -> Any? {
        guard let ext = try? _getExtension(by: SharedStateExtension.self) else {
            return nil
        }
        
        return ext.querySharedState(by: key)
    }
    
    public func putSharedState(by key: String, sharedState: Any?) {
        guard let ext = try? _getExtension(by: SharedStateExtension.self) else {
            return
        }
        
        ext.setSharedState(sharedState, on: key)
    }
}
