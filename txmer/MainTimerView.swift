//
//  ContentView.swift
//  timer
//
//  Created by Tim Xie on 21/11/21.
//

import CoreData
import SwiftUI
import CoreGraphics


var userHoldTime: Double = 0.5 /// todo make so user can set in setting

enum stopWatchMode {
    case running
    case stopped
}

// TO left = discard
// TO right = reload scramble
// Double Tap = penalty menu

class StopWatchManager: ObservableObject {
    @Binding var currentSession: Sessions?
    let managedObjectContext: NSManagedObjectContext
    var mode: stopWatchMode = .stopped
    
    let scrambler = CHTScrambler.init()
    
    var scrambleType: Int32
    var scrambleSubType: Int32 = 0
    
    var prevScrambleStr: String? = nil
    var scrambleStr: String? = nil
    
    init (currentSession: Binding<Sessions?>, managedObjectContext: NSManagedObjectContext) {
        _currentSession = currentSession
        self.managedObjectContext = managedObjectContext
        scrambler.initSq1()
        scrambleType = (currentSession.wrappedValue?.scramble_type)!
        let scr = CHTScramble.getNewScramble(by: scrambler, type: scrambleType, subType: scrambleSubType)
        scrambleStr = scr?.scramble
    }
    
    private var timerStartTime: Date?
    
    @Published var secondsElapsed = 0.0
    
    @Environment(\.colorScheme) var colourScheme
    
    var timer = Timer()
    
    /// todo set custom fps for battery purpose, promotion can set as low as 10 / 24hz ,others 60 fixed, no option for them >:C
    var frameTime: Double = 1/60
    
    func start() {
        mode = .running
        
        secondsElapsed = 0
        timerStartTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: frameTime, repeats: true) { [self] timer in
            self.secondsElapsed = -timerStartTime!.timeIntervalSinceNow
        }
    }
    
    func stop() {
        timer.invalidate()
        mode = .stopped

    }
    
    @Published var timerColour: Color = TimerTextColours.timerDefaultColour
    
    private var canStartTimer = false
    
    private var taskTimerReady: DispatchWorkItem?
    
    private let feedbackStyle = UIImpactFeedbackGenerator(style: .medium) /// TODO: add option to change heaviness/turn on off in settings
    
    private var prevIsDown = false
    
    func touchDown() {
        if !prevIsDown {
            prevIsDown = true
            timerColour = TimerTextColours.timerHeldDownColour
            NSLog("Down")
            if mode == .running {
                stop()
                let solveItem = Solves(context: managedObjectContext)
                // .comment
                solveItem.date = Date()
                // .penalty
                // .puzzle_id
                NSLog("Saving with sesion \(currentSession)")
                NSLog("Saving with context \(solveItem.managedObjectContext)")
                NSLog("currentSession's context is \(currentSession!.managedObjectContext)")
                solveItem.session = currentSession /// ???
                // currentSession!.addToSolves(solveItem)
                solveItem.scramble = prevScrambleStr
                solveItem.scramble_type = scrambleType
                solveItem.scramble_subtype = scrambleSubType
                // .starred
                solveItem.time = self.secondsElapsed
                do {
                    try managedObjectContext.save()
                } catch {
                    if let error = error as NSError? {
                        // Replace this implementation with code to handle the error appropriately.
                        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                        /*
                        Typical reasons for an error here include:
                        * The parent directory does not exist, cannot be created, or disallows writing.
                        * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                        * The device is out of space.
                        * The store could not be migrated to the current model version.
                        Check the error message to determine what the actual problem was.
                        */
                        fatalError("Unresolved error \(error), \(error.userInfo)")
                    }
                }
            } else { // TODO on update gesture cancels the taskAfterHold once a drag started past a certain threshold
                let newTaskTimerReady = DispatchWorkItem {
                    self.canStartTimer = true
                    self.timerColour = TimerTextColours.timerCanStartColour
                    self.feedbackStyle.impactOccurred()
                }
                taskTimerReady = newTaskTimerReady
                DispatchQueue.main.asyncAfter(deadline: .now() + userHoldTime, execute: newTaskTimerReady)
                
            }
        }
    }
    
    func touchUp(value: DragGesture.Value) {
        prevIsDown = false
        NSLog("up")
        taskTimerReady?.cancel()
        
        timerColour = ((colourScheme == .light) ? Color.black : Color.white)
        
        let hAmount = value.translation.width as CGFloat
        let vAmount = value.translation.height as CGFloat
        let threshold = 20 as CGFloat
        
        if abs(hAmount) > threshold && abs(vAmount) < abs(hAmount) {
            if hAmount > 0 {
                NSLog("Right")
            } else {
                NSLog("Left")
            }
        } else if abs(vAmount) > threshold && abs(hAmount) < abs(vAmount) {
            if vAmount > 0 {
                NSLog("Down")
            } else {
                NSLog("Up")
            }
        }
        // TODO disallow gestures after 200 ms
        if canStartTimer {
            NSLog("minimumTapDurationMet, starting timer.")
            start()
            canStartTimer = false
            prevScrambleStr = scrambleStr
            let scr = CHTScramble.getNewScramble(by: scrambler, type: scrambleType, subType: scrambleSubType)
            scrambleStr = scr?.scramble
        }
    }
}

