//
//  TransitionContext.swift
//  StackViewController
//
//  Created by Paolo Moroni on 03/04/2019.
//  Copyright © 2019 codedby.pm. All rights reserved.
//

import Foundation

class TransitionContext: NSObject, UIViewControllerContextTransitioning {

    let containerView: UIView
    var isAnimated: Bool = true
    var isInteractive: Bool = false
    var transitionWasCancelled: Bool = false
    var presentationStyle: UIModalPresentationStyle = .custom
    var targetTransform: CGAffineTransform = .identity
    var onTransitionFinished: ((Bool) -> Void)?
    var onTransitionCancelled: ((Bool) -> Void)?
    var operation: StackViewController.Operation = .none

    var from: UIViewController? { return viewController(forKey: .from) }
    var to: UIViewController? { return viewController(forKey: .to) }

    // MARK: - Private properties

    private var viewControllers: [UITransitionContextViewControllerKey: UIViewController?] = [:]
    private var views: [UITransitionContextViewKey: UIView] {
        var views = [UITransitionContextViewKey: UIView]()

        if let fromView = view(forKey: .from) {
            views[.from] = fromView
        }

        if let toView = view(forKey: .to) {
            views[.to] = toView
        }
        return views
    }

    // MARK: - Init

    init(operation: StackViewController.Operation, from: UIViewController?, to: UIViewController?, containerView: UIView, animated: Bool, interactive: Bool = false) {
        self.operation = operation
        self.viewControllers = [.from: from, .to: to]
        self.containerView = containerView
        self.isAnimated = animated && (from != nil && to != nil)
        self.isInteractive = interactive
    }

    func setViewController(_ viewController: UIViewController?,
                           forKey key: UITransitionContextViewControllerKey) {
        return viewControllers[key] = viewController
    }

    func completeTransition(_ didComplete: Bool) {
        onTransitionFinished?(didComplete)
    }

    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        return viewControllers[key].flatMap({ $0 })
    }

    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        if case .from = key, let fromVC = viewControllers[.from].flatMap({ $0 }), fromVC.isViewLoaded {
            return fromVC.view
        }

        if case .to = key, let toVC = viewControllers[.to].flatMap({ $0 }), toVC.isViewLoaded {
            return toVC.view
        }

        return nil
    }

    func initialFrame(for vc: UIViewController) -> CGRect {
        if vc == viewController(forKey: .from) {
            return containerView.bounds
        }
        return .zero
    }

    func finalFrame(for vc: UIViewController) -> CGRect {
        if vc == viewController(forKey: .to) {
            return containerView.bounds
        }
        return .zero
    }

    // MARK: - Interactive transition

    func updateInteractiveTransition(_ percentComplete: CGFloat) {

    }

    func finishInteractiveTransition() {
        transitionWasCancelled = false
    }

    func cancelInteractiveTransition() {
        transitionWasCancelled = true
    }

    func pauseInteractiveTransition() {

    }
}
