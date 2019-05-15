//
//  StackViewControllerTests.swift
//  StackViewControllerTests
//
//  Created by Paolo Moroni on 24/04/2019.
//  Copyright © 2019 codedby.pm. All rights reserved.
//

import XCTest
import UIKit

@testable import StackViewController

class StackViewControllerTests: XCTestCase {
    var sut: StackViewController!

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThat_whenTheGestureRecognizerSendItsAction_itCallshandleScreenEdgePanGestureRecognizerStateChangeOnTheInteractor() {
        // Arrange
        let gestureRecognizer = ScreenEdgePanGestureRecognizer(target: nil, action: nil)
        let stackHandler = StackHandler.init()
        let interactor = MockStackViewControllerInteractor(stackHandler: stackHandler)
        sut = StackViewController(interactor: interactor)

        XCTAssertNil(interactor.didCallHandleScreenEdgePanGestureRecognizerStateChange)
        XCTAssertNil(interactor.gestureRecognizer)

        // Act
        sut.screenEdgeGestureRecognizerDidChangeState(gestureRecognizer)

        // Assert
        XCTAssertEqual(interactor.didCallHandleScreenEdgePanGestureRecognizerStateChange, true)
        XCTAssertTrue(interactor.gestureRecognizer === gestureRecognizer)
    }

    // MARK: - didAddStackElements(_: Stack)

    /// UIKit sends the event in this sequence
    ///
    /// - VC1 willMove
    /// - VC1 didMove
    /// - VC2 willMove
    /// - ...
    ///
    /// To guarantee the same behavior, this tests mark for each view controller the time stamp of
    /// both calls `willMoveToParent` and `didMoveToPatent`. After that, flatMapping the sequence got
    /// from zip(willDates, didDates) and adding the very last willMove, will give the ordered
    /// array of timestamps.
//    func testThat_whenAddingElementsToTheStack_theViewContainmentEventsAreSentTheSameWayUIKitDoes() {
//        // Arrange
//        sut = StackViewController.withEmptyStack()
//        let stack: [MockViewController] = Stack.distinctElements(4)
//
//        // Act
////        sut.didAddStackElements(stack)
//
//        // Assert
//        let willMoveDates = stack.compactMap { $0.willMoveToParentDate }
//        XCTAssertEqual(willMoveDates.count, 4)
//
//        let didMoveDates = stack.compactMap { $0.didMoveToParentDate }
//        XCTAssertEqual(didMoveDates.count, 3)
//
//        var flattenedDates = zip(willMoveDates, didMoveDates).flatMap({ return [$0, $1] })
//        flattenedDates.append(contentsOf: willMoveDates.suffix(1))
//        XCTAssertEqual(flattenedDates, flattenedDates.sorted())
//        XCTAssertEqual(flattenedDates.count, 7)
//    }
//
//    // MARK: - didRemoveStackElements(_: Stack)
//
//    func testThat_whenRemovingElementsFromTheStack_theViewContainmentEventsAreSentTheSameWayUIKitDoes() {
//        // Arrange
//        let stack: [MockViewController] = Stack.distinctElements(4)
//        sut = StackViewController(viewControllers: stack)
//
//        // Act
////        sut.didRemoveStackElements(stack)
//
//        // Assert
//        let willMoveDates = stack.compactMap { $0.willMoveToParentDate }
//        XCTAssertEqual(willMoveDates.count, 4)
//
//        let didMoveDates = stack.compactMap { $0.didMoveToParentDate }
//        XCTAssertEqual(didMoveDates.count, 4)
//
//        let flattenedDates = zip(willMoveDates, didMoveDates).flatMap({ return [$0, $1] })
//        XCTAssertEqual(flattenedDates, flattenedDates.sorted())
//        XCTAssertEqual(flattenedDates.count, 8)
//    }


//    Start NC with stack = [Black, Red, Green]
//  
//    [UIKit] Black    =>    willMove(toParent:)
//    [UIKit] Black    =>    didMove(toParent:)
//    [UIKit] Red    =>    willMove(toParent:)
//    [UIKit] Red    =>    didMove(toParent:)
//    [UIKit] Green    =>    willMove(toParent:)
    func testThat_whenInitWithANonEmptyStack_itSendsCorrectSequenceOfEventsToHisChildren() {
        // Arrange
        let stack: [MockViewController] = Stack.distinctElements(3)

        // Act
        sut = StackViewController(viewControllers: stack)

        // Assert
        let willMoveDates = stack.compactMap { $0.willMoveToParentDate }
        XCTAssertEqual(willMoveDates.count, 3)

        let didMoveDates = stack.compactMap { $0.didMoveToParentDate }
        XCTAssertEqual(didMoveDates.count, 2)

        var flattenedDates = zip(willMoveDates, didMoveDates).flatMap({ return [$0, $1] })
        flattenedDates.append(contentsOf: willMoveDates.suffix(1))
        XCTAssertEqual(flattenedDates, flattenedDates.sorted())
        XCTAssertEqual(flattenedDates.count, 5)
    }
}
