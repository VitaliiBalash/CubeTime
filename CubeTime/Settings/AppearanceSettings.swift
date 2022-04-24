import SwiftUI


struct settingsBlocks: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)).shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3))
    }
}

enum asKeys: String {
    case accentColour, overrideDM, dmBool, staticGradient, gradientSelected, graphGlow
}


struct AppearanceSettingsView: View {
    @Environment(\.colorScheme) var colourScheme
    
    @State var showThemeOptions: Bool = false
    
    let accentColours: [Color] = [.cyan, .blue, .indigo, .purple, .red]
    
    private let columns = [GridItem(spacing: 16), GridItem(spacing: 16)]
    
    // colours
    @AppStorage(asKeys.accentColour.rawValue) private var accentColour: Color = .indigo
    @AppStorage(asKeys.staticGradient.rawValue) private var staticGradient: Bool = true
    @AppStorage(asKeys.gradientSelected.rawValue) private var gradientSelected: Int = 6
    @AppStorage(asKeys.graphGlow.rawValue) private var graphGlow: Bool = true
    
    // system settings (appearance)
    @AppStorage(asKeys.overrideDM.rawValue) private var overrideSystemAppearance: Bool = false
    @AppStorage(asKeys.dmBool.rawValue) private var darkMode: Bool = false
    
    
    var body: some View {
        VStack(spacing: 16) {
            SettingsGroup(name: "Colours", iconname: "paintbrush.pointed.fill") {
                HStack {
                    Text("Accent Colour")
                        .font(.system(size: 17, weight: .medium))
                    
                    Spacer()
                    
                }
                .padding(.top, 10)

                
                HStack(spacing: 6) {
                    ForEach(accentColours, id: \.self) { colour in
                        
                        // See extension in Helper.swift
                        let isSameColor = UIColor(colour).colorsEqual(UIColor(accentColour))
                        
                        ZStack {
                            Circle()
                                .strokeBorder(colour.opacity(0.25), lineWidth: isSameColor ? 2 : 0)
                                .frame(width: 31, height: 31)
                             
                            
                            Image(systemName: "circle.fill")
                                .foregroundColor(colour)
                                .font(.system(size: 24))
                                .shadow(color: isSameColor ? .black.opacity(0.16) : .clear, radius: 6, x: 0, y: 2)
                                .drawingGroup()
                                .onTapGesture {
                                    accentColour = colour
                                }
                            
                            if isSameColor {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    ColorPicker("", selection: $accentColour, supportsOpacity: false)
                    
                }
                .padding(.bottom, 4)
                .padding(.top, 8)
                
                Divider()
                
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center) {
                        Text("Theme")
                            .font(.system(size: 17, weight: .medium))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(uiColor: .systemGray3))
                            .rotationEffect(.degrees(showThemeOptions ? 90 : 0))
                    }
                    
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring()) {
                            showThemeOptions.toggle()
                        }
                    }
                    
                    
                    if !showThemeOptions {
                        Text("Customise the app theme and gradients.\nNote: this is separate from the accent colour.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(uiColor: .systemGray))
                            .multilineTextAlignment(.leading)
                            .padding(.bottom, 12)
                            .padding(.top, 10)
                            .offset(x: 1, y: 1)
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            /* add this switch back when dynamic gradient added
                            HStack {
                                Toggle(isOn: $staticGradient) {
                                    Text("Use Static Gradient")
                                        .font(.system(size: 17, weight: .medium))
                                }
                                    .toggleStyle(SwitchToggleStyle(tint: accentColour))
                                
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                             */
                            
                            Text("By default, the gradient is static. Dynamic gradient coming soon!")
//                                Text("By default, the gradient is dynamic and changes throughout the day. If turned off, the gradient will only be of static colours.")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(uiColor: .systemGray))
                                .multilineTextAlignment(.leading)
                                .padding(.bottom, 12)
                            
                            if staticGradient {
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(CustomGradientColours.gradientColours, id: \.self) { gradient in
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
//                                                Rectangle()
                                                .fill(LinearGradient(gradient: Gradient(colors: gradient), startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .frame(height: 50)
                                                .onTapGesture {
                                                    gradientSelected = CustomGradientColours.gradientColours.firstIndex(of: gradient)!
                                                }
                                            if CustomGradientColours.gradientColours[gradientSelected] == gradient {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 15, weight: .black))
                                                    .foregroundColor(.white)
                                            }
                                            
                                                
                                        }
                                    }
                                }
                                .padding(.bottom)

                            }
                        }
                        .padding(.top, 10)
                    }
                }
                
                Divider()
                
                
                SettingsToggle(isOn: $graphGlow, text: "Graph Glow")
               
                Text("Turn on/off the glow effect on graphs.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(uiColor: .systemGray))
                    .multilineTextAlignment(.leading)
            }
            
            SettingsGroup(name: "System Settings", iconname: "command") {
                SettingsToggle(isOn: $overrideSystemAppearance.animation(.spring()), text: "Override System Appearance")
                
                if overrideSystemAppearance {
                    SettingsToggle(isOn: $darkMode, text: "Dark Mode")
                }
            }
        }
        .padding(.horizontal)
    }
}
