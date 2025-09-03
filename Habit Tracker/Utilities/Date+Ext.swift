
import Foundation

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
    
    var isoWeekday: Int {
        let appleWd = Calendar.current.component(.weekday, from: self)
        return appleWd == 1 ? 7 : (appleWd - 1)
    }
}

