//
//  HomeViewController.swift
//  Example
//
//  Created by Lumia_Saki on 2021/7/12.
//  Copyright © 2021年 tianren.zhu. All rights reserved.
//

import Foundation
import UIKit
import SceneBox

final class HomeViewController: UIViewController, Scene {
    
    var sceneIdentifier: UUID!
    
    private(set) var viewModel: HomeViewModel
    
    // MARK: - UI Element
    
    private lazy var redButton: UIButton = {
        let view = UIButton()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setTitle("RED", for: .normal)
        view.setTitleColor(.label, for: .normal)
        view.backgroundColor = Color.red.concreteColor()
        view.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        return view
    }()
    
    private lazy var greenButton: UIButton = {
        let view = UIButton()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setTitle("GREEN", for: .normal)
        view.setTitleColor(.label, for: .normal)
        view.backgroundColor = Color.green.concreteColor()
        view.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        return view
    }()
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }
    
    // MARK: - Private
    
    private func setUp() {
        navigationItem.largeTitleDisplayMode = .never
        
        title = "HOME"
        view.backgroundColor = .systemBackground
        
        let container = UIStackView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.axis = .horizontal
        container.distribution = .fillEqually
        
        view.addSubview(container)
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            container.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.2),
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        container.addArrangedSubview(redButton)
        container.addArrangedSubview(greenButton)
    }
    
    @objc
    private func buttonPressed(_ sender: UIButton) {
        let color: Color
        
        switch sender {
        case redButton:
            color = .red
        case greenButton:
            color = .green
        default:
            color = .red
        }
        
        viewModel.choose(color: color)
    }
}
