import SwiftUI

// MARK: - Settings Sheet
struct SettingsSheetView: View {
    @Binding var isPresented: Bool
    @ObservedObject var vm: DashboardViewModel

    @State private var navPath = NavigationPath()

    @AppStorage("userName")          private var storedName         = ""
    @AppStorage("focusWorkMinutes")  private var focusWorkMinutes   = 25
    @AppStorage("focusBreakMinutes") private var focusBreakMinutes  = 5
    @AppStorage("focusSessionGoal")  private var focusSessionGoal   = 4

    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack {
                Color(hex: "#0D0D10").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // ── App identity ──
                        VStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(LinearGradient(
                                        colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color(hex: "#8A4AF3").opacity(0.5), radius: 20, x: 0, y: 8)
                                Text("✓")
                                    .font(.system(size: 38, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Text("Opus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            Text(storedName.isEmpty ? "Welcome" : "Hi, \(storedName.split(separator: " ").first.map(String.init) ?? storedName)")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.45))
                            Text("Version 1.0 (Build 22)")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.25))
                        }
                        .padding(.top, 12)

                        // ── Settings rows ──
                        VStack(spacing: 0) {
                            Button { navPath.append(SettingsDestination.notifications) } label: {
                                rowLabel(icon: "bell.fill", label: "Notifications", color: "#FF6B6B")
                            }
                            Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 18)
                            Button { navPath.append(SettingsDestination.focusPrefs) } label: {
                                rowLabel(icon: "moon.fill", label: "Focus Preferences", color: "#6E6BF5")
                            }
                            Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 18)
                            Button { navPath.append(SettingsDestination.statistics) } label: {
                                rowLabel(icon: "chart.bar.fill", label: "Statistics", color: "#34D399")
                            }
                            Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 18)
                            Button { navPath.append(SettingsDestination.privacy) } label: {
                                rowLabel(icon: "shield.fill", label: "Privacy", color: "#60A5FA")
                            }
                            Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 18)
                            Button { navPath.append(SettingsDestination.about) } label: {
                                rowLabel(icon: "info.circle.fill", label: "About Opus", color: "#A78BFA")
                            }
                        }
                        .buttonStyle(.plain)
                        .background(Color(hex: "#1A1A1E"))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.07), lineWidth: 0.5))
                        .padding(.horizontal, 16)

                        Spacer().frame(height: 40)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { isPresented = false }
                        .foregroundColor(Color(hex: "#8A4AF3"))
                }
            }
            .navigationDestination(for: SettingsDestination.self) { dest in
                switch dest {
                case .notifications: notificationsView
                case .focusPrefs:    focusPrefsView
                case .statistics:    statisticsView
                case .privacy:       privacyView
                case .about:         aboutView
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    // MARK: - Row label

    private func rowLabel(icon: String, label: String, color: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: color).opacity(0.18))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: color))
            }
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.22))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    // MARK: - Notifications

    private var notificationsView: some View {
        ZStack {
            Color(hex: "#0D0D10").ignoresSafeArea()
            VStack(spacing: 24) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#FF6B6B").opacity(0.15))
                            .frame(width: 52, height: 52)
                        Image(systemName: "bell.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "#FF6B6B"))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Push Notifications")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        Text(NotificationManager.shared.isAuthorized ? "Enabled ✓" : "Tap to enable in Settings")
                            .font(.system(size: 13))
                            .foregroundColor(NotificationManager.shared.isAuthorized
                                             ? Color(hex: "#34D399") : Color(hex: "#FF6B6B"))
                    }
                    Spacer()
                }
                .padding(18)
                .background(Color(hex: "#1A1A1E"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.07), lineWidth: 0.5))

                VStack(alignment: .leading, spacing: 14) {
                    Text("WHAT YOU'LL RECEIVE")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white.opacity(0.25))
                        .kerning(1.5)

                    ForEach([
                        ("sun.max.fill", "#F59E0B", "Daily 9 AM reminder", "Your pending task count, every morning"),
                        ("moon.stars.fill", "#A78BFA", "Evening streak guard", "8 PM nudge if you still have tasks left"),
                        ("calendar.badge.clock", "#60A5FA", "Due date alerts", "30 minutes before a task is due"),
                        ("party.popper.fill", "#34D399", "All-done celebration", "When you clear your entire list"),
                    ], id: \.2) { icon, color, title, subtitle in
                        HStack(spacing: 14) {
                            Image(systemName: icon)
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: color))
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                Text(subtitle)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.38))
                            }
                        }
                    }
                }
                .padding(18)
                .background(Color(hex: "#1A1A1E"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.07), lineWidth: 0.5))

                Button {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Open Notification Settings", systemImage: "arrow.up.right.square")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LinearGradient(
                            colors: [Color(hex: "#FF6B6B"), Color(hex: "#FF3B30")],
                            startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Spacer()
            }
            .padding(20)
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Focus Preferences

    private var focusPrefsView: some View {
        ZStack {
            Color(hex: "#0D0D10").ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    stepperCard(icon: "timer", color: "#6E6BF5",
                                title: "Work Session", subtitle: "Minutes of focused work",
                                value: $focusWorkMinutes, range: 5...90, step: 5)
                    stepperCard(icon: "cup.and.saucer.fill", color: "#34D399",
                                title: "Break Length", subtitle: "Minutes to rest between sessions",
                                value: $focusBreakMinutes, range: 1...30, step: 1)
                    stepperCard(icon: "flag.checkered", color: "#F59E0B",
                                title: "Daily Session Goal", subtitle: "Target sessions per day",
                                value: $focusSessionGoal, range: 1...12, step: 1)
                    Text("Changes take effect next time you start Focus Mode.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.28))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    Spacer().frame(height: 40)
                }
                .padding(20)
            }
        }
        .navigationTitle("Focus Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stepperCard(icon: String, color: String, title: String, subtitle: String,
                              value: Binding<Int>, range: ClosedRange<Int>, step: Int) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: color).opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: color))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                Text(subtitle).font(.system(size: 12)).foregroundColor(.white.opacity(0.38))
            }
            Spacer()
            HStack(spacing: 12) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if value.wrappedValue - step >= range.lowerBound { value.wrappedValue -= step }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                Text("\(value.wrappedValue)")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .frame(minWidth: 36)
                    .monospacedDigit()
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if value.wrappedValue + step <= range.upperBound { value.wrappedValue += step }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
            }
        }
        .padding(16)
        .background(Color(hex: "#1A1A1E"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.07), lineWidth: 0.5))
    }

    // MARK: - Statistics

    private var statisticsView: some View {
        ZStack {
            Color(hex: "#0D0D10").ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    let totalCompleted = vm.completedTasks.count + vm.completedHistory.reduce(0) { $0 + $1.tasks.count }
                    let avgPerDay = vm.completedHistory.isEmpty ? 0 : vm.completedHistory.reduce(0) { $0 + $1.tasks.count } / max(vm.completedHistory.count, 1)
                    let bestDay = vm.completedHistory.max(by: { $0.tasks.count < $1.tasks.count })

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        statBlock(emoji: "✅", value: "\(totalCompleted)", label: "Total Completed")
                        statBlock(emoji: "🔥", value: "\(vm.streak)", label: "Current Streak")
                        statBlock(emoji: "⚡️", value: "\(vm.momentum)%", label: "Momentum")
                        statBlock(emoji: "📅", value: "\(vm.completedHistory.count)", label: "Days Logged")
                        statBlock(emoji: "📊", value: "\(avgPerDay)", label: "Avg / Day")
                        statBlock(emoji: "🏆", value: "\(bestDay?.tasks.count ?? 0)", label: "Best Day")
                    }

                    if !vm.completedHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("RECENT DAYS")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.white.opacity(0.25))
                                .kerning(1.5)
                            ForEach(vm.completedHistory.prefix(5)) { entry in
                                HStack {
                                    Text(entry.date)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                    Spacer()
                                    Text("\(entry.tasks.count) task\(entry.tasks.count == 1 ? "" : "s")")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color(hex: "#34D399"))
                                }
                                .padding(.vertical, 6)
                                if entry.id != vm.completedHistory.prefix(5).last?.id {
                                    Divider().background(Color.white.opacity(0.06))
                                }
                            }
                        }
                        .padding(18)
                        .background(Color(hex: "#1A1A1E"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.07), lineWidth: 0.5))
                    }

                    Spacer().frame(height: 40)
                }
                .padding(20)
            }
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func statBlock(emoji: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Text(emoji).font(.system(size: 26))
            Text(value)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(hex: "#1A1A1E"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.07), lineWidth: 0.5))
    }

    // MARK: - Privacy

    private var privacyView: some View {
        ZStack {
            Color(hex: "#0D0D10").ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#60A5FA").opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: "shield.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Color(hex: "#60A5FA"))
                    }
                    Text("Your data stays on your device.")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    VStack(spacing: 12) {
                        ForEach([
                            ("lock.fill", "#60A5FA", "100% On-Device", "Tasks, streaks, and stats are stored locally in UserDefaults. Nothing leaves your phone."),
                            ("wifi.slash", "#34D399", "No Accounts Required", "Opus works without signing in. No email, no password, no cloud sync."),
                            ("eye.slash.fill", "#A78BFA", "No Analytics", "We don't track what you do inside the app. No usage data is collected."),
                            ("bell.slash.fill", "#F59E0B", "Notifications are Local", "All reminders are scheduled on-device via UserNotifications. No servers involved."),
                        ], id: \.2) { icon, color, title, body in
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: color))
                                    .frame(width: 24, height: 24)
                                    .padding(.top, 2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(title)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text(body)
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.45))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Color(hex: "#1A1A1E"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.07), lineWidth: 0.5))
                        }
                    }
                    Spacer().frame(height: 40)
                }
                .padding(20)
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - About

    private var aboutView: some View {
        ZStack {
            Color(hex: "#0D0D10").ignoresSafeArea()
            VStack(spacing: 28) {
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 26)
                            .fill(LinearGradient(
                                colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 100, height: 100)
                            .shadow(color: Color(hex: "#8A4AF3").opacity(0.55), radius: 28, x: 0, y: 10)
                        Text("✓")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("Opus")
                        .font(.system(size: 30, weight: .black))
                        .foregroundColor(.white)
                    Text("Version 1.0 · Build 22")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.32))
                }
                .padding(.top, 20)

                VStack(spacing: 0) {
                    aboutRow(label: "Developer", value: "Hector Ruiz")
                    Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 18)
                    aboutRow(label: "Platform", value: "iOS 17+")
                    Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 18)
                    aboutRow(label: "Built with", value: "SwiftUI · WidgetKit")
                    Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 18)
                    aboutRow(label: "Beta", value: "TestFlight")
                }
                .background(Color(hex: "#1A1A1E"))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.07), lineWidth: 0.5))
                .padding(.horizontal, 20)

                Text("Made with focus, for people who build.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.28))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
            }
        }
        .navigationTitle("About Opus")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func aboutRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.55))
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}
