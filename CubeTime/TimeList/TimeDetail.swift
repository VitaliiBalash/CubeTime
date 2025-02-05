//
//  TimeDetail.swift
//  CubeTime
//
//  Created by Tim Xie on 10/01/22.
//

import SwiftUI

struct TimeDetail: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var stopWatchManager: StopWatchManager
    
    let solve: Solves
    @Binding var currentSolve: Solves?
    
    
    init(solve: Solves, currentSolve: Binding<Solves?>?) {
        
        self.solve = solve
        self._currentSolve = currentSolve ?? Binding.constant(nil)
        
    }
    
    var body: some View {
        NavigationView {
            TimeDetailViewOnly(solve: solve, currentSolve: $currentSolve)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { // Only show delete if called from timelist and not stats
                    Button {
                        if currentSolve == nil {
                            dismiss()
                        }
                        
                        currentSolve = nil
                        
                        withAnimation {
                            stopWatchManager.delete(solve: solve)
                        }
                    } label: {
                        Text("Delete Solve")
                            .font(.body.weight(.medium))
                            .foregroundColor(Color.red)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        currentSolve = nil
                        
                        dismiss()
                        
                        if managedObjectContext.hasChanges {
                            try! managedObjectContext.save()
                        }
                    } label: {
                        Text("Done")
                    }
                }
            }
        }
    }
}


