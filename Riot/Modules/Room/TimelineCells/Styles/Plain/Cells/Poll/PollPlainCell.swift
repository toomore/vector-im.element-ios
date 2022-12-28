// 
// Copyright 2021 New Vector Ltd
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

import Foundation

class PollPlainCell: SizableBaseRoomCell, RoomCellReactionsDisplayable, RoomCellReadMarkerDisplayable {

    private var event: MXEvent?
    private var supportedEventTypes: Set<__MXEventType> = [.pollStart, .pollEnd]
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        guard
            let contentView = roomCellContentView?.innerContentView,
            let bubbleData = cellData as? RoomBubbleCellData,
            let event = bubbleData.events.last,
            supportedEventTypes.contains(event.eventType),
            let controller = TimelinePollProvider.shared.buildTimelinePollVCForEvent(event)
        else {
            return
        }
        
        self.event = event
        self.addContentViewController(controller, on: contentView)
    }
    
    override func setupViews() {
        super.setupViews()
        
        roomCellContentView?.backgroundColor = .clear
        roomCellContentView?.showSenderInfo = true
        roomCellContentView?.showPaginationTitle = false
    }
    
    // The normal flow for tapping on cell content views doesn't work for bubbles without attributed strings
    override func onContentViewTap(_ sender: UITapGestureRecognizer) {
        guard let event = self.event else {
            return
        }
        
        delegate.cell(self, didRecognizeAction: kMXKRoomBubbleCellTapOnContentView, userInfo: [kMXKRoomBubbleCellEventKey: event])
    }
}

extension PollPlainCell: RoomCellThreadSummaryDisplayable {}