public enum ButtonState {
    case pressed
    case notPressed
}

extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}


struct SubTimerView: View {
    //@ObservedObject var currentSession: Sessions
    
    @ObservedObject var stopWatchManager: StopWatchManager
    
    
    @Environment(\.colorScheme) var colourScheme
    
    
    init(/*currentSession: ObservedObject<Sessions>, */stopWatchManager: StopWatchManager) {
        //_currentSession = currentSession
        self.stopWatchManager = stopWatchManager
    }

    var body: some View {
        ZStack {
            
            
            Color(colourScheme == .light ? UIColor.systemGray6 : UIColor.black) /// todo make so user can change colour/changes dynamically with system theme - but when dark mode, change systemgray6 -> black (or not full black >:C)
                .ignoresSafeArea()
            
            
            
            VStack {
                Text(stopWatchManager.scrambleStr ?? "Loading scramble")
                    //.background(Color.red)
                    .padding(22)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .position(x: UIScreen.screenWidth / 2, y: 108)
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                
                               
            }
            
            
            Text(formatSolveTime(secs: stopWatchManager.secondsElapsed))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(stopWatchManager.timerColour)
                       
            GeometryReader { geometry in
                VStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.0000000001)) /// TODO: fix this don't just use this workaround: https://stackoverflow.com/questions/56819847/tap-action-not-working-when-color-is-clear-swiftui
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height - CGFloat(SetValues.tabBarHeight) /* - CGFloat(safeAreaBottomHeight) */,
                            alignment: .center
                            //height: geometry.safeAreaInsets.top,
                            //height:  - safeAreaInset(edge: .bottom) - CGFloat(tabBarHeight),
                        )
                        /*
                        .modifier(Touch(changeState: { (buttonState) in
                            
                            
                            if buttonState == .pressed { /// ON TOUCH DOWN EVENT
                                self.stopWatchManager.touchDown()
                            } else { /// ON TOUCH UP (FINGER RELEASE) EVENT
                                self.stopWatchManager.touchUp()
                            }
                        }))
                        //.safeAreaInset(edge: .bottom)
                         //.aspectRatio(contentMode: ContentMode.fit)
                         */
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                .onChanged({_ in
                                    stopWatchManager.touchDown()
                                })
                                .onEnded({ value in
                                    stopWatchManager.touchUp(value: value)
                                })
                        )
                }
            }
        }
    }
}

struct MainTimerView: View {
    @Binding var currentSession: Sessions?
    @Environment(\.managedObjectContext) var managedObjectContext
          
    
    var body: some View {
        /// Please see https://developer.apple.com/forums/thread/658313
        /// For why I did this abomination
        /// Please file a PR if you know a better way
        SubTimerView(stopWatchManager: StopWatchManager(currentSession: _currentSession, managedObjectContext: managedObjectContext))
    }
}

/*
struct MainTimerView_Previews: PreviewProvider {
    static var previews: some View {
        MainTimerView()
    }
}

*/
