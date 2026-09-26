import SwiftUI

extension Binding where Value == Set<String> {
    func contains(_ key: String) -> Binding<Bool> {
        Binding<Bool>(get: { wrappedValue.contains(key) },
                      set: { isOn in
                          if isOn { wrappedValue.insert(key) } else { wrappedValue.remove(key) }
                      })
    }
}
