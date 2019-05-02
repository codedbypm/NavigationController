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

class BaseViewController: UIViewController, ConsoleDebuggable {

    weak var debugDelegate: DebugDelegate?
    weak var stack: StackViewControllerHandling?
    
    let debugAppearance = true
    let debugViewControllerContainment = true
    let debugTraitCollection = true

    var onPopAnimated: (() -> Void)?
    var onPopNonAnimated: (() -> Void)?
    var onPushAnimated: (() -> Void)?
    var onPushNonAnimated: (() -> Void)?

    var onSetViewControllersSameAnimated: (() -> Void)?
    var onSetViewControllersSameNonAnimated: (() -> Void)?
    var onSetVarViewControllersSame: (() -> Void)?

    var onSetViewControllersEmptyAnimated: (() -> Void)?
    var onSetViewControllersEmptyNonAnimated: (() -> Void)?
    var onSetVarViewControllersEmpty: (() -> Void)?
    var onReplaceWithRootAnimated: (() -> Void)?
    var onReplaceWithRootNonAnimated: (() -> Void)?

    lazy var titles: [String] = [
        "pop(_: true)",
        "pop(_: false)",
        "push(_: true)",
        "push(_: false)",
        "setViewControllers(same, true)",
        "setViewControllers(same, false)",
        "viewControllers = same",
        "setViewControllers([], true)",
        "setViewControllers([], false)",
        "viewControllers = []",
        "setViewControllers([root], true)",
        "viewControllers = [root]"
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
        onSetViewControllersEmptyNonAnimated,
        onSetVarViewControllersEmpty,
        onReplaceWithRootAnimated,
        onReplaceWithRootNonAnimated,
    ]

    lazy var buttons: [UIButton] = titles.map { button(title: $0) }
    lazy var buttonsAndClosures = zip(buttons, closures)
    lazy var dictionary = Dictionary(uniqueKeysWithValues: buttonsAndClosures)

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: buttons)
        stackView.axis = .vertical
        stackView.spacing = 10.0
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let color: Color
    
    required init(debugDelegate: DebugDelegate, color: Color) {
        self.debugDelegate = debugDelegate
        self.color = color
        super.init(nibName: nil, bundle: nil)
        navigationItem.title = color.rawValue
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func debugFunc(_ functionName: String, allowed: Bool, appending string: String? = nil) {
        if allowed {
            debugDelegate?.debug(String(describing: self)
                .appending(debugArrow)
                .appending(functionName)
                .appending(string ?? ""))
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = color.uiColor

        addSubviews()
        addSubviewsLayoutConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        debugFunc(#function, allowed: debugAppearance)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        debugFunc(#function, allowed: debugAppearance)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        debugFunc(#function, allowed: debugAppearance)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        debugFunc(#function, allowed: debugAppearance)
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        debugFunc(#function, allowed: debugViewControllerContainment, appending: " \(parent == nil ? "nil" : "")")
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        debugFunc(#function, allowed: debugViewControllerContainment, appending: " \(parent == nil ? "nil" : "")")
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        debugFunc(#function, allowed: debugTraitCollection)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        debugFunc(#function, allowed: debugTraitCollection)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        debugFunc(#function, allowed: debugTraitCollection)
    }

    override var description: String {
        return "\(navigationItem.title?.capitalized ?? "")"
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
