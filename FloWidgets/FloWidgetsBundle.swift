import WidgetKit
import SwiftUI

@main
struct FloWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TodaySummaryWidget()
        FocusTimerWidget()
        HabitTrackerWidget()
        NextTaskWidget()
        StreakWidget()
        ProductivityScoreWidget()
        TaskCountLockScreenWidget()
        StreakLockScreenWidget()
        FocusMinutesLockScreenWidget()
        NextTaskInlineWidget()
    }
}
