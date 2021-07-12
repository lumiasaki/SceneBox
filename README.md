# SceneBox


## Motivation

There is a very common scenario when we build an app, that is, using a series of uninterrupted processes to complete a business operation, for example, many apps have a user login/registration process, will display a series of login and registration channels on the first page for the user to choose, the second page may ask the user to fill in some information, when jumping to the third page may require the user to fill in some other information further, and the last page will aggregate all the information that has been filled in before, then make a network request to get the final result. If we use the traditional approach, one of the challenges here is that the developer needs to pass the data between pages one by one, which results the data that is clearly not the concern of current page, but is seen in its public interface declaration as requiring an unrelated data to be passed in the previous page. At the same time, all these pages, if without using other decoupling approaches, will be tightly coupled together, making it difficult for developers to easily modify the order of the pages in the process and to add new pages to the whole process.

Based on these two pain points, I conceived the framework to enable us to develop application-specific business scenarios that can be more scalable and efficient.

## How to integrate into your project

To integrate using Apple's SPM, add following as a dependency to your Target.

`.package(url: "https://github.com/lumiasaki/SceneBox.git", .upToNextMajor(from: "0.2.4"))`

## How to use

### Distribute scene states from product level

```swift

struct SceneState: RawRepresentable, Hashable, Equatable {

    var rawValue: Int

    static let home = SceneState(rawValue: NavigationExtension.entry)
    static let detail = SceneState(rawValue: 1)
    static let termination = SceneState(rawValue: NavigationExtension.termination)
}

extension SceneState: CaseIterable {

    /// Help to register all states.
    static var allCases: [SceneState] { [.home, .detail, .termination] }
}

```

### Generate configuration

```swift

let identifier = UUID()
let sceneState = SceneState.home.rawValue

let sceneBoxConfiguration = Configuration(stateSceneIdentifierTable: [sceneState : identifier])

```

I strongly recommend you to use helper `SceneStateConfiguration` in `Example Project` to simplify `Configuration` initialization.

### Initiate SceneBox

```swift

let sceneBox = SceneBox(configuration: sceneBoxConfiguration) { scene, sceneBox in
            self.navigationController.pushViewController(scene, animated: false)
        } exit: { _ in }
        
```

### Setup scene state identifier table

```swift

box.lazyAdd(identifier: sceneStateConfiguration.identifier(with: .home)) {
                let viewModel = HomeViewModel()
                let viewController = HomeViewController(viewModel: viewModel)
                viewModel.scene = viewController

                return viewController
            }

```

### Launch the box

```swift

try? Executor.shared.execute(box: sceneBox)

```

### Make a view controller as Scene

```swift

import Foundation
import UIKit
import SceneBox

class MyViewController: UIViewController, Scene {

    var sceneIdentifier: UUID!
  
    // ...
}

```

### How to access capabilities from SceneBox in Scene

```swift

class MyViewController: UIViewController, Scene {

    var sceneIdentifier: UUID!
  
    func saveValue() {
        sbx.putSharedState(by: "Color", sharedState: UIColor.red)
    }
    
    func fetchValue() {
        let color: UIColor? = sbx.getSharedState(by: "Color")
    }
    
    func pushToNext() {
        sbx.transit(to: SceneState.detail.rawValue)
    }
}

```

You can create any feature to enhance your box by implementing extensions.

### Shared state injection wrapper

```swift

class MyViewController: UIViewController, Scene {

    var sceneIdentifier: UUID!
  
    @SceneBoxSharedStateInjected(key: "Color")
    private var color: UIColor?
    
    init() {
        _color.configure(scene: self)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    func getCurrentColor() -> UIColor? {
        return color
    }
}

```

## Basic Concept

### SceneBox

A `SceneBox` represents a complete process, imagine it is a box that contains a series of pages inside, and the pages that are contained inside the box can easily use a series of capabilities provided by the box. Initializing a `SceneBox` requires providing a `Configuration`, in which the caller is required to provide the initialization method of the pages and the corresponding unique identifiers of the pages for later decoupling between pages purpose. Besides, `SceneBox` requires caller to provide two blocks to control the behavior when entering and exiting the box. The behavior of entering the box means that when a box is called with the `execute()` method, how to display the first page, whether it is pushed or other more custom operations are left to the callers to manage, with strong scalability. The behavior of leaving the box means that when the whole process is completed, the state of the box comes to `terminated`, the caller should provide an implementation to control the behavior at this point to handle post cleanup stuffs.

In general, after initializing a `SceneBox`, it can be held manually by the caller and call the `execute()` method of `SceneBox`, but using the framework's built-in `Executor` to start the operation is a much more recommend way, the `Executor` will automatically manage the life cycle of the `SceneBox`.

### Scene

The `Scene` represents a page in the `SceneBox`, which is currently limited in the `UIViewController` class, and the limitation may be removed in the future. The fact that `Scene` is a protocol means that using `SceneBox` does not need to change the inheritance of your existing code, making it relatively easy to transform an existing `UIViewController` into a class that can be used in `SceneBox`. `Scene` provides a number of capabilities that can be used in `SceneBox`, such as `getSharedState(by:)`, `putSharedState(state:key:)` and so on.

Once a `UIViewController` is marked as conforming to the `Scene` protocol, you can access a number of capabilities under `sbx` namespace of your view controller. Even more, you can extend your own capabilities to the `Scene` under the namespace easily by extend `SceneCapabilityWrapper`, you can follow the guide to extend it.

By calling these `Scene` capabilities, you no longer need to pass a piece of data from the first page to the last one, all of what you need to do is giving the data that will be shared to `SceneBox`, and if the downstream pages need the corresponding values, retrieve them from the `SceneBox` by a negotiated key. Also, since it is no longer necessary to explicitly push to the next page, but to call the `transit(to:)` method provided by `Scene` instead, the strong coupling between these pages is also lifted.

### Extensions

All the capabilities in `Scene` are driven by `SceneBox` fundamental outlets, and `SceneBox` does not actually provide these capabilities directly, `SceneBox` only provides a series of basic interfaces to the extensions, and the use of these fundamental functions to form more complex and advanced functions is `Extension`'s task. This is designed very much like Microsoft's `Visual Studio Code`, or Chrome's `Chrome Extension`. In fact, all the basic and additional capabilities of `SceneBox` are implemented by `Extension`s ( such as `navigation` or `shared state` capabilities provided by built-in extensions ), and you can even build a complete set of `Redux` or `Data Binding` on top of `SceneBox` if you want.

There is always a need for interaction between `Extension`s, and to reduce coupling between `Extension`s and to emphasize the independence of each one, `Extension`s interact with each other through an internal message bus, where each `Extension` can declare what messages it listens to and what messages it can respond to, without paying attention to where the messages come from or whether there is a recipient for the messages it sends.
