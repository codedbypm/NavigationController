//
//  StackViewControllerInteractor.swift
//  StackViewController
//
//  Created by Paolo Moroni on 11/05/2019.
//  Copyright © 2019 codedby.pm. All rights reserved.
//

import Foundation

protocol StackViewControllerInteractorDelegate: UIViewController {
    func prepareAddingChild(_: UIViewController) // after this sends willMoveToParent self
    func finishAddingChild(_: UIViewController) // after this sends didMoveToParent self

    func prepareRemovingChild(_: UIViewController) // after this sends willMoveToParent nil
    func finishRemovingChild(_: UIViewController) // after this sends didMoveToParent nil

    func prepareAppearance(of _: UIViewController, animated: Bool)
    func finishAppearance(of _: UIViewController)
    func prepareDisappearance(of _: UIViewController, animated: Bool)
    func finishDisappearance(of _: UIViewController)
}

class StackViewControllerInteractor: StackHandlerDelegate, TransitionHandlerDelegate  {

    // MARK: - Internal properties

    weak var delegate: StackViewControllerInteractorDelegate?
    weak var transitioningDelegate: StackViewControllerDelegate?

    var stack: Stack { return stackHandler.stack }
    
    var topViewController: UIViewController? { return stack.last }

    lazy var viewControllerWrapperView: UIView = ViewControllerWrapperView()

    // MARK: - Private properties

    private let stackHandler: StackHandler

    private var transitionHandler: TransitionHandler?

    private var currentTransition: Transition?


    // MARK: - Init

    init(stackHandler: StackHandler) {
        self.stackHandler = stackHandler
    }

    // MARK: - Internal methods

    func push(_ viewController: UIViewController, animated: Bool) {
        currentTransition = Transition(operation: .push,
                                       from: topViewController,
                                       to: viewController,
                                       animated: animated)
        stackHandler.push(viewController)
    }

    func push(_ stack: Stack, animated: Bool) {
        currentTransition = Transition(operation: .push,
                                       from: topViewController,
                                       to: stack.last,
                                       animated: animated)
        stackHandler.push(stack)
    }

    @discardableResult
    func pop(animated: Bool, interactive: Bool = false) -> UIViewController? {
        currentTransition = Transition(operation: .pop,
                                       from: topViewController,
                                       to: stack[stack.endIndex - 2],
                                       animated: animated,
                                       interactive: interactive)
        return stackHandler.pop()
    }

    func popToRoot(animated: Bool) -> Stack {
        currentTransition = Transition(operation: .pop,
                                       from: topViewController,
                                       to: stack.first,
                                       animated: animated)
        return stackHandler.popToRoot()
    }

    func popTo(_ viewController: UIViewController, animated: Bool, interactive: Bool = false) -> Stack {
        currentTransition = Transition(operation: .pop,
                                       from: topViewController,
                                       to: viewController,
                                       animated: animated,
                                       interactive: interactive)
        return stackHandler.popTo(viewController)
    }

    func setStack(_ newStack: Stack, animated: Bool) {
        let operation = stackOperation(whenReplacing: stack, with: newStack)
        currentTransition = Transition(operation: operation,
                                       from: topViewController,
                                       to: newStack.last,
                                       animated: animated)
        stackHandler.setStack(newStack)
    }

    // MARK: - StackHandlerDelegate

    func stackDidChange(_ difference: Stack.Difference) {
        print(difference)
        notifyControllerAboutStackChanges(difference)

        guard var currentTransition = currentTransition else { return }

        currentTransition.undo = { [weak self] in
            guard let self = self else { return }
            guard let invertedDifference = difference.inverted else { return }
            guard let oldStack = self.stack.applying(invertedDifference) else { return }

            self.stackHandler.delegate = nil
            self.stackHandler.setStack(oldStack)
            self.stackHandler.delegate = self
        }

        let animationController: UIViewControllerAnimatedTransitioning?

        if let from = currentTransition.from, let to = currentTransition.to, let controller = transitioningDelegate?.animationController(for: currentTransition.operation, from: from, to: to) {
            animationController = controller
        } else {
            
            animationController = (currentTransition.operation == .push ? PushAnimator() : PopAnimator())
        }

        let interactionController: UIViewControllerInteractiveTransitioning?
        if currentTransition.isInteractive, let animationController = animationController {
            if let controller = transitioningDelegate?.interactionController(for: animationController) {
                interactionController = controller
            } else {
                interactionController = InteractivePopAnimator(animationController: animationController)
            }
        } else {
            interactionController = nil
        }


        if let delegate = delegate, delegate.isInViewHierarchy, let animationController = animationController {
            let context = TransitionContext(transition: currentTransition, in: viewControllerWrapperView)
            transitionHandler = TransitionHandler(
                transition: currentTransition,
                context: context,
                animationController: animationController,
                interactionController: interactionController
            )
            transitionHandler?.delegate = self
            transitionHandler?.performTransition()
        }
    }

