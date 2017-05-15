/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public typealias Timestamp = UInt64
public typealias MicrosecondTimestamp = UInt64

public let ThreeWeeksInSeconds = 3 * 7 * 24 * 60 * 60

public let OneMonthInMilliseconds = 30 * OneDayInMilliseconds
public let OneWeekInMilliseconds = 7 * OneDayInMilliseconds
public let OneDayInMilliseconds = 24 * OneHourInMilliseconds
public let OneHourInMilliseconds = 60 * OneMinuteInMilliseconds
public let OneMinuteInMilliseconds = 60 * OneSecondInMilliseconds
public let OneSecondInMilliseconds: UInt64 = 1000

extension Date {
    public static func now() -> Timestamp {
        return UInt64(1000 * Date().timeIntervalSince1970)
    }

    public static func nowNumber() -> NSNumber {
        return NSNumber(value: now() as UInt64)
    }

    public static func nowMicroseconds() -> MicrosecondTimestamp {
        return UInt64(1000000 * Date().timeIntervalSince1970)
    }

    public static func fromTimestamp(_ timestamp: Timestamp) -> Date {
        return Date(timeIntervalSince1970: Double(timestamp) / 1000)
    }

    public static func fromMicrosecondTimestamp(_ microsecondTimestamp: MicrosecondTimestamp) -> Date {
        return Date(timeIntervalSince1970: Double(microsecondTimestamp) / 1000000)
    }

    public func toRelativeTimeString() -> String {
        let now = Date()

        let units: NSCalendar.Unit = [NSCalendar.Unit.second, NSCalendar.Unit.minute, NSCalendar.Unit.day, NSCalendar.Unit.weekOfYear, NSCalendar.Unit.month, NSCalendar.Unit.year, NSCalendar.Unit.hour]

        let components = (Calendar.current as NSCalendar).components(units,
            from: self,
            to: now,
            options: [])
        
        if components.year! > 0 {
            return String(format: DateFormatter.localizedString(from: self, dateStyle: DateFormatter.Style.short, timeStyle: DateFormatter.Style.short))
        }

        if components.month == 1 {
            return Strings.More_than_a_month
        }

        if components.month! > 1 {
            return String(format: DateFormatter.localizedString(from: self, dateStyle: DateFormatter.Style.short, timeStyle: DateFormatter.Style.short))
        }

        if components.weekOfYear! > 0 {
            return Strings.More_than_a_week
        }

        if components.day == 1 {
            return Strings.Yesterday
        }

        if components.day! > 1 {
            return String(format: Strings.This_week, String(describing: components.day))
        }

        if components.hour! > 0 || components.minute! > 0 {
            let absoluteTime = DateFormatter.localizedString(from: self, dateStyle: DateFormatter.Style.none, timeStyle: DateFormatter.Style.short)
            return String(format: Strings.Today_at_template, absoluteTime)
        }

        return Strings.Just_now
    }
}

public func decimalSecondsStringToTimestamp(_ input: String) -> Timestamp? {
    var double = 0.0
    if Scanner(string: input).scanDouble(&double) {
        return Timestamp(double * 1000)
    }
    return nil
}

public func millisecondsToDecimalSeconds(_ input: Timestamp) -> String {
    let val: Double = Double(input) / 1000
    return String(format: "%.2F", val)
}
