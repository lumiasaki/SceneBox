//
//  SceneBoxTests.swift
//  SceneBox
//
//  Created by Lumia_Saki on 2021/5/6.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import XCTest
@testable import SceneBox

final class SceneBoxTests: XCTestCase {
    
    var navigationController: UINavigationController!
    var configuration: Configuration!
    var unitTestExtension: UnitTestExtension!
    var sceneBox: SceneBox!
    
    var scene1: SceneBoxTestSceneViewController!
    var sceneIdentifier1: UUID!
    var scene2: SceneBoxTestSceneViewController!
    var sceneIdentifier2: UUID!
    
    struct SceneState: RawRepresentable, Hashable, Equatable {
                
        var rawValue: Int
        
        static let page1 = SceneState(rawValue: NavigationExtension.entry)
        static let page2 = SceneState(rawValue: 1)
        static let termination = SceneState(rawValue: NavigationExtension.termination)
    }
    
    override func setUp() {
        navigationController = UINavigationController()
        
        unitTestExtension = UnitTestExtension()
        
        sceneIdentifier1 = UUID()
        sceneIdentifier2 = UUID()
        
        let sceneIdentifierTable = [
            SceneState.page1.rawValue : sceneIdentifier1!,
            SceneState.page2.rawValue : sceneIdentifier2!
        ]
        
        configuration = Configuration(stateSceneIdentifierTable: sceneIdentifierTable)
            .withBuiltInNavigationExtension()
            .withBuiltInSharedStateExtension()
        
        try! configuration.setExtension(unitTestExtension)
        
        configuration.navigationController = navigationController
        
        sceneBox = SceneBox(configuration: configuration, entry: { [weak navigationController] scene, sceneBox in
            navigationController?.pushViewController(scene, animated: true)
        }, exit: { sceneBox in
            // keep empty here
        })
        
        scene1 = SceneBoxTestSceneViewController()
        scene2 = SceneBoxTestSceneViewController()
    }
    
    override func tearDown() {
        navigationController = nil
        configuration = nil
        unitTestExtension = nil
        sceneBox = nil
        scene1 = nil
        scene2 = nil
    }
    
