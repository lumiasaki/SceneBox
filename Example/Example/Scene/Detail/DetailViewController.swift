//
//  DetailViewController.swift
//  Example
//
//  Created by Lumia_Saki on 2021/7/12.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation
import UIKit
import SceneBox

final class DetailViewController: UIViewController, Scene {
    
    var sceneIdentifier: UUID!
    
    private(set) var viewModel: DetailViewModel
    
    init(viewModel: DetailViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "DETAIL"
        navigationItem.largeTitleDisplayMode = .never
        
        view.backgroundColor = viewModel.backgroundColor                
    }
}
