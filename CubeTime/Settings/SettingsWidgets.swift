import SwiftUI

struct SettingsGroup<Content>: View where Content: View {
    @Environment(\.colorScheme) var colourScheme
    @AppStorage(asKeys.accentColour.rawValue) private var accentColour: Color = .indigo
    
    var name: String
    var iconname: String
    
    let content: () -> Content
    
    @inlinable init(name: String, iconname: String, @ViewBuilder content: @escaping () -> Content) {
        self.name = name
        self.iconname = iconname
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: iconname)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(accentColour)
                Text(name)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                
                Spacer()
            }
            .padding([.horizontal, .top], 10)
            
            content()
                .padding(.horizontal)
        }
        .padding(.bottom, 10)
        .background(Color(uiColor: colourScheme == .light ? .white : .systemGray6).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)).shadow(color: Color.black.opacity(colourScheme == .light ? 0.06 : 0), radius: 6, x: 0, y: 3))
    }
}

struct SettingsToggle: View {
    @AppStorage(asKeys.accentColour.rawValue) private var accentColour: Color = .indigo
    @Binding var isOn: Bool
    var text: String
    
    var body: some View {
        Toggle(isOn: _isOn) {
            Text(text)
                .font(.system(size: 17, weight: .medium))
        }
        .toggleStyle(SwitchToggleStyle(tint: accentColour))
    }
}

struct SettingsPicker<SelectionValue, Content>: View where SelectionValue: Hashable, Content: View {
    @AppStorage(asKeys.accentColour.rawValue) private var accentColour: Color = .indigo
    
    let content: () -> Content
    let text: String
    
    @Binding var selection: SelectionValue
    
    
    @inlinable init(selection: Binding<SelectionValue>, text: String, @ViewBuilder content: @escaping () -> Content) {
        self._selection = selection
        self.text = text
        self.content = content
    }
    
    var body: some View {
        HStack {
            Text(text)
                .font(.system(size: 17, weight: .medium))
            Spacer()
            Picker("", selection: _selection) {
                content()
            }
            .pickerStyle(.menu)
            .accentColor(accentColour)
            .font(.system(size: 17, weight: .regular))
        }
    }
}

struct SettingsAction: View {
    let text: String
    let buttontext: String
    let role: ButtonRole?
    let action: () -> Void
    var body: some View {
        HStack {
            Text(text)
                .font(.system(size: 17, weight: .medium))
            Spacer()
            Button(buttontext, role: role, action: action)
                .buttonStyle(.bordered)
        }
    }
}