    // MARK: - TransitionHandlerDelegate

    func willStartTransition(using context: TransitionContext) {
        if let from = context.viewController(forKey: .from) {
            delegate?.prepareDisappearance(of: from, animated: context.isAnimated)
        }
        if let to = context.viewController(forKey: .to) {
            delegate?.prepareAppearance(of: to, animated: context.isAnimated)
        }
    }

    func didEndTransition(using context: TransitionContext, didComplete: Bool) {
        if didComplete {
            if let from = context.viewController(forKey: .from) {
                delegate?.finishDisappearance(of: from)
            }
            if let to = context.viewController(forKey: .to) {
                delegate?.finishAppearance(of: to)
            }

            if let from = context.viewController(forKey: .from) {
                if case .pop = context.operation {
                    delegate?.finishRemovingChild(from)
                }
            }

            if let to = context.viewController(forKey: .to) {
                if case .push = context.operation {
                    delegate?.finishAddingChild(to)
                }
            }
        } else {
            if let from = context.viewController(forKey: .from) {
                delegate?.prepareAppearance(of: from, animated: context.isAnimated)
            }
            if let to = context.viewController(forKey: .to) {
                delegate?.prepareDisappearance(of: to, animated: context.isAnimated)
            }
            if let from = context.viewController(forKey: .from) {
                delegate?.finishAppearance(of: from)
            }
            if let to = context.viewController(forKey: .to) {
                delegate?.finishAppearance(of: to)
            }

            currentTransition?.undo?()
        }

        transitionHandler = nil
//        debugTransitionEnded()
    }
    // MARK: - Actions

    @objc func screenEdgeGestureRecognizerDidChangeState(_
        gestureRecognizer: ScreenEdgePanGestureRecognizer) {

        switch gestureRecognizer.state {
        case .began:
            pop(animated: true, interactive: true)
        case .changed:
            transitionHandler?.updateInteractiveTransition(gestureRecognizer)
        case .ended:
            transitionHandler?.stopInteractiveTransition(gestureRecognizer)
        case .cancelled:
            transitionHandler?.cancelInteractiveTransition()
        case .failed, .possible:
            break
        @unknown default:
            assertionFailure()
        }

    }

    // MARK: - Private methods

    private func notifyControllerAboutStackChanges(_ difference: Stack.Difference) {
        let removedViewControllers = difference.removals.map { $0._element }
        notifyControllerOfRemovals(removedViewControllers)

        let insertedViewControllers = difference.insertions.map { $0._element }
        notifyControllerOfInsertions(insertedViewControllers)
    }

    private func notifyControllerOfInsertions(_ insertions: Stack) {
        insertions.dropLast().forEach {
            self.delegate?.prepareAddingChild($0)
            self.delegate?.finishAddingChild($0)
        }
        insertions.suffix(1).forEach {
            self.delegate?.prepareAddingChild($0)
        }
    }

    private func notifyControllerOfRemovals(_ removals: Stack) {
        removals.dropLast().forEach {
            self.delegate?.prepareRemovingChild($0)
            self.delegate?.finishRemovingChild($0)
        }
        removals.suffix(1).forEach {
            self.delegate?.prepareRemovingChild($0)
        }
    }

    private func stackOperation(whenReplacing oldStack: Stack, with newStack: Stack) -> StackViewController.Operation {
        let from = topViewController
        let to = newStack.last

        if let to = to {
            if oldStack.contains(to) { return .pop }
            else { return .push }
        } else {
            if from != nil { return .pop }
            else { return .none }
        }
    }
}