// 
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
@testable import RiotSwiftUI
import XCTest

final class PollHistoryViewModelTests: XCTestCase {
    private var viewModel: PollHistoryViewModel!
    private var pollHistoryService: MockPollHistoryService = .init()

    override func setUpWithError() throws {
        pollHistoryService = .init()
        viewModel = .init(mode: .active, pollService: pollHistoryService)
    }

    func testEmitsContentOnLanding() throws {
        XCTAssert(viewModel.state.polls == nil)
        viewModel.process(viewAction: .viewAppeared)
        XCTAssertFalse(try polls.isEmpty)
    }
    
    func testLoadingState() throws {
        XCTAssertFalse(viewModel.state.isLoading)
        viewModel.process(viewAction: .viewAppeared)
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertFalse(try polls.isEmpty)
    }
    
    func testLoadingStateIsTrueWhileLoading() {
        XCTAssertFalse(viewModel.state.isLoading)
        pollHistoryService.nextBatchPublishers = [MockPollPublisher.loadingPolls, MockPollPublisher.emptyPolls]
        viewModel.process(viewAction: .viewAppeared)
        XCTAssertTrue(viewModel.state.isLoading)
        viewModel.process(viewAction: .viewAppeared)
        XCTAssertFalse(viewModel.state.isLoading)
    }
    
    func testUpdatesAreHandled() throws {
        let mockUpdates: PassthroughSubject<TimelinePollDetails, Never> = .init()
        pollHistoryService.updatesPublisher = mockUpdates.eraseToAnyPublisher()
        viewModel.process(viewAction: .viewAppeared)
        
        var firstPoll = try XCTUnwrap(try polls.first)
        XCTAssertEqual(firstPoll.question, "Do you like the active poll number 1?")
        firstPoll.question = "foo"
        
        mockUpdates.send(firstPoll)
        
        let updatedPoll = try XCTUnwrap(viewModel.state.polls?.first)
        XCTAssertEqual(updatedPoll.question, "foo")
    }
    
    func testSegmentsAreUpdated() throws {
        viewModel.process(viewAction: .viewAppeared)
        XCTAssertFalse(try polls.isEmpty)
        XCTAssertTrue(try polls.allSatisfy { !$0.closed })
        
        viewModel.state.bindings.mode = .past
        viewModel.process(viewAction: .segmentDidChange)
        
        XCTAssertTrue(try polls.allSatisfy(\.closed))
    }
    
    func testPollsAreReverseOrdered() throws {
        viewModel.process(viewAction: .viewAppeared)
        
        let pollDates = try polls.map(\.startDate)
        XCTAssertEqual(pollDates, pollDates.sorted(by: { $0 > $1 }))
    }
    
    func testLivePollsAreHandled() throws {
        pollHistoryService.nextBatchPublishers = [MockPollPublisher.emptyPolls]
        pollHistoryService.livePollsPublisher = Just(mockPoll).eraseToAnyPublisher()
        viewModel.process(viewAction: .viewAppeared)
        XCTAssertEqual(viewModel.state.polls?.count, 1)
        XCTAssertEqual(viewModel.state.polls?.first?.id, "id")
    }
    
    func testLivePollsDontChangeLoadingState() throws {
        let livePolls = PassthroughSubject<TimelinePollDetails, Never>()
        pollHistoryService.nextBatchPublishers = [MockPollPublisher.loadingPolls]
        pollHistoryService.livePollsPublisher = livePolls.eraseToAnyPublisher()
        viewModel.process(viewAction: .viewAppeared)
        XCTAssertTrue(viewModel.state.isLoading)
        XCTAssertNil(viewModel.state.polls)
        livePolls.send(mockPoll)
        XCTAssertTrue(viewModel.state.isLoading)
        XCTAssertNotNil(viewModel.state.polls)
        XCTAssertEqual(viewModel.state.polls?.count, 1)
    }
    
    func testAfterFailureCompletionIsCalled() throws {
        let expectation = expectation(description: #function)
        
        pollHistoryService.nextBatchPublishers = [MockPollPublisher.failure]
        viewModel.completion = { event in
            XCTAssertEqual(event, .genericError)
            expectation.fulfill()
        }
        viewModel.process(viewAction: .viewAppeared)
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertNotNil(viewModel.state.polls)
        
        wait(for: [expectation], timeout: 1.0)
    }
}

private extension PollHistoryViewModelTests {
    var polls: [TimelinePollDetails] {
        get throws {
            try XCTUnwrap(viewModel.state.polls)
        }
    }
    
    var mockPoll: TimelinePollDetails {
        .init(id: "id",
              question: "Do you like polls?",
              answerOptions: [],
              closed: false,
              startDate: .init(),
              totalAnswerCount: 3,
              type: .undisclosed,
              eventType: .started,
              maxAllowedSelections: 1,
              hasBeenEdited: false,
              hasDecryptionError: false)
    }
}
