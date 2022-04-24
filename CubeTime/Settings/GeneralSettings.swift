import SwiftUI


enum gsKeys: String {
    case inspection, freeze, timeDpWhenRunning, hapBool, hapType, gestureDistance, displayDP, showScramble, showStats, scrambleSize, inspectionCountsDown, compressionStrength
}

extension UIImpactFeedbackGenerator.FeedbackStyle: CaseIterable {
    public static var allCases: [UIImpactFeedbackGenerator.FeedbackStyle] = [.light, .medium, .heavy, .soft, .rigid]
    var localizedName: String { "\(self)" }
}

struct GeneralSettingsView: View {
    // timer settings
    @AppStorage(gsKeys.inspection.rawValue) private var inspectionTime: Bool = false
    @AppStorage(gsKeys.inspectionCountsDown.rawValue) private var insCountDown: Bool = false
    @AppStorage(gsKeys.freeze.rawValue) private var holdDownTime: Double = 0.5
    @AppStorage(gsKeys.timeDpWhenRunning.rawValue) private var timerDP: Int = 3
    
    // timer tools
    @AppStorage(gsKeys.showScramble.rawValue) private var showScramble: Bool = true
    @AppStorage(gsKeys.showStats.rawValue) private var showStats: Bool = true
    
    // accessibility
    @AppStorage(gsKeys.hapBool.rawValue) private var hapticFeedback: Bool = true
    @AppStorage(gsKeys.hapType.rawValue) private var feedbackType: UIImpactFeedbackGenerator.FeedbackStyle = .rigid
    @AppStorage(gsKeys.scrambleSize.rawValue) private var scrambleSize: Int = 18
    @AppStorage(gsKeys.gestureDistance.rawValue) private var gestureActivationDistance: Double = 50
    
    // statistics
    @AppStorage(gsKeys.displayDP.rawValue) private var displayDP: Int = 3
    
        
    @Environment(\.colorScheme) var colourScheme
    @EnvironmentObject var stopWatchManager: StopWatchManager
    
    @AppStorage(asKeys.accentColour.rawValue) private var accentColour: Color = .indigo
    
    @AppStorage(gsKeys.compressionStrength.rawValue) private var compressionStrength: Int = 11
    
    let hapticNames: [UIImpactFeedbackGenerator.FeedbackStyle: String] = [
        UIImpactFeedbackGenerator.FeedbackStyle.light: "Light",
        UIImpactFeedbackGenerator.FeedbackStyle.medium: "Medium",
        UIImpactFeedbackGenerator.FeedbackStyle.heavy: "Heavy",
        UIImpactFeedbackGenerator.FeedbackStyle.soft: "Soft",
        UIImpactFeedbackGenerator.FeedbackStyle.rigid: "Rigid"
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            SettingsGroup(name: "Timer Settings", iconname: "timer") {
                SettingsToggle(isOn: $inspectionTime.animation(.spring()), text: "Inspection Time")
                .onChange(of: inspectionTime) { newValue in
                    stopWatchManager.inspectionEnabled = newValue
                }
                
                Divider()
                
                if inspectionTime {
                    SettingsToggle(isOn: $insCountDown, text: "Inspection Counts Down")
                    .onChange(of: insCountDown) { newValue in
                        stopWatchManager.insCountDown = newValue
                    }
                    
                    Divider()
                }
                
                Stepper(value: $holdDownTime, in: 0.05...1.0, step: 0.05) {
                    Text("Hold Down Time: ")
                        .font(.system(size: 17, weight: .medium))
                    Text(String(format: "%.2fs", holdDownTime))
                }
                
                Divider()
                    
                SettingsPicker(selection: $timerDP, text: "Timer Update") {
                    Text("Nothing")
                        .tag(-1)
                    ForEach(0...3, id: \.self) {
                        Text("\($0) d.p")
                    }
                }
                .onChange(of: timerDP) { newValue in
                    stopWatchManager.timeDP = newValue
                }
            }
            
            SettingsGroup(name: "Timer Tools", iconname: "wrench") {
                SettingsToggle(isOn: $showScramble, text: "Show draw scramble on timer")
                .onChange(of: inspectionTime) { newValue in
                    stopWatchManager.inspectionEnabled = newValue
                }
                
                Divider()
                
                
                SettingsToggle(isOn: $showStats, text: "Show stats on timer")
                .onChange(of: inspectionTime) { newValue in
                    stopWatchManager.inspectionEnabled = newValue
                }
                
                Text("Show scramble/statistics on the timer screen.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(uiColor: .systemGray))
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 2)
            }
            
            SettingsGroup(name: "Accessibility", iconname: "eye") {
                SettingsToggle(isOn: $hapticFeedback, text: "Haptic Feedback")
                .onChange(of: hapticFeedback) { newValue in
                    
                    stopWatchManager.hapticEnabled = newValue
                    stopWatchManager.calculateFeedbackStyle()
                }
                
                if hapticFeedback {
                    SettingsPicker(selection: $feedbackType, text: "Haptic Mode") {
                        ForEach(Array(UIImpactFeedbackGenerator.FeedbackStyle.allCases), id: \.self) { mode in
                            Text(hapticNames[mode]!)
                        }
                    }
                    .onChange(of: feedbackType) { newValue in
                        stopWatchManager.hapticType = newValue.rawValue
                        stopWatchManager.calculateFeedbackStyle()
                        UIImpactFeedbackGenerator(style: newValue).impactOccurred()
                    }
                }
                
                Divider()
                
                Stepper(value: $scrambleSize, in: 15...36, step: 1) {
                    Text("Scramble Size: ")
                        .font(.system(size: 17, weight: .medium))
                    Text("\(scrambleSize)")
                }
                
                Divider()
                
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Gesture Activation Distance")
                        .font(.system(size: 17, weight: .medium))
                        .padding(.bottom, 4)
                    
                    HStack {
                        Text("MIN")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(Color(uiColor: .systemGray2))
                        
                        Slider(value: $gestureActivationDistance, in: 20...300)
                            .padding(.horizontal, 4)
                        
                        Text("MAX")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(Color(uiColor: .systemGray2))
                        
                    }
                    
                }
                
            }
            
            SettingsGroup(name: "Statistics", iconname: "chart.bar.xaxis") {
                SettingsPicker(selection: $displayDP, text: "Times Displayed To: ") {
                    ForEach(2...3, id: \.self) {
                        Text("\($0) d.p")
                            .tag($0)
                    }
                }
            }
            
            SettingsGroup(name: "Advanced", iconname: "gear") {
                Stepper(value: $compressionStrength, in: -7...22, step: 1) {
                    Text("Compression Strength: ")
                        .font(.system(size: 17, weight: .medium))
                    Text(String(compressionStrength))
                }
            }
        }
        .padding(.horizontal)
    }
}
