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
            .withBuiltInSharedStateExtension(stateValue: MyState())
        
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
    
    @available(*, deprecated, message: "Use `testSharedStateExtensionWithKeyPathApproach` instead.")
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
    
    func testSharedStateExtensionWithKeyPathApproach() {
        sceneBox.lazyAdd(identifier: sceneIdentifier1, sceneBuilder: self.scene1)
        sceneBox.lazyAdd(identifier: sceneIdentifier2, sceneBuilder: self.scene2)
        
        XCTAssertNoThrow(try Executor.shared.execute(box: sceneBox))
        
        // value type
        do {
            XCTAssertNil(scene1.sbx.getSharedState(by: \MyState.timestamp))
            
            let timestamp = Date().timeIntervalSince1970
            
            scene1.sbx.putSharedState(by: \MyState.timestamp, sharedState: timestamp)
            
            XCTAssertTrue(scene1.sbx.getSharedState(by: \MyState.timestamp) == timestamp)
            
            scene1.sbx.transit(to: SceneState.page2.rawValue)
            
            XCTAssertTrue(unitTestExtension.getSceneStates()?.last == SceneState.page2.rawValue)
            
            XCTAssertTrue(scene2.sbx.getSharedState(by: \MyState.timestamp) == timestamp)
            
            let newTimestamp = Date().timeIntervalSince1970
                    
            scene2.sbx.putSharedState(by: \MyState.timestamp, sharedState: newTimestamp)
            
            XCTAssertTrue(scene2.sbx.getSharedState(by: \MyState.timestamp) == newTimestamp)
            XCTAssertTrue(scene1.sbx.getSharedState(by: \MyState.timestamp) == newTimestamp)
            
            scene1.sbx.putSharedState(by: \MyState.timestamp, sharedState: nil)
            XCTAssertNil(scene1.sbx.getSharedState(by: \MyState.timestamp))
            XCTAssertNil(scene2.sbx.getSharedState(by: \MyState.timestamp))
        }
        
        // reference type
        do {
            let myCar = Car(name: "benz")
            
            scene1.sbx.putSharedState(by: \MyState.car, sharedState: myCar)
            
            XCTAssertTrue(scene1.sbx.getSharedState(by: \MyState.car) === myCar)
            XCTAssertTrue(scene1.sbx.getSharedState(by: \MyState.car)?.name == "benz")
            
            XCTAssertTrue(scene2.sbx.getSharedState(by: \MyState.car) === myCar)
            XCTAssertTrue(scene2.sbx.getSharedState(by: \MyState.car)?.name == "benz")
            
            myCar.name = "bmw"
            
            XCTAssertTrue(scene1.sbx.getSharedState(by: \MyState.car) === myCar)
            XCTAssertTrue(scene1.sbx.getSharedState(by: \MyState.car)?.name == "bmw")
            
            XCTAssertTrue(scene2.sbx.getSharedState(by: \MyState.car) === myCar)
            XCTAssertTrue(scene2.sbx.getSharedState(by: \MyState.car)?.name == "bmw")
            
            scene1.sbx.putSharedState(by: \MyState.car, sharedState: nil)
            XCTAssertNil(scene1.sbx.getSharedState(by: \MyState.car))
            XCTAssertNil(scene2.sbx.getSharedState(by: \MyState.car))
        }
        
        // injection property wrapper
        do {
            let myCar = Car(name: "mini")
            
            XCTAssertNil(scene1.car)
            XCTAssertNil(scene2.car)
            
            scene1.car = myCar
            
            XCTAssertTrue(scene1.car === myCar)
            XCTAssertTrue(scene1.car?.name == "mini")
            
            XCTAssertTrue(scene2.car === myCar)
            XCTAssertTrue(scene2.car?.name == "mini")
            
            scene2.car?.name = "benz"
            
            XCTAssertTrue(scene1.car === myCar)
            XCTAssertTrue(scene1.car?.name == "benz")
            
            XCTAssertTrue(scene2.car === myCar)
            XCTAssertTrue(scene2.car?.name == "benz")
            
            scene2.car = nil
            
            XCTAssertNil(scene1.car)
            XCTAssertNil(scene2.car)
        }
        
        // isolation between boxes
        do {
            let navigationController = UINavigationController()
            
            let sceneIdentifier3 = UUID()
            let sceneIdentifier4 = UUID()
            
            let sceneIdentifierTable = [
                SceneState.page1.rawValue : sceneIdentifier3,
                SceneState.page2.rawValue : sceneIdentifier4
            ]
            
            let configuration = Configuration(stateSceneIdentifierTable: sceneIdentifierTable)
                .withBuiltInNavigationExtension()
                .withBuiltInSharedStateExtension(stateValue: MyState())
            
            configuration.navigationController = navigationController
            
            let sceneBox2 = SceneBox(configuration: configuration, entry: { [weak navigationController] scene, sceneBox in
                navigationController?.pushViewController(scene, animated: true)
            }, exit: { sceneBox in
                // keep empty here
            })
            
            let scene3 = SceneBoxTestSceneViewController()
            let scene4 = SceneBoxTestSceneViewController()
            
            sceneBox2.lazyAdd(identifier: sceneIdentifier3, sceneBuilder: scene3)
            sceneBox2.lazyAdd(identifier: sceneIdentifier4, sceneBuilder: scene4)
            
            XCTAssertNoThrow(try Executor.shared.execute(box: sceneBox2))
            
            scene1.sbx.putSharedState(by: \MyState.timestamp, sharedState: Date().timeIntervalSince1970)
            scene2.sbx.putSharedState(by: \MyState.car, sharedState: Car(name: "benz"))
            
            XCTAssertNotNil(scene1.sbx.getSharedState(by: \MyState.timestamp))
            XCTAssertNotNil(scene2.sbx.getSharedState(by: \MyState.car))
            
            XCTAssertNil(scene3.sbx.getSharedState(by: \MyState.timestamp))
            XCTAssertNil(scene4.sbx.getSharedState(by: \MyState.car))
        }
    }

    static var allTests = [
        ("testBasicLifeCyclesOfSceneBox", testBasicLifeCyclesOfSceneBox),
        ("testBasicLifeCycleOfScene", testBasicLifeCycleOfScene),
        ("testNavigationExtension", testNavigationExtension),
        ("testSharedStateExtensionWithKeyPathApproach", testSharedStateExtensionWithKeyPathApproach)
    ]
}