struct TimeDetailViewOnly: View {
    @Environment(\.presentationMode) var presentation
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.colorScheme) var colourScheme
    
    private let titleDateFormat: DateFormatter
    
    @State var offsetValue: CGFloat = -25
    
    @FocusState private var commentFocus: Bool
    
    let solve: Solves
    
    // Copy all items out of solve that are used by the UI
    // This is so that when the item is deleted they don't reset to default values
    let date: Date
    let time: String
    let puzzle_type: PuzzleType
    let scramble: String
    let phases: Array<Double>?
    
    
    private let windowSize = UIApplication.shared.connectedScenes.compactMap({ scene -> UIWindow? in
                                (scene as? UIWindowScene)?.keyWindow
                            }).first?.frame.size
    
    @Binding var currentSolve: Solves?
    
    @State private var userComment: String
    
    
    init(solve: Solves, currentSolve: Binding<Solves?>?){
        self.solve = solve
        self.date = solve.date ?? Date(timeIntervalSince1970: 0)
        self.time = formatSolveTime(secs: solve.time, penType: PenTypes(rawValue: solve.penalty)!)
        self.puzzle_type = puzzle_types[Int(solve.scramble_type)]
        self.scramble = solve.scramble ?? "Retrieving scramble failed."
            
        if let multiphaseSolve = (solve as? MultiphaseSolve) {
            self.phases = multiphaseSolve.phases ?? [0.00, 0.00, 0.00, 0.00]
//            Array(zip(multiphaseSolve.phases!.indices, multiphaseSolve.phases!))
        } else {
            self.phases = nil
        }
        
        self._currentSolve = currentSolve ?? Binding.constant(nil)
        _userComment = State(initialValue: solve.comment ?? "")

        
        self.titleDateFormat = DateFormatter()
        
        titleDateFormat.locale = Locale(identifier: "en_US_POSIX")
        titleDateFormat.timeZone = TimeZone(secondsFromGMT: 0)
        titleDateFormat.dateFormat = "h:mm a, MMM d, yyyy"
        
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: colourScheme == .light ? .systemGray6 : .black)
                .ignoresSafeArea()
            
            ScrollView {
                VStack (spacing: 12) {
                    HStack {
                        Text(time)
                            .font(.largeTitle.weight(.bold))
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    HStack {
                        Text(date, formatter: titleDateFormat)
                            .font(.title2.weight(.semibold))
                            .foregroundColor(Color(uiColor: .systemGray))
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, -10)
                    
                    VStack {
                        HStack {
                            Image(puzzle_type.name)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                
                                .padding(.leading, 2)
                                .padding(.trailing, 4)
                            
                            Text(puzzle_type.name)
                                .font(.body.weight(.semibold))
                            
                            Spacer()
                            
                            Text((["2x2", "3x3", "Square-1", "Pyraminx", "Skewb", "3x3 OH", "3x3 BLD"].contains(puzzle_type.name)) ? "RANDOM STATE" : "RANDOM MOVES")
                                .font(.footnote.weight(.semibold))
                                .offset(y: 2)
                        }
                        .padding(.leading, 12)
                        .padding(.trailing)
                        .padding(.top, 12)
                        
                        Divider()
                            .padding(.leading)
                        
                        let brokenScramble: Bool = chtscramblesthatdontworkwithtnoodle.contains(puzzle_type.puzzle) && (date < Date(timeIntervalSince1970: TimeInterval(1643760000)))
                        
                        Group {
                            if puzzle_type.name == "Megaminx" {
                                Text(scramble.dropLast())
                                    .font(.system(size: (windowSize!.width-32) / (42.00) * 1.44, weight: .regular, design: .monospaced))
                            } else {
                                Text(scramble)
                                    .font(.callout.monospaced())
                            }
                        }
                        .foregroundColor(colourScheme == .light ? .black : .white)
                        .padding([.horizontal], 12)
                        .padding(.bottom, brokenScramble ? 12 : 0)
                        
                        
                        if !(brokenScramble) {
                            Divider()
                                .padding(.leading)
                            
                            GeometryReader { proxy in
                                AsyncScrambleView(puzzle: puzzle_type.puzzle, scramble: scramble, width: 10, height: 10)
                                    .position(x: proxy.frame(in: .local).midX, y: proxy.frame(in: .local).midY)
                            }
                            .frame(width: nil, height: UIScreen.screenHeight / 3.5)
                            .padding([.horizontal, .bottom])
                            .padding(.top, 12)
                        }
                    }
                    .background(Color(uiColor: colourScheme == .light ? .white : .systemGray6).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)))
                    
                    .padding(.top, -10)
                    .padding(.horizontal)
                    
                    VStack {
                        HStack {
                            Image(systemName: "square.text.square.fill")
                                .symbolRenderingMode(.hierarchical)
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundColor(colourScheme == .light ? .black : .white)
                            
                            Text("Comment")
                                .font(.body.weight(.semibold))
                                .foregroundColor(colourScheme == .light ? .black : .white)
                            
                            Spacer()
                            
                        }
                        .padding(.leading, 12)
                        .padding(.trailing)
                        .padding(.top, 12)
                        
                        Divider()
                            .padding(.leading)
                        
                        ZStack {
                            TextEditor(text: $userComment)
                                .focused($commentFocus)
                                .padding(.horizontal)
                                .padding(.bottom, 12)
                                .onChange(of: userComment) { newValue in
                                    solve.comment = newValue
                                }
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        HStack {
                                            Spacer()
                                            
                                            
                                            Button("Comment") {
                                                commentFocus = false
                                            }
                                        }
                                    }
                                }
                            
                            if userComment == "" {
                                Text("Comment something...")
                                    .foregroundColor(Color(uiColor: .systemGray2))
                                    .padding(.vertical, 10)
                                    .offset(y: -4)
                                    .onTapGesture {
                                        commentFocus = true
                                    }
                            }
                            
                            Text(userComment)
                                .opacity(0)
                                .padding([.horizontal, .bottom])
                        }
                    }
                    .background(Color(uiColor: colourScheme == .light ? .white : .systemGray6).clipShape(RoundedRectangle(cornerRadius:10)))
                    .padding(.horizontal)
                    
                    if let phases = self.phases {
                        VStack {
                            HStack {
                                Image(systemName: "square.stack.3d.up.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundColor(colourScheme == .light ? .black : .white)
                                
                                Text("Multiphase Breakdown")
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(colourScheme == .light ? .black : .white)
                                
                                Spacer()
                                
                            }
                            .padding(.leading, 12)
                            .padding(.trailing)
                            .padding(.top, 12)
                            
                            Divider()
                                .padding(.leading)
                            
                            
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(zip(phases.indices, phases)), id: \.0) { index, phase in
                                    
                                    HStack {
                                        if index == 0 {
                                            Image(systemName: "\(index+1).circle")
                                                .font(.body.weight(.medium))
                                            
                                            Text("+"+formatSolveTime(secs: phase))
                                        } else {
                                            if index < phases.count {
                                                let phaseDifference = phases[index] - phases[index-1]
                                                
                                                Image(systemName: "\(index+1).circle")
                                                    .font(.body.weight(.medium))
                                                
                                                Text("+"+formatSolveTime(secs: phaseDifference))
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Text("("+formatSolveTime(secs: phase)+")")
                                            .foregroundColor(Color(uiColor: .systemGray))
                                            .font(.body)
                                    }
                                }
                            }
                            .padding([.bottom, .horizontal], 12)
                        }
                        .background(Color(uiColor: colourScheme == .light ? .white : .systemGray6).clipShape(RoundedRectangle(cornerRadius:10)))
                        .padding(.trailing)
                        .padding(.leading)
                    }
                    
                    
                    Button {
                        var str = "Generated by CubeTime.\n\(time):\t\(scramble)"
                        if let phases = phases {
                            str += "\n\nMultiphase Breakdown:"
                            
                            
                            var prevphasetime = 0.0
                            for (index, phase) in phases.enumerated() {
                                str += "\n\(index + 1): +\(formatSolveTime(secs: phase - prevphasetime)) (\(formatSolveTime(secs: phase)))"
                                prevphasetime = phase
                            }
                        }
                        UIPasteboard.general.string = str
                        withAnimation(Animation.interpolatingSpring(stiffness: 140, damping: 20).delay(0.25)) {
                            self.offsetValue = 0
                        }
                        
                        withAnimation(Animation.easeOut.delay(2.25)) {
                            self.offsetValue = -25
                        }
                    } label: {
                        HStack {
                            Text("Copy Solve")
                                .padding([.leading, .vertical], 14)
                            
                            
                            Image(systemName: "checkmark")
                                .font(Font.system(.subheadline, design: .rounded).weight(.bold))
//                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .clipShape(Rectangle().offset(x: self.offsetValue))
                            
                            Spacer()
                        }
                    }
                    .background(Color(uiColor: colourScheme == .light ? .white : .systemGray6).clipShape(RoundedRectangle(cornerRadius:10)))
                    .padding(.horizontal)
                }
                .offset(y: -6)
                .navigationBarTitle("", displayMode: .inline)
                
            }
        }
        
    }
}
