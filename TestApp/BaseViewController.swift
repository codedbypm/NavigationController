//
//  BaseViewController.swift
//  TestApp
//
//  Created by Paolo Moroni on 24/04/2019.
//  Copyright © 2019 codedby.pm. All rights reserved.
//

import UIKit
import StackViewController

enum Color: String, CaseIterable {
    case yellow
    case green
    case red
    case magenta
    case gray
    case blue
    case black


    var uiColor: UIColor {
        switch self {
        case .yellow: return .yellow
        case .green: return .green
        case .red: return .red
        case .magenta: return .magenta
        case .gray: return .gray
        case .blue: return .blue
        case .black: return .black
        }
    }

    var textColor: UIColor {
        switch self {
        case .red, .yellow, .magenta, .green : return .darkText
        case .blue, .black, .gray: return .lightText
        }
    }

    static var random: Color {
        return allCases.randomElement()!
    }
}

final class BaseViewController: UIViewController, Tracing {

    weak var stack: StackViewControllerHandling?
    
    let debugAppearance = true
    let debugViewControllerContainment = true
    let debugTraitCollection = false

    var onPopAnimated: (() -> Void)?
    var onPopNonAnimated: (() -> Void)?
    var onPushAnimated: (() -> Void)?
    var onPushNonAnimated: (() -> Void)?

    var onSetViewControllersSameAnimated: (() -> Void)?
    var onSetViewControllersSameNonAnimated: (() -> Void)?
    var onSetVarViewControllersSame: (() -> Void)?

    var onSetViewControllersEmptyAnimated: (() -> Void)?
    var onPopToRootAnimated: (() -> Void)?
    var onSwapIntermediateControllers: (() -> Void)?
    var onSetVarViewControllersEmpty: (() -> Void)?
    var onSwapRootWithTop: (() -> Void)?
    var onInsertAtIndexZero: (() -> Void)?

    lazy var titles: [String] = [
        "pop(_: true)",
        "pop(_: false)",
        "push(_: true)",
        "push(_: false)",
        "setViewControllers(same, true)",
        "setViewControllers(same, false)",
        "viewControllers = same",
        "setViewControllers([], true)",
        "viewControllers = []",
        "popToRootAnimated",
        "Swap 2 middle elements",
        "Swap root with top",
        "insert new at index 0"
    ]

    lazy var closures = [
        onPopAnimated,
        onPopNonAnimated,
        onPushAnimated,
        onPushNonAnimated,
        onSetViewControllersSameAnimated,
        onSetViewControllersSameNonAnimated,
        onSetVarViewControllersSame,
        onSetViewControllersEmptyAnimated,
        onSetVarViewControllersEmpty,
        onPopToRootAnimated,
        onSwapIntermediateControllers,
        onSwapRootWithTop,
        onInsertAtIndexZero,
    ]

    lazy var buttons: [UIButton] = titles.map { button(title: $0) }
    lazy var buttonsAndClosures = zip(buttons, closures)
    lazy var dictionary = Dictionary(uniqueKeysWithValues: buttonsAndClosures)

    private lazy var popStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: Array(buttons.prefix(2)))
        stackView.axis = .horizontal
        stackView.spacing = 10.0
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var pushStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: Array(buttons[2...3]))
        stackView.axis = .horizontal
        stackView.spacing = 10.0
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [popStackView, pushStackView] + Array(buttons.dropFirst(4)))
        stackView.axis = .vertical
        stackView.spacing = 10.0
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let color: Color
    
    required init(color: Color) {
        self.color = color
        super.init(nibName: nil, bundle: nil)
        navigationItem.title = color.rawValue
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = color.uiColor

        addSubviews()
        addSubviewsLayoutConstraints()
    }

    override func beginAppearanceTransition(_ isAppearing: Bool, animated: Bool) {
        trace(.viewControllerContainment, self, #function, isAppearing ? "isAppearing" : "isDisappearing")
        super.beginAppearanceTransition(isAppearing, animated: animated)
    }

    override func endAppearanceTransition() {
        trace(.viewControllerContainment, self, #function)
        super.endAppearanceTransition()
    }

    override func viewWillAppear(_ animated: Bool) {
        trace(.viewLifeCycle, self, #function)
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        trace(.viewLifeCycle, self, #function)
        super.viewDidAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        trace(.viewLifeCycle, self, #function)
        super.viewWillDisappear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        trace(.viewLifeCycle, self, #function)
        super.viewDidDisappear(animated)
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        trace(.viewControllerContainment, self, #function, parent == nil ? "removed" : "added")
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        trace(.viewControllerContainment, self, #function, parent == nil ? "removed" : "added")
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        trace(.traitCollection, self, #function)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        trace(.traitCollection, self, #function)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        trace(.traitCollection, self, #function)
    }

    override var description: String {
        let controllerName = navigationItem.title?.capitalized ?? ""
        let stackName = stack?.description ?? ""
        
        return "\(stackName) \(controllerName)"
    }

    @objc func didTap(button: UIButton) {
        dictionary[button]??()
    }

    func button(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.setTitleColor(color.textColor, for: .normal)
        button.addTarget(self, action: #selector(didTap(button:)), for: .touchUpInside)
        return button
    }
}

private extension BaseViewController {

    func addSubviews() {
        view.addSubview(stackView)
    }

    func addSubviewsLayoutConstraints() {
        addStackViewLayoutConstraints()
    }

    func addStackViewLayoutConstraints() {
        stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stackView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 20.0).isActive = true
        stackView.widthAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.widthAnchor).isActive = true
    }
}