    func testBasicLifeCyclesOfSceneBox() {
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 3
        
        unitTestExtension.sceneBoxWillTerminateBlock = {
            expectation.fulfill()
        }
        
        unitTestExtension.extensionDidMountBlock = {
            expectation.fulfill()
        }
        
        scene1.sceneBoxWillTerminateBlock = {
            expectation.fulfill()
        }
        
        sceneBox.lazyAdd(identifier: sceneIdentifier1, sceneBuilder: self.scene1)
        sceneBox.lazyAdd(identifier: sceneIdentifier2, sceneBuilder: self.scene2)
        
        XCTAssertNoThrow(try Executor.shared.execute(box: sceneBox))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.scene1.sbx.transit(to: SceneState.termination.rawValue)
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testBasicLifeCycleOfScene() {
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 6
        
        var scene1Load: TimeInterval = TimeInterval()
        scene1.sceneDidLoadedBlock = {
            scene1Load = Date().timeIntervalSince1970
            expectation.fulfill()
        }
        
        var scene1Unload: TimeInterval = TimeInterval()
        scene1.sceneWillUnloadedBlock = {
            scene1Unload = Date().timeIntervalSince1970
            expectation.fulfill()
        }
        
        var scene2Load: TimeInterval = TimeInterval()
        scene2.sceneDidLoadedBlock = {
            scene2Load = Date().timeIntervalSince1970
            expectation.fulfill()
        }
        
        var scene2Unload: TimeInterval = TimeInterval()
        scene2.sceneWillUnloadedBlock = {
            scene2Unload = Date().timeIntervalSince1970
            expectation.fulfill()
        }
        
        sceneBox.lazyAdd(identifier: sceneIdentifier1, sceneBuilder: self.scene1)
        sceneBox.lazyAdd(identifier: sceneIdentifier2, sceneBuilder: self.scene2)
        
        XCTAssertNoThrow(try Executor.shared.execute(box: sceneBox))
        
        XCTAssertTrue(scene1.isActiveScene)
        XCTAssertFalse(scene2.isActiveScene)
        
        unitTestExtension.navigationTrackBlock = {
            XCTAssert($0 == SceneState.page1.rawValue)
            XCTAssert($1 == SceneState.page2.rawValue)
            
            expectation.fulfill()
        }
        scene1.sbx.transit(to: SceneState.page2.rawValue)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertFalse(self.scene1.isActiveScene)
            XCTAssertTrue(self.scene2.isActiveScene)
            
            self.unitTestExtension.navigationTrackBlock = {
                XCTAssert($0 == SceneState.page2.rawValue)
                XCTAssert($1 == SceneState.termination.rawValue)
                
                XCTAssertTrue(scene1Load <= scene1Unload)
                XCTAssertTrue(scene1Unload <= scene2Load)
                XCTAssertTrue(scene2Load <= scene2Unload)
                
                expectation.fulfill()
            }
            
            self.scene1.sbx.transit(to: SceneState.termination.rawValue)
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testNavigationExtension() {
        sceneBox.lazyAdd(identifier: sceneIdentifier1, sceneBuilder: self.scene1)
        sceneBox.lazyAdd(identifier: sceneIdentifier2, sceneBuilder: self.scene2)
        
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 5
        
        XCTAssertNoThrow(try Executor.shared.execute(box: sceneBox))
        
        XCTAssertTrue(unitTestExtension.getSceneStates()?.count == 1)
        
        unitTestExtension.navigationTrackBlock = {
            XCTAssertTrue($0 == SceneState.page1.rawValue)
            XCTAssertTrue($1 == SceneState.page2.rawValue)
            expectation.fulfill()
        }
        scene1.sbx.transit(to: SceneState.page2.rawValue)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertTrue(self.unitTestExtension.getSceneStates()?.count == 2)
            
            self.unitTestExtension.navigationTrackBlock = nil
            self.unitTestExtension.navigationTrackBlock = {
                XCTAssertTrue($0 == SceneState.page2.rawValue)
                XCTAssertTrue($1 == SceneState.page1.rawValue)
                expectation.fulfill()
            }
            self.scene2.sbx.transit(to: SceneState.page1.rawValue)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.unitTestExtension.navigationTrackBlock = nil
                XCTAssertTrue(self.unitTestExtension.getSceneStates()?.count == 1)
                XCTAssertTrue(self.scene1.isActiveScene)
                XCTAssertFalse(self.scene2.isActiveScene)
                expectation.fulfill()
                
                self.scene1.sbx.transit(to: SceneState.page2.rawValue)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    XCTAssertTrue(self.unitTestExtension.getSceneStates()?.count == 2)
                    XCTAssertFalse(self.scene1.isActiveScene)
                    XCTAssertTrue(self.scene2.isActiveScene)
                    expectation.fulfill()
                    
                    self.scene2.sbx.transit(to: SceneState.page1.rawValue)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        XCTAssertTrue(self.unitTestExtension.getSceneStates()?.count == 1)
                        XCTAssertTrue(self.scene1.isActiveScene)
                        XCTAssertFalse(self.scene2.isActiveScene)
                        expectation.fulfill()
                    }
                }
            }
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testSharedStateExtension() {
        sceneBox.lazyAdd(identifier: sceneIdentifier1, sceneBuilder: self.scene1)
        sceneBox.lazyAdd(identifier: sceneIdentifier2, sceneBuilder: self.scene2)
        
        XCTAssertNoThrow(try Executor.shared.execute(box: sceneBox))
        
        let value = 1
        let key = "count"
        
        scene1.sbx.putSharedState(by: key, sharedState: value)
        
        XCTAssertTrue(scene1.sbx.getSharedState(by: key) as? Int == value)
        
        scene1.sbx.transit(to: SceneState.page2.rawValue)
        
        XCTAssertTrue(unitTestExtension.getSceneStates()?.last == SceneState.page2.rawValue)
        
        XCTAssertTrue(scene2.sbx.getSharedState(by: key) as? Int == value)
    }

    static var allTests = [
        ("testBasicLifeCyclesOfSceneBox", testBasicLifeCyclesOfSceneBox),
        ("testBasicLifeCycleOfScene", testBasicLifeCycleOfScene),
        ("testNavigationExtension", testNavigationExtension),
        ("testSharedStateExtension", testSharedStateExtension)
    ]
}
