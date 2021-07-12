//
//  SceneDelegate.swift
//  Example
//
//  Created by Lumia_Saki on 2021/7/12.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import UIKit
import SceneBox

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    var navigationController: UINavigationController = UINavigationController()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        navigationController.navigationBar.prefersLargeTitles = true
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.windowScene = windowScene
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        // configure SceneBox with some configurations
        let sceneStateConfiguration = SceneStateConfiguration(sceneStates: ExampleSceneState.allCases)

        let sceneBoxConfiguration = Configuration(stateSceneIdentifierTable: sceneStateConfiguration.currentSceneStateMap).withBuiltInNavigationExtension().withBuiltInSharedStateExtension()

        sceneBoxConfiguration.navigationController = navigationController

        let sceneBox = SceneBox(configuration: sceneBoxConfiguration) { scene, sceneBox in
            self.navigationController.pushViewController(scene, animated: false)
        } exit: { _ in }

        setUpSceneStateIdentifierTable(for: sceneBox, sceneStateConfiguration: sceneStateConfiguration)

        try? Executor.shared.execute(box: sceneBox)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

extension SceneDelegate {
    
    // The real set up place for view controllers and view models, it's a great tool for decoupling
    private func setUpSceneStateIdentifierTable(for box: SceneBox, sceneStateConfiguration: SceneStateConfiguration) {
        // home
        do {
            box.lazyAdd(identifier: sceneStateConfiguration.identifier(with: .home)) {
                let viewModel = HomeViewModel()
                let viewController = HomeViewController(viewModel: viewModel)
                viewModel.scene = viewController

                return viewController
            }
        }

        // detail
        do {
            box.lazyAdd(identifier: sceneStateConfiguration.identifier(with: .detail)) {
                let viewModel = DetailViewModel()
                let viewController = DetailViewController(viewModel: viewModel)
                viewModel.scene = viewController

                return viewController
            }
        }
    }
}
