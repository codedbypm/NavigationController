//
//  StackViewController.swift
//  NavigationController
//
//  Created by Paolo Moroni on 01/04/2019.
//  Copyright © 2019 codedby.pm. All rights reserved.
//

import UIKit

public protocol StackViewControllerHandling: UIViewController {
    func popViewController(animated: Bool) -> UIViewController?
    func pushViewController(_: UIViewController, animated: Bool)
}

public protocol StackViewControllerDelegate: class {
    func stackViewController(_: StackViewController,
                             animationControllerFor operation: StackViewController.Operation,
                             from: UIViewController,
                             to: UIViewController) -> UIViewControllerAnimatedTransitioning?

    func stackViewController(_: StackViewController,
                             interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?

}

public class StackViewController: UIViewController, StackViewControllerHandling {

    public enum Operation {
        case push
        case pop
    }
    
    // MARK: - Public properties

    public weak var delegate: StackViewControllerDelegate?

    public private(set) var viewControllers: [UIViewController]

    public var topViewController: UIViewController? {
        return viewControllers.last
    }

    public var visibleViewController: UIViewController? {
        guard
            let topViewController = topViewController,
            topViewController.isViewLoaded && topViewController.view.superview != nil
        else { return nil }

        return topViewController
    }

    public override var shouldAutomaticallyForwardAppearanceMethods: Bool {
        return false
    }

    // MARK: - Private properties

    private lazy var screenEdgePanGestureRecognizer: UIScreenEdgePanGestureRecognizer = {
        let recognizer = UIScreenEdgePanGestureRecognizer()
        recognizer.edges = .left
        recognizer.delegate = self
        return recognizer
    }()

    private var interactionController: UIViewControllerInteractiveTransitioning?

    // MARK: - Init

    public required init(viewControllers: [UIViewController]) {
        self.viewControllers = viewControllers
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        self.viewControllers = []
        super.init(coder: aDecoder)
    }

    // MARK: - Public methods

    public func pushViewController(_ viewController: UIViewController, animated: Bool) {
        guard canPush(viewController) else { return }

        guard let from = visibleViewController else {
            show(viewController)
            viewControllers.append(viewController)
            return
        }

        let to = viewController

        performTransition(forOperation: .push, from: from, to: to, animated: animated) {
            self.viewControllers.append(to)
        }
    }

    @discardableResult
    public func popViewController(animated: Bool) -> UIViewController? {
        guard let from = visibleViewController else { return nil }
        guard let to = viewControllerBefore(from) else { return nil }

        return popToViewController(to, animated: animated).first
    }

    @discardableResult
    func popToViewController(_ to: UIViewController, animated: Bool) -> [UIViewController] {
        guard let from = visibleViewController, visibleViewController != to else { return [] }
        guard let indexOfTo = viewControllers.firstIndex(where: { $0 === to }) else { return [] }

        let poppedViewControllers = viewControllers[(indexOfTo + 1)...]
        performTransition(forOperation: .pop, from: from, to: to, animated: animated, interactive: false) {
            self.viewControllers.removeLast(poppedViewControllers.count)
        }
        return Array(poppedViewControllers)
    }

    public func setViewControllers(_ newViewControllers: [UIViewController], animated: Bool) {
        guard let newTopViewController = newViewControllers.last else {
            assertionFailure("Error: Cannot replace viewControllers with an empty array")
            return
        }

        let operation = operationWhenReplacingStack(with: newViewControllers)

        switch operation {
        case .push:
            pushViewController(newTopViewController, animated: animated)
        case .pop:
            popToViewController(newTopViewController, animated: animated)
        }

        viewControllers = newViewControllers
    }

    func operationWhenReplacingStack(with newStack: [UIViewController]) -> Operation {

        // newStack is empty => instant pop all
        guard let newTopViewController = newStack.last else {
            return .pop
        }

        // oldStack is empty => instant push all
        guard let oldTopViewController = topViewController else {
            // oldStack is empty
            return .push
        }

        if viewControllers.contains(newTopViewController) {
            return .pop
        } else {
            return .push
        }
    }
}

// MARK: - UIViewController

public extension StackViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addGestureRecognizer(screenEdgePanGestureRecognizer)

        if let topViewController = topViewController {
            addChild(topViewController)
            topViewController.didMove(toParent: self)
            view.addSubview(topViewController.view)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        visibleViewController?.beginAppearanceTransition(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        visibleViewController?.endAppearanceTransition()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        visibleViewController?.beginAppearanceTransition(false, animated: animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        visibleViewController?.endAppearanceTransition()
    }
}

// MARK: - UIGestureRecognizerDelegate

extension StackViewController: UIGestureRecognizerDelegate {

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === screenEdgePanGestureRecognizer {
            return screenEdgePanGestureRecognizerShouldBegin()
        } else {
            return false
        }
    }

    private func screenEdgePanGestureRecognizerShouldBegin() -> Bool {
        guard interactionController == nil else { return false }
        guard let from = visibleViewController else { return false }
        guard let to = viewControllerBefore(from) else { return false }

        performInteractivePopTransition(from: from, to: to)
        return true
    }
}

// MARK: - Validation

private extension StackViewController {

