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
import Reusable
import UIKit
import MatrixSDK

protocol VoiceMessagePlaybackViewDelegate: AnyObject {
    func voiceMessagePlaybackViewDidRequestPlaybackToggle()
    func voiceMessagePlaybackViewDidRequestSeek(to progress: CGFloat)
    func voiceMessagePlaybackViewDidChangeWidth()
}

struct VoiceMessagePlaybackViewDetails {
    var currentTime: String = ""
    var progress = 0.0
    var samples: [Float] = []
    var playing: Bool = false
    var playbackEnabled = false
    var recording: Bool = false
    var loading: Bool = false
}

class VoiceMessagePlaybackView: UIView, NibLoadable, Themable {
    
    private enum Constants {
        static let backgroundCornerRadius: CGFloat = 12.0
    }
    
    private var _waveformView: VoiceMessageWaveformView!
    private var currentTheme: Theme?
    private var scrubProgress: CGFloat?
    
    @IBOutlet private var backgroundView: UIView!
    @IBOutlet private var recordingIcon: UIView!
    @IBOutlet private var playButton: UIButton!
    @IBOutlet private var elapsedTimeLabel: UILabel!
    @IBOutlet private var waveformContainerView: UIView!
    
    weak var delegate: VoiceMessagePlaybackViewDelegate?
    
    var details: VoiceMessagePlaybackViewDetails?
    
    var waveformView: UIView {
        return _waveformView
    }
    
    override var bounds: CGRect {
        didSet {
            if oldValue.width != bounds.width {
                delegate?.voiceMessagePlaybackViewDidChangeWidth()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundView.layer.cornerRadius = Constants.backgroundCornerRadius
        playButton.layer.cornerRadius = playButton.bounds.width / 2.0
        
        _waveformView = VoiceMessageWaveformView(frame: waveformContainerView.bounds)
        waveformContainerView.vc_addSubViewMatchingParent(_waveformView)
    }
    
    func configureWithDetails(_ details: VoiceMessagePlaybackViewDetails?) {
        guard let details = details else {
            return
        }
        
        playButton.isEnabled = details.playbackEnabled
        playButton.setImage((details.playing ? Asset.Images.voiceMessagePauseButton.image : Asset.Images.voiceMessagePlayButton.image), for: .normal)
        
        UIView.performWithoutAnimation {
            // UIStackView doesn't respond well to re-setting hidden states https://openradar.appspot.com/22819594
            if playButton.isHidden != details.recording {
                playButton.isHidden = details.recording
            }
            
            // UIStackView doesn't respond well to re-setting hidden states https://openradar.appspot.com/22819594
            if recordingIcon.isHidden != !details.recording {
                recordingIcon.isHidden = !details.recording
            }
        }
        
        if details.loading {
            elapsedTimeLabel.text = "--:--"
            _waveformView.progress = 0
            _waveformView.samples = []
            _waveformView.alpha = 0.3
        } else {
            elapsedTimeLabel.text = details.currentTime
            _waveformView.progress = details.progress
            _waveformView.samples = details.samples
            _waveformView.alpha = 1.0
        }
        
        self.details = details
        
        guard let theme = currentTheme else {
            return
        }
        
        self.backgroundColor = theme.colors.background
        playButton.backgroundColor = theme.colors.background
        playButton.tintColor = theme.colors.secondaryContent
        backgroundView.backgroundColor = theme.colors.quinaryContent
        _waveformView.primaryLineColor =  theme.colors.quarterlyContent
        _waveformView.secondaryLineColor = theme.colors.secondaryContent
        elapsedTimeLabel.textColor = theme.colors.tertiaryContent
    }
    
    func getRequiredNumberOfSamples() -> Int {
        _waveformView.setNeedsLayout()
        _waveformView.layoutIfNeeded()
        return _waveformView.requiredNumberOfSamples
    }
    
    // MARK: - Themable
    
    func update(theme: Theme) {
        currentTheme = theme
        configureWithDetails(details)
    }
    
    // MARK: - Private
        
    @IBAction private func onPlayButtonTap() {
        delegate?.voiceMessagePlaybackViewDidRequestPlaybackToggle()
    }
    
    @IBAction private func tap(gestureRecognizer: UITapGestureRecognizer) {
        let x = gestureRecognizer.location(in: waveformContainerView).x.clamped(to: 0...waveformContainerView.bounds.width)
        let progress = x / waveformContainerView.bounds.width
        let seekPoint = progress == 1 ? 0 : progress
        delegate?.voiceMessagePlaybackViewDidRequestSeek(to: seekPoint)
    }

    @IBAction private func pan(gestureRecognizer: UIPanGestureRecognizer) {
            switch gestureRecognizer.state {
            case .began, .changed:
                let x = gestureRecognizer.location(in: waveformContainerView).x.clamped(to: 0...waveformContainerView.bounds.width)
                scrubProgress = x / waveformContainerView.bounds.width
                let seekPoint = scrubProgress == 1 ? 0 : scrubProgress ?? 0
                delegate?.voiceMessagePlaybackViewDidRequestSeek(to: seekPoint)
            default:
                scrubProgress = nil
            }
        }
}
