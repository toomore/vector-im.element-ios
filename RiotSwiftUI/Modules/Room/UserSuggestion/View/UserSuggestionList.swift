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

import SwiftUI

struct UserSuggestionList: View {
    private enum Constants {
        static let topPadding: CGFloat = 8.0
        static let listItemPadding: CGFloat = 4.0
        static let lineSpacing: CGFloat = 10.0
        static let maxHeight: CGFloat = 300.0
        static let maxVisibleRows = 4

        /*
         As of iOS 16.0, SwiftUI's List uses `UICollectionView` instead
         of `UITableView` internally, this value is an adjustment to apply
         to the list items in order to be as close as possible as the
         `UITableView` display.
         */
        @available (iOS 16.0, *)
        static let collectionViewPaddingCorrection: CGFloat = -5.0
    }

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    @State private var prototypeListItemFrame: CGRect = .zero
    
    // MARK: Public
    
    @ObservedObject var viewModel: UserSuggestionViewModel.Context
    var showBackgroundShadow: Bool = true
    
    var body: some View {
        if viewModel.viewState.items.isEmpty {
            EmptyView()
        } else {
            ZStack {
                UserSuggestionListItem(avatar: AvatarInput(mxContentUri: "", matrixItemId: "", displayName: "Prototype"),
                                       displayName: "Prototype",
                                       userId: "Prototype")
                    .background(ViewFrameReader(frame: $prototypeListItemFrame))
                    .hidden()
                if showBackgroundShadow {
                    BackgroundView {
                        list()
                    }
                } else {
                    list()
                }
            }
        }
    }
    
    private func contentHeightForRowCount(_ count: Int) -> CGFloat {
        (prototypeListItemFrame.height + (Constants.listItemPadding * 2) + Constants.lineSpacing) * CGFloat(count) + Constants.topPadding
    }

    private func list() -> some View {
        List(viewModel.viewState.items) { item in
            Button {
                viewModel.send(viewAction: .selectedItem(item))
            } label: {
                UserSuggestionListItem(
                    avatar: item.avatar,
                    displayName: item.displayName,
                    userId: item.id
                )
                .modifier(ListItemPaddingModifier(isFirst: viewModel.viewState.items.first?.id == item.id))
            }
        }
        .listStyle(PlainListStyle())
        .frame(height: min(Constants.maxHeight,
                           min(contentHeightForRowCount(Constants.maxVisibleRows),
                               contentHeightForRowCount(viewModel.viewState.items.count))))
        .id(UUID()) // Rebuild the whole list on item changes. Fixes performance issues.
    }

    private struct ListItemPaddingModifier: ViewModifier {
        private let isFirst: Bool

        init(isFirst: Bool) {
            self.isFirst = isFirst
        }

        func body(content: Content) -> some View {
            var topPadding: CGFloat = isFirst ? Constants.listItemPadding + Constants.topPadding : Constants.listItemPadding
            var bottomPadding: CGFloat = Constants.listItemPadding
            if #available(iOS 16.0, *) {
                topPadding += Constants.collectionViewPaddingCorrection
                bottomPadding += Constants.collectionViewPaddingCorrection
            }

            return content
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
        }
    }
}

private struct BackgroundView<Content: View>: View {
    var content: () -> Content
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    private let shadowRadius: CGFloat = 20.0
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
            .background(theme.colors.background)
            .clipShape(RoundedCornerShape(radius: shadowRadius, corners: [.topLeft, .topRight]))
            .shadow(color: .black.opacity(0.20), radius: 20.0, x: 0.0, y: 3.0)
            .mask(Rectangle().padding(.init(top: -(shadowRadius * 2), leading: 0.0, bottom: 0.0, trailing: 0.0)))
            .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Previews

struct UserSuggestion_Previews: PreviewProvider {
    static let stateRenderer = MockUserSuggestionScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
