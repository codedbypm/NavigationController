//
//  NavigationController.swift
//  TestApp
//
//  Created by Paolo Moroni on 01/05/2019.
//  Copyright © 2019 codedby.pm. All rights reserved.
//

import UIKit
import StackViewController

class NavigationController: UINavigationController, ConsoleDebuggable {

    var debugDelegate: DebugDelegate?


    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    convenience override init(rootViewController: UIViewController) {
        self.init(nibName: nil, bundle: nil)
        viewControllers = [rootViewController]
        debugFunc(#function, allowed: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        debugFunc(#function, allowed: true)
    }

    override var description: String {
        return "UINC"
    }

    override func addChild(_ childController: UIViewController) {
        super.addChild(childController)
        debugFunc(#function, allowed: true)
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: true)
        
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        let returned = super.popViewController(animated: animated)
        return returned
    }
}

extension NavigationController: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        print("Operation: \(operation.rawValue)")
        print("From: \(fromVC)")
        print("To: \(toVC == nil ? "nil" : toVC.description)")

        switch operation {
        case .push:
            return PushAnimator()
        case .pop:
            return PopAnimator()
        default:
            return nil
        }
    }

    //    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
    //
    //        guard let gestureRecognizer = navigationController.interactivePopGestureRecognizer as? UIScreenEdgePanGestureRecognizer else { return nil }
    //
    //        gestureRecognizer.removeTarget(nil, action: nil)
    //        interactionController = HorizontalSlideInteractiveController(animationController: animationController,
    //                                                                     gestureRecognizer: gestureRecognizer)
    //        return interactionController
    //    }
}