    func canPush(_ viewController: UIViewController) -> Bool {
        guard !viewControllers.contains(viewController) else { return false }
        return true
    }
}

// MARK: - Transition

private extension StackViewController {

    func performInteractivePopTransition(from: UIViewController, to: UIViewController) {
        performTransition(forOperation: .pop, from: from, to: to, animated: true, interactive: true) {
            self.viewControllers.removeLast()
        }
    }

    func performTransition(forOperation operation: Operation,
                           from: UIViewController,
                           to: UIViewController,
                           animated: Bool,
                           interactive: Bool = false,
                           completion: (() -> Void)?) {

        let context = transitionContextForTransition(from: from,
                                                     to: to,
                                                     animated: animated,
                                                     interactive: interactive)

        context.onTransitionFinished = { didComplete in
            self.interactionController = nil

            if didComplete {
                completion?()
                self.sendFinalViewAppearanceEvents(from: from, to: to)
            }
        }

        sendInitialViewAppearanceEvents(from: from, to: to, animated: animated)

        let animationController = animationControllerForOperation(operation, from: from, to: to)

        if interactive {
            interactionController = interactionController(for: animationController, context: context)
        } else {
            animationController.animateTransition(using: context)
        }
    }

    func sendInitialViewAppearanceEvents(from: UIViewController, to: UIViewController, animated: Bool) {
        from.willMove(toParent: nil)
        from.beginAppearanceTransition(false, animated: animated)

        addChild(to)
        to.beginAppearanceTransition(true, animated: animated)
    }

    func sendFinalViewAppearanceEvents(from: UIViewController, to: UIViewController) {
        from.view.removeFromSuperview()
        from.removeFromParent()
        from.endAppearanceTransition()

        to.didMove(toParent: self)
        to.endAppearanceTransition()
    }

    func show(_ viewController: UIViewController) {
        addChild(viewController)
        viewController.didMove(toParent: self)

        viewController.beginAppearanceTransition(true, animated: false)
        view.addSubview(viewController.view)
        viewController.endAppearanceTransition()
    }

    func hideVisibleViewController() {
        visibleViewController?.beginAppearanceTransition(false, animated: false)
        visibleViewController?.view.removeFromSuperview()
        visibleViewController?.endAppearanceTransition()

        visibleViewController?.willMove(toParent: nil)
        visibleViewController?.removeFromParent()
    }
}

// MARK: - Object creation

private extension StackViewController {

    func animationControllerForOperation(_ operation: Operation,
                                         from: UIViewController,
                                         to: UIViewController) -> UIViewControllerAnimatedTransitioning {

        if let controller = delegate?.stackViewController(self, animationControllerFor: operation,
                                                          from: from, to: to) {
            return controller
        } else {
            let transitionType = self.transitionType(for: operation)
            return HorizontalSlideAnimationController(type: transitionType)
        }
    }

    func interactionController(for animationController: UIViewControllerAnimatedTransitioning,
                               context: UIViewControllerContextTransitioning) -> UIViewControllerInteractiveTransitioning? {

        if let controller = delegate?.stackViewController(self, interactionControllerFor: animationController) {
            return controller
        } else {
            return HorizontalSlideInteractiveController(animationController: animationController,
                                                        gestureRecognizer: screenEdgePanGestureRecognizer,
                                                        context: context)
        }
    }

    func transitionContextForTransition(from: UIViewController,
                                        to: UIViewController,
                                        animated: Bool = true,
                                        interactive: Bool = false) -> StackViewControllerTransitionContext {

        let context = StackViewControllerTransitionContext(from: from,
                                                           to: to,
                                                           containerView: view)
        context.isAnimated = animated
        context.isInteractive = interactive

        return context
    }
}

// MARK: - Stack-based information

extension StackViewController {

    func viewControllerBefore(_ viewController: UIViewController) -> UIViewController? {
        let indexOfViewControllerInStack = viewControllers.firstIndex(of: viewController)

        guard let beforeIndex = indexOfViewControllerInStack?.advanced(by: -1), beforeIndex >= 0 else {
            return nil
        }

        return viewControllers[beforeIndex]
    }

    func transitionType(for operation: Operation) -> HorizontalSlideTransitionType {
        switch operation {
        case .push: return .slideIn
        case .pop: return .slideOut
        }
    }
}
