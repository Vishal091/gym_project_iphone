import SwiftUI

private enum GymStyle {
    static let ink = Color(red: 0.09, green: 0.13, blue: 0.11)
    static let forest = Color(red: 0.09, green: 0.30, blue: 0.23)
    static let mint = Color(red: 0.72, green: 0.95, blue: 0.81)
    static let canvas = Color(red: 0.96, green: 0.97, blue: 0.95)
    static let muted = Color(red: 0.44, green: 0.50, blue: 0.47)
    static let border = Color(red: 0.88, green: 0.91, blue: 0.88)
    static let orange = Color(red: 0.68, green: 0.34, blue: 0.20)
}

private struct MembershipPlan: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var durationMonths: Int
    var fee: Int
}
private struct Member: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var phone: String
    var planId: String
    var planName: String
    var fee: Int
    var startDate: String
    var expiryDate: String
    var dueDate: String
}
private struct PaymentRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var memberId: UUID
    var amount: Int
    var paidOn: String
    var method: String
}
private struct AttendanceRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var memberId: UUID
    var day: String
    var checkedInAt: String
}
private struct GymState: Codable, Equatable {
    var members: [Member]
    var plans: [MembershipPlan]
    var payments: [PaymentRecord]
    var attendance: [AttendanceRecord]
}

private enum DateSupport {
    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    static func dayString(_ date: Date = Date()) -> String { dayFormatter.string(from: date) }
    static func date(_ value: String) -> Date? { dayFormatter.date(from: value) }
    static func plusMonths(_ months: Int, from value: String) -> String {
        guard let d = date(value),
              let next = Calendar.current.date(byAdding: .month, value: months, to: d),
              let lastDay = Calendar.current.date(byAdding: .day, value: -1, to: next) else { return value }
        return dayString(lastDay)
    }
    static func dueLabel(_ value: String) -> String {
        guard let due = date(value), let today = date(dayString()) else { return "Date needed" }
        let days = Calendar.current.dateComponents([.day], from: today, to: due).day ?? 0
        if days < 0 { return "Overdue" }
        if days == 0 { return "Today" }
        if days == 1 { return "Tomorrow" }
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "dd MMM"
        return f.string(from: due)
    }
    static func active(_ member: Member, today: String = dayString()) -> Bool {
        guard let start = date(member.startDate), let end = date(member.expiryDate), let current = date(today) else { return false }
        return start <= current && end >= current
    }
    static func expired(_ member: Member, today: String = dayString()) -> Bool {
        guard let end = date(member.expiryDate), let current = date(today) else { return false }
        return end < current
    }
    static func status(_ member: Member, today: String = dayString()) -> String {
        guard let start = date(member.startDate) else { return "Date needed" }
        guard let current = date(today) else { return "Date needed" }
        if current < start { return "Not started" }
        if expired(member, today: today) { return "Expired" }
        return "Active"
    }
}

private enum GymStore {
    private static let key = "gympilot.state.v2"
    static func load() -> GymState {
        if let data = UserDefaults.standard.data(forKey: key),
           let state = try? JSONDecoder().decode(GymState.self, from: data) {
            return state
        }
        let seeded = sampleState()
        save(seeded)
        return seeded
    }
    static func save(_ state: GymState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    private static func sampleState() -> GymState {
        let today = DateSupport.dayString()
        let calendar = Calendar.current
        func relative(_ days: Int) -> String {
            guard let date = DateSupport.date(today), let shifted = calendar.date(byAdding: .day, value: days, to: date) else { return today }
            return DateSupport.dayString(shifted)
        }
        let plans = [
            MembershipPlan(id: "monthly", name: "Monthly", durationMonths: 1, fee: 1200),
            MembershipPlan(id: "quarterly", name: "Quarterly", durationMonths: 3, fee: 3000),
            MembershipPlan(id: "half-yearly", name: "Half-yearly", durationMonths: 6, fee: 6000),
            MembershipPlan(id: "annual", name: "Annual", durationMonths: 12, fee: 10000)
        ]
        let ids = (1...6).map { UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", $0))! }
        let members = [
            Member(id: ids[0], name: "Aman Sharma", phone: "98765 43210", planId: "monthly", planName: "Monthly", fee: 1200, startDate: relative(-20), expiryDate: relative(10), dueDate: today),
            Member(id: ids[1], name: "Priya Verma", phone: "98901 23456", planId: "quarterly", planName: "Quarterly", fee: 3000, startDate: relative(-30), expiryDate: relative(60), dueDate: relative(6)),
            Member(id: ids[2], name: "Rahul Kumar", phone: "98111 22334", planId: "monthly", planName: "Monthly", fee: 1200, startDate: relative(-12), expiryDate: relative(17), dueDate: relative(1)),
            Member(id: ids[3], name: "Neha Singh", phone: "98770 11223", planId: "monthly", planName: "Monthly", fee: 1200, startDate: relative(-10), expiryDate: relative(20), dueDate: relative(8)),
            Member(id: ids[4], name: "Arjun Malik", phone: "99911 22334", planId: "half-yearly", planName: "Half-yearly", fee: 6000, startDate: relative(-60), expiryDate: relative(120), dueDate: relative(12)),
            Member(id: ids[5], name: "Simran Kaur", phone: "98140 22110", planId: "monthly", planName: "Monthly", fee: 1200, startDate: relative(-60), expiryDate: relative(-2), dueDate: relative(-7))
        ]
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "yyyy-MM"
        let currentMonth = String(today.prefix(7))
        let paymentDay1 = relative(-4)
        let paymentDay2 = relative(-8)
        let payments = [
            PaymentRecord(id: UUID(), memberId: ids[1], amount: 3000, paidOn: paymentDay1, method: "UPI"),
            PaymentRecord(id: UUID(), memberId: ids[3], amount: 1200, paidOn: paymentDay2, method: "Cash")
        ]
        let attendance = [AttendanceRecord(id: UUID(), memberId: ids[0], day: today, checkedInAt: ISO8601DateFormatter().string(from: Date()))]
        _ = currentMonth
        return GymState(members: members, plans: plans, payments: payments, attendance: attendance)
    }
}

private enum AppScreen: String, CaseIterable {
    case home, members, attendance, dues, profile, plans, alerts
    var title: String {
        switch self {
        case .home: "Home"; case .members: "Members"; case .attendance: "Check-in"; case .dues: "Dues"
        case .profile: "Member profile"; case .plans: "Plan settings"; case .alerts: "Reminders"
        }
    }
    var icon: String {
        switch self {
        case .home: "square.grid.2x2.fill"; case .members: "person.2.fill"; case .attendance: "checkmark.circle.fill"
        case .dues: "indianrupeesign.circle.fill"; case .profile: "person.crop.circle"; case .plans: "gearshape"; case .alerts: "bell"
        }
    }
}

struct ContentView: View {
    @State private var data = GymStore.load()
    @State private var screen: AppScreen = .home
    @State private var selectedMemberID: UUID?
    @State private var searchText = ""
    @State private var showingAddMember = false
    @State private var showingEditDates = false
    @State private var showingPaymentMethod = false
    @State private var pendingPaymentID: UUID?

    private var selectedMember: Member? { data.members.first { $0.id == selectedMemberID } }
    private var activePages: [AppScreen] { [.home, .members, .attendance, .dues] }
    private var today: String { DateSupport.dayString() }

    var body: some View {
        VStack(spacing: 0) {
            header
            Group {
                switch screen {
                case .home: dashboard
                case .members: membersPage
                case .attendance: attendancePage
                case .dues: duesPage
                case .profile:
                    if let member = selectedMember {
                        MemberProfilePage(data: data, member: member, checkedIn: isCheckedIn(member.id),
                                          onRecordPayment: { requestPayment(for: member.id) },
                                          onToggleCheckIn: { toggleCheckIn(member.id) },
                                          onEditDates: { showingEditDates = true })
                    } else { EmptyState(title: "Member not found", message: "Return to the directory and select a member.") }
                case .plans:
                    PlanSettingsPage(plans: data.plans, onSave: { newPlans in data.plans = newPlans; screen = .home })
                case .alerts: alertsPage
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if activePages.contains(screen) { bottomBar }
        }
        .background(GymStyle.canvas.ignoresSafeArea())
        .preferredColorScheme(.light)
        .onChange(of: data) { _, updated in GymStore.save(updated) }
        .sheet(isPresented: $showingAddMember) {
            AddMemberSheet(plans: data.plans, existingPhones: data.members.map(\.phone)) { name, phone, plan, start, expiry in
                let newMember = Member(id: UUID(), name: name, phone: phone, planId: plan.id, planName: plan.name,
                                       fee: plan.fee, startDate: start, expiryDate: expiry, dueDate: start)
                data.members.insert(newMember, at: 0)
                selectedMemberID = newMember.id
                screen = .profile
                showingAddMember = false
            }
        }
        .sheet(isPresented: $showingEditDates) {
            if let member = selectedMember {
                EditDatesSheet(member: member) { start, expiry, due in
                    guard let index = data.members.firstIndex(where: { $0.id == member.id }) else { return }
                    data.members[index].startDate = start
                    data.members[index].expiryDate = expiry
                    data.members[index].dueDate = due
                    showingEditDates = false
                }
            }
        }

        .confirmationDialog("Choose a payment method", isPresented: $showingPaymentMethod, titleVisibility: .visible) {
            Button("Cash") { finishPayment("Cash") }
            Button("UPI") { finishPayment("UPI") }
            Button("Bank transfer") { finishPayment("Bank transfer") }
            Button("Card") { finishPayment("Card") }
            Button("Other") { finishPayment("Other") }
            Button("Cancel", role: .cancel) { pendingPaymentID = nil }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            if [.profile, .plans, .alerts].contains(screen) {
                Button { screen = screen == .profile ? .members : .home } label: {
                    Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold)).foregroundStyle(GymStyle.ink).frame(width: 40, height: 40)
                }
            } else {
                Image(systemName: "figure.strengthtraining.traditional").font(.system(size: 21, weight: .bold))
                    .foregroundStyle(GymStyle.mint).frame(width: 43, height: 43).background(GymStyle.forest, in: RoundedRectangle(cornerRadius: 14))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("GYMPILOT").font(.system(size: 10, weight: .heavy)).tracking(2).foregroundStyle(GymStyle.muted)
                Text(screen == .home ? "Your gym, in control." : screen.title).font(.system(size: 15, weight: .bold)).foregroundStyle(GymStyle.ink)
            }
            Spacer()
            if screen == .members {
                Button { showingAddMember = true } label: {
                    Image(systemName: "person.badge.plus").font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                        .frame(width: 40, height: 40).background(GymStyle.forest, in: RoundedRectangle(cornerRadius: 12))
                }.accessibilityLabel("Add member")
            } else if screen == .home {
                Button { screen = .alerts } label: { Image(systemName: "bell").foregroundStyle(GymStyle.ink).frame(width: 40, height: 40).background(GymStyle.canvas, in: Circle()) }
                    .accessibilityLabel("Renewal reminders")
            } else if screen != .plans {
                Button { screen = .plans } label: { Image(systemName: "gearshape").foregroundStyle(GymStyle.ink).frame(width: 40, height: 40).background(GymStyle.canvas, in: Circle()) }
                    .accessibilityLabel("Plan settings")
            }
        }
        .padding(.horizontal, 19).padding(.vertical, 11).background(.white)
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            ForEach(activePages, id: \.self) { item in
                Button { withAnimation(.easeInOut(duration: 0.15)) { screen = item } } label: {
                    VStack(spacing: 5) {
                        Image(systemName: item.icon).font(.system(size: 18, weight: .semibold))
                        Text(item.title).font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(screen == item ? GymStyle.forest : GymStyle.muted)
                    .frame(maxWidth: .infinity).padding(.top, 10).padding(.bottom, 7).contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
        }.background(.white).overlay(alignment: .top) { Rectangle().fill(GymStyle.border).frame(height: 1) }
    }

    private var dashboard: some View {
        let active = data.members.filter { DateSupport.active($0) }.count
        let dueSoon = data.members.filter { isDueWithin($0.dueDate, days: 7) }.count
        let monthCollection = data.payments.filter { $0.paidOn.hasPrefix(String(today.prefix(7))) }.reduce(0) { $0 + $1.amount }
        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)).uppercased())
                        .font(.system(size: 10, weight: .heavy)).tracking(1.2).foregroundStyle(GymStyle.muted)
                    Text(greeting).font(.system(size: 27, weight: .bold, design: .rounded)).foregroundStyle(GymStyle.ink)
                    Text("Here’s what’s happening at your gym.").font(.system(size: 13)).foregroundStyle(GymStyle.muted)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("COLLECTED THIS MONTH").font(.system(size: 10, weight: .heavy)).tracking(1.1).foregroundStyle(GymStyle.mint)
                    Text(rupees(monthCollection)).font(.system(size: 29, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    Text("Demo transactions are included in this preview.").font(.system(size: 11)).foregroundStyle(.white.opacity(0.8))
                    Rectangle().fill(.white.opacity(0.18)).frame(height: 1).padding(.vertical, 4)
                    Text("Saved on this device. Shared sync requires a backend.").font(.system(size: 11)).foregroundStyle(.white.opacity(0.85))
                }.padding(18).frame(maxWidth: .infinity, alignment: .leading).background(GymStyle.forest, in: RoundedRectangle(cornerRadius: 22))
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        MetricCard(title: "Active members", value: String(active), subtitle: "Within membership dates", icon: "person.2.fill")
                        MetricCard(title: "Today's check-ins", value: String(data.attendance.filter { $0.day == today }.count), subtitle: "Recorded today", icon: "checkmark.seal.fill")
                    }
                    HStack(spacing: 10) {
                        MetricCard(title: "Fee alerts", value: String(dueSoon), subtitle: "Due within 7 days", icon: "bell.badge.fill", warning: true)
                        MetricCard(title: "Expired", value: String(data.members.filter { DateSupport.expired($0) }.count), subtitle: "Outside active dates", icon: "calendar.badge.exclamationmark", warning: true)
                    }
                }
                HStack {
                    Text("Quick actions").font(.system(size: 17, weight: .bold)).foregroundStyle(GymStyle.ink)
                    Spacer()
                    Button("Plans") { screen = .plans }.font(.system(size: 12, weight: .bold)).foregroundStyle(GymStyle.forest)
                }
                HStack(spacing: 9) {
                    QuickAction(title: "Add member", icon: "person.badge.plus") { showingAddMember = true }
                    QuickAction(title: "Attendance", icon: "checkmark.circle") { screen = .attendance }
                    QuickAction(title: "Fee dues", icon: "indianrupeesign.circle") { screen = .dues }
                }
                HStack {
                    Text("Needs attention").font(.system(size: 17, weight: .bold)).foregroundStyle(GymStyle.ink)
                    Spacer()
                    Button("View all") { screen = .dues }.font(.system(size: 12, weight: .bold)).foregroundStyle(GymStyle.forest)
                }
                let dueMembers = data.members.filter { isDueWithin($0.dueDate, days: 7) }.sorted { $0.dueDate < $1.dueDate }.prefix(3)
                if dueMembers.isEmpty { Text("No upcoming fee reminders.").font(.system(size: 12)).foregroundStyle(GymStyle.muted) }
                ForEach(Array(dueMembers)) { member in MemberRow(member: member) { openProfile(member.id) } }
            }.padding(19)
        }
    }

    private var membersPage: some View {
        let checkedIDs = Set(data.attendance.filter { $0.day == today }.map(\.memberId))
        let filtered = data.members.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) || $0.phone.localizedCaseInsensitiveContains(searchText) }
        return VStack(alignment: .leading, spacing: 11) {
            heading("Members", subtitle: String(data.members.filter { DateSupport.active($0) }.count) + " active · " + String(data.members.count) + " total")
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass").foregroundStyle(GymStyle.muted)
                TextField("Search name or phone…", text: $searchText).font(.system(size: 14)).autocorrectionDisabled()
                if !searchText.isEmpty { Button { searchText = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(GymStyle.muted) }.accessibilityLabel("Clear search") }
            }.padding(13).background(.white, in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(GymStyle.border, lineWidth: 1))
            if filtered.isEmpty { EmptyState(title: "No members found", message: "Try another name or phone number.") }
            else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 9) {
                        ForEach(filtered) { member in
                            MemberCard(member: member, checkedIn: checkedIDs.contains(member.id), onProfile: { openProfile(member.id) }, onToggle: { toggleCheckIn(member.id) })
                        }
                    }.padding(.bottom, 15)
                }
            }
        }.padding(.horizontal, 19).padding(.top, 17)
    }

    private var attendancePage: some View {
        let checkedIDs = Set(data.attendance.filter { $0.day == today }.map(\.memberId))
        let activeMembers = data.members.filter { DateSupport.active($0) }
        return VStack(alignment: .leading, spacing: 12) {
            heading("Attendance", subtitle: "Check-ins include dates and timestamps.")
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("TODAY'S CHECK-INS").font(.system(size: 10, weight: .heavy)).tracking(1).foregroundStyle(GymStyle.mint)
                    Text(String(checkedIDs.intersection(Set(activeMembers.map(\.id))).count) + " / " + String(activeMembers.count))
                        .font(.system(size: 27, weight: .bold, design: .rounded)).foregroundStyle(.white)
                }
                Spacer(); Image(systemName: "checkmark.seal.fill").font(.system(size: 31)).foregroundStyle(GymStyle.mint)
            }.padding(17).background(GymStyle.forest, in: RoundedRectangle(cornerRadius: 18))
            if activeMembers.isEmpty { EmptyState(title: "No active members", message: "Add or renew a membership to record attendance.") }
            else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 9) {
                        ForEach(activeMembers) { m in MemberCard(member: m, checkedIn: checkedIDs.contains(m.id), onProfile: { openProfile(m.id) }, onToggle: { toggleCheckIn(m.id) }) }
                    }.padding(.bottom, 15)
                }
            }
        }.padding(.horizontal, 19).padding(.top, 17)
    }

    private var duesPage: some View {
        let dueMembers = data.members.filter { isDueWithin($0.dueDate, days: 30) }.sorted { $0.dueDate < $1.dueDate }
        let overdueCount = dueMembers.filter { DateSupport.dueLabel($0.dueDate) == "Overdue" }.count
        return VStack(alignment: .leading, spacing: 12) {
            heading("Fee tracker", subtitle: "Outstanding and upcoming fees over 30 days.")
            HStack(spacing: 10) {
                SummaryCard(title: "DUE SOON", value: String(dueMembers.count))
                SummaryCard(title: "OVERDUE", value: String(overdueCount))
            }
            if dueMembers.isEmpty { EmptyState(title: "You're all caught up", message: "No fees due in the next 30 days.") }
            else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 9) {
                        ForEach(dueMembers) { member in
                            DueMemberCard(member: member, onProfile: { openProfile(member.id) }, onPay: { requestPayment(for: member.id) })
                        }
                    }.padding(.bottom, 15)
                }
            }
        }.padding(.horizontal, 19).padding(.top, 17)
    }

    private var alertsPage: some View {
        let alerts = data.members.filter { isDueWithin($0.dueDate, days: 30) }.sorted { $0.dueDate < $1.dueDate }
        return VStack(alignment: .leading, spacing: 12) {
            heading("Renewal reminders", subtitle: "Fees due or overdue in the next 30 days.")
            if alerts.isEmpty { EmptyState(title: "No reminders", message: "No fees are due in the next 30 days.") }
            else {
                ScrollView { LazyVStack(spacing: 9) { ForEach(alerts) { member in MemberRow(member: member) { openProfile(member.id) } } }.padding(.bottom, 10) }
            }
            Button("Open fee tracker") { screen = .dues }.buttonStyle(.borderedProminent).tint(GymStyle.forest).frame(maxWidth: .infinity)
        }.padding(.horizontal, 19).padding(.top, 17)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning 👋" }
        if hour < 17 { return "Good afternoon 👋" }
        return "Good evening 👋"
    }

    private func heading(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 27, weight: .bold, design: .rounded)).foregroundStyle(GymStyle.ink)
            Text(subtitle).font(.system(size: 13)).foregroundStyle(GymStyle.muted)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private func openProfile(_ id: UUID) { selectedMemberID = id; screen = .profile }
    private func isCheckedIn(_ id: UUID) -> Bool { data.attendance.contains { $0.memberId == id && $0.day == today } }
    private func toggleCheckIn(_ id: UUID) {
        if let current = data.attendance.first(where: { $0.memberId == id && $0.day == today }) {
            data.attendance.removeAll { $0.id == current.id }
        } else {
            data.attendance.append(AttendanceRecord(id: UUID(), memberId: id, day: today, checkedInAt: ISO8601DateFormatter().string(from: Date())))
        }
    }
    private func requestPayment(for id: UUID) { pendingPaymentID = id; showingPaymentMethod = true }
    private func finishPayment(_ method: String) {
        guard let id = pendingPaymentID else { return }
        recordPayment(for: id, method: method)
        pendingPaymentID = nil
    }
    private func recordPayment(for id: UUID, method: String) {
        guard let index = data.members.firstIndex(where: { $0.id == id }) else { return }
        let member = data.members[index]
        let duration = data.plans.first(where: { $0.id == member.planId })?.durationMonths ?? 1
        let base = max(member.dueDate, today)
        let nextDue = monthAfter(due: base, months: duration)
        data.payments.append(PaymentRecord(id: UUID(), memberId: id, amount: member.fee, paidOn: today, method: method))
        data.members[index].dueDate = nextDue
        data.members[index].expiryDate = dayBefore(nextDue)
    }
    private func isDueWithin(_ value: String, days: Int) -> Bool {
        guard let due = DateSupport.date(value), let current = DateSupport.date(today),
              let end = Calendar.current.date(byAdding: .day, value: days, to: current) else { return false }
        return due <= end
    }
    private func monthAfter(due: String, months: Int) -> String {
        guard let d = DateSupport.date(due), let next = Calendar.current.date(byAdding: .month, value: months, to: d) else { return due }
        return DateSupport.dayString(next)
    }
    private func dayBefore(_ value: String) -> String {
        guard let d = DateSupport.date(value), let prev = Calendar.current.date(byAdding: .day, value: -1, to: d) else { return value }
        return DateSupport.dayString(prev)
    }
}

private struct MetricCard: View {
    let title: String; let value: String; let subtitle: String; let icon: String; var warning = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(warning ? GymStyle.orange : GymStyle.forest)
                .frame(width: 34, height: 34).background(warning ? Color.orange.opacity(0.13) : GymStyle.mint.opacity(0.45), in: RoundedRectangle(cornerRadius: 11))
            Text(value).font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(GymStyle.ink)
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(GymStyle.ink)
            Text(subtitle).font(.system(size: 10)).foregroundStyle(GymStyle.muted).lineLimit(2)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(13).background(.white, in: RoundedRectangle(cornerRadius: 18))
    }
}
private struct QuickAction: View {
    let title: String; let icon: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(GymStyle.forest)
                    .frame(width: 39, height: 39).background(GymStyle.mint.opacity(0.5), in: Circle())
                Text(title).font(.system(size: 10, weight: .semibold)).foregroundStyle(GymStyle.ink).lineLimit(1).minimumScaleFactor(0.8)
            }.frame(maxWidth: .infinity).padding(.vertical, 12).background(.white, in: RoundedRectangle(cornerRadius: 15))
        }.buttonStyle(.plain)
    }
}
private struct MemberRow: View {
    let member: Member; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                AvatarView(name: member.name)
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.name).font(.system(size: 13, weight: .bold)).foregroundStyle(GymStyle.ink)
                    Text("Due " + DateSupport.dueLabel(member.dueDate) + " · " + rupees(member.fee)).font(.system(size: 11)).foregroundStyle(GymStyle.muted)
                }
                Spacer(); DueBadge(due: DateSupport.dueLabel(member.dueDate))
            }.padding(12).background(.white, in: RoundedRectangle(cornerRadius: 15))
        }.buttonStyle(.plain)
    }
}
private struct MemberCard: View {
    let member: Member; let checkedIn: Bool; let onProfile: () -> Void; let onToggle: () -> Void
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 9) {
                AvatarView(name: member.name)
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.name).font(.system(size: 14, weight: .bold)).foregroundStyle(GymStyle.ink)
                    Text(member.phone).font(.system(size: 12)).foregroundStyle(GymStyle.muted)
                }
                Spacer(minLength: 3)
                DueBadge(due: DateSupport.active(member) ? DateSupport.dueLabel(member.dueDate) : DateSupport.status(member))
            }
            Rectangle().fill(GymStyle.border).frame(height: 1)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.planName).font(.system(size: 12, weight: .semibold)).foregroundStyle(GymStyle.ink)
                    Text(rupees(member.fee) + " · Due " + DateSupport.dueLabel(member.dueDate)).font(.system(size: 11)).foregroundStyle(GymStyle.muted)
                }
                Spacer()
                Button("Profile", action: onProfile).font(.system(size: 10, weight: .bold)).foregroundStyle(GymStyle.forest)
                Button(checkedIn ? "Undo" : "Check in", action: onToggle).font(.system(size: 10, weight: .bold)).foregroundStyle(GymStyle.forest)
                    .padding(.horizontal, 9).padding(.vertical, 7).background(GymStyle.mint.opacity(0.38), in: RoundedRectangle(cornerRadius: 9))
            }
        }.padding(13).background(.white, in: RoundedRectangle(cornerRadius: 16))
    }
}
private struct DueMemberCard: View {
    let member: Member; let onProfile: () -> Void; let onPay: () -> Void
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 9) {
                AvatarView(name: member.name)
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.name).font(.system(size: 14, weight: .bold)).foregroundStyle(GymStyle.ink)
                    Text(member.planName + " · Due " + DateSupport.dueLabel(member.dueDate)).font(.system(size: 11)).foregroundStyle(GymStyle.muted)
                }
                Spacer(); Text(rupees(member.fee)).font(.system(size: 13, weight: .bold)).foregroundStyle(GymStyle.ink)
            }
            HStack {
                DueBadge(due: DateSupport.dueLabel(member.dueDate)); Spacer()
                Button("Profile", action: onProfile).font(.system(size: 11, weight: .bold)).foregroundStyle(GymStyle.forest)
                Button("Record payment", action: onPay).font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 7).background(GymStyle.forest, in: RoundedRectangle(cornerRadius: 9))
            }
        }.padding(13).background(.white, in: RoundedRectangle(cornerRadius: 16))
    }
}
private struct MemberProfilePage: View {
    let data: GymState; let member: Member; let checkedIn: Bool
    let onRecordPayment: () -> Void; let onToggleCheckIn: () -> Void; let onEditDates: () -> Void
    private var payments: [PaymentRecord] { data.payments.filter { $0.memberId == member.id }.sorted { $0.paidOn > $1.paidOn } }
    private var visits: [AttendanceRecord] { data.attendance.filter { $0.memberId == member.id }.sorted { $0.checkedInAt > $1.checkedInAt } }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                AvatarView(name: member.name)
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.name).font(.system(size: 20, weight: .bold)).foregroundStyle(GymStyle.ink)
                    Text(member.phone).font(.system(size: 12)).foregroundStyle(GymStyle.muted)
                }
                Spacer(); DueBadge(due: DateSupport.status(member))
            }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MEMBERSHIP").font(.system(size: 10, weight: .heavy)).tracking(1).foregroundStyle(GymStyle.muted)
                        ProfileLine(label: "Plan", value: member.planName)
                        ProfileLine(label: "Plan fee", value: rupees(member.fee))
                        ProfileLine(label: "Start date", value: member.startDate)
                        ProfileLine(label: "Expiry date", value: member.expiryDate)
                        ProfileLine(label: "Next fee due", value: member.dueDate)
                        Button("Edit membership dates", action: onEditDates).buttonStyle(.bordered).tint(GymStyle.forest).frame(maxWidth: .infinity)
                    }.padding(14).background(.white, in: RoundedRectangle(cornerRadius: 16))
                    HStack(spacing: 8) {
                        Button("Record payment", action: onRecordPayment).buttonStyle(.borderedProminent).tint(GymStyle.forest).frame(maxWidth: .infinity)
                        Button(checkedIn ? "Undo check-in" : "Check in", action: onToggleCheckIn).buttonStyle(.bordered).tint(GymStyle.forest).frame(maxWidth: .infinity)
                    }
                    Text("Payment history (" + String(payments.count) + ")").font(.system(size: 16, weight: .bold)).foregroundStyle(GymStyle.ink)
                    if payments.isEmpty { EmptyState(title: "No payments recorded", message: "Recorded payments will appear here.") }
                    ForEach(payments.prefix(20)) { payment in
                        HStack {
                            Image(systemName: "receipt").foregroundStyle(GymStyle.forest)
                            VStack(alignment: .leading, spacing: 3) { Text(payment.paidOn).font(.system(size: 12, weight: .semibold)).foregroundStyle(GymStyle.ink); Text(payment.method).font(.system(size: 11)).foregroundStyle(GymStyle.muted) }
                            Spacer(); Text(rupees(payment.amount)).font(.system(size: 13, weight: .bold)).foregroundStyle(GymStyle.forest)
                        }.padding(12).background(.white, in: RoundedRectangle(cornerRadius: 13))
                    }
                    Text("Attendance history (" + String(visits.count) + ")").font(.system(size: 16, weight: .bold)).foregroundStyle(GymStyle.ink)
                    if visits.isEmpty { EmptyState(title: "No attendance yet", message: "Check-ins appear here with timestamps.") }
                    ForEach(visits.prefix(20)) { record in
                        HStack { Image(systemName: "checkmark.circle.fill").foregroundStyle(GymStyle.forest); Text(record.checkedInAt).font(.system(size: 11)).foregroundStyle(GymStyle.ink); Spacer() }
                            .padding(12).background(.white, in: RoundedRectangle(cornerRadius: 13))
                    }
                }.padding(.bottom, 15)
            }
        }.padding(.horizontal, 19).padding(.top, 17)
    }
}
private struct ProfileLine: View {
    let label: String; let value: String
    var body: some View {
        HStack { Text(label).font(.system(size: 12)).foregroundStyle(GymStyle.muted); Spacer(); Text(value).font(.system(size: 12, weight: .semibold)).foregroundStyle(GymStyle.ink) }
    }
}
private struct PlanSettingsPage: View {
    @State private var plans: [MembershipPlan]
    let onSave: ([MembershipPlan]) -> Void
    init(plans: [MembershipPlan], onSave: @escaping ([MembershipPlan]) -> Void) {
        _plans = State(initialValue: plans)
        self.onSave = onSave
    }
    private var valid: Bool { plans.allSatisfy { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.durationMonths > 0 && $0.fee >= 0 } }
    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("Membership plans").font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(GymStyle.ink)
            Text("Settings apply to new members. Existing member fees remain unchanged.").font(.system(size: 12)).foregroundStyle(GymStyle.muted)
            ScrollView {
                VStack(spacing: 10) {
                    ForEach($plans) { $plan in
                        VStack(alignment: .leading, spacing: 9) {
                            TextField("Plan name", text: $plan.name).textFieldStyle(.roundedBorder)
                            Stepper("Duration: " + String(plan.durationMonths) + " months", value: $plan.durationMonths, in: 1...36)
                                .font(.system(size: 12, weight: .medium)).foregroundStyle(GymStyle.ink)
                            TextField("Fee in rupees", value: $plan.fee, format: .number).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                        }.padding(13).background(.white, in: RoundedRectangle(cornerRadius: 15))
                    }
                }
            }
            Button("Save plan settings") { onSave(plans) }.buttonStyle(.borderedProminent).tint(GymStyle.forest).disabled(!valid).frame(maxWidth: .infinity)
        }.padding(.horizontal, 19).padding(.top, 17).padding(.bottom, 10)
    }
}
private struct AddMemberSheet: View {
    @Environment(\.dismiss) private var dismiss
    let plans: [MembershipPlan]
    let existingPhones: [String]
    let onSave: (String, String, MembershipPlan, String, String) -> Void
    @State private var name = ""
    @State private var phone = ""
    @State private var planId = ""
    @State private var start = DateSupport.dayString()
    @State private var expiry = DateSupport.plusMonths(1, from: DateSupport.dayString())
    private var selectedPlan: MembershipPlan { plans.first(where: { $0.id == planId }) ?? plans[0] }
    private var digits: String { phone.filter(\.isNumber) }
    private var validPhone: Bool { digits.count == 10 || (digits.count == 12 && digits.hasPrefix("91")) }
    private var duplicatePhone: Bool { validPhone && existingPhones.contains { normalizedPhone($0) == normalizedPhone(phone) } }
    private var validDates: Bool {
        guard let s = DateSupport.date(start), let e = DateSupport.date(expiry) else { return false }
        return e >= s
    }
    init(plans: [MembershipPlan], existingPhones: [String], onSave: @escaping (String, String, MembershipPlan, String, String) -> Void) {
        self.plans = plans
        self.existingPhones = existingPhones
        self.onSave = onSave
        _planId = State(initialValue: plans.first?.id ?? "monthly")
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("Member details") {
                    TextField("Full name *", text: $name).textInputAutocapitalization(.words)
                    TextField("Phone number *", text: $phone).keyboardType(.phonePad)
                    if !phone.isEmpty && !validPhone { Text("Enter a valid 10-digit number or +91 number.").font(.caption).foregroundStyle(.red) }
                    if duplicatePhone { Text("This phone number already exists.").font(.caption).foregroundStyle(.red) }
                }
                Section("Membership plan") {
                    Picker("Plan", selection: $planId) {
                        ForEach(plans) { p in Text(p.name + " · " + rupees(p.fee)).tag(p.id) }
                    }
                    HStack { Text("Plan fee"); Spacer(); Text(rupees(selectedPlan.fee)).fontWeight(.semibold) }
                }
                Section("Membership dates") {
                    TextField("Start date (YYYY-MM-DD)", text: $start).textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("Expiry date (YYYY-MM-DD)", text: $expiry).textInputAutocapitalization(.never).autocorrectionDisabled()
                    if !validDates { Text("Dates must be valid; expiry must be on or after start.").font(.caption).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Add member").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), phone.trimmingCharacters(in: .whitespacesAndNewlines), selectedPlan, start, expiry) }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !validPhone || duplicatePhone || !validDates)
                }
            }
            .onChange(of: planId) { _, id in
                if let p = plans.first(where: { $0.id == id }) { expiry = DateSupport.plusMonths(p.durationMonths, from: start) }
            }
            .onChange(of: start) { _, value in expiry = DateSupport.plusMonths(selectedPlan.durationMonths, from: value) }
        }.tint(GymStyle.forest)
    }
}
private struct EditDatesSheet: View {
    @Environment(\.dismiss) private var dismiss
    let member: Member
    let onSave: (String, String, String) -> Void
    @State private var start = ""
    @State private var expiry = ""
    @State private var due = ""
    init(member: Member, onSave: @escaping (String, String, String) -> Void) {
        self.member = member
        self.onSave = onSave
        _start = State(initialValue: member.startDate)
        _expiry = State(initialValue: member.expiryDate)
        _due = State(initialValue: member.dueDate)
    }
    private var valid: Bool {
        guard let s = DateSupport.date(start), let e = DateSupport.date(expiry), DateSupport.date(due) != nil else { return false }
        return e >= s
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("Membership dates") {
                    TextField("Start (YYYY-MM-DD)", text: $start).textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("Expiry (YYYY-MM-DD)", text: $expiry).textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("Next fee due (YYYY-MM-DD)", text: $due).textInputAutocapitalization(.never).autocorrectionDisabled()
                    if !valid { Text("Enter valid dates; expiry must be on or after start.").font(.caption).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Edit membership dates").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { onSave(start, expiry, due) }.disabled(!valid) }
            }
        }.tint(GymStyle.forest)
    }
}
private struct SummaryCard: View {
    let title: String; let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 10, weight: .heavy)).foregroundStyle(GymStyle.muted)
            Text(value).font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(GymStyle.ink)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(14).background(.white, in: RoundedRectangle(cornerRadius: 15))
    }
}
private struct AvatarView: View {
    let name: String
    private var initials: String { name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined() }
    var body: some View { Text(initials).font(.system(size: 12, weight: .bold)).foregroundStyle(GymStyle.forest).frame(width: 41, height: 41).background(GymStyle.mint.opacity(0.5), in: Circle()) }
}
private struct DueBadge: View {
    let due: String
    private var urgent: Bool { ["Overdue", "Today", "Tomorrow", "Expired"].contains(due) }
    var body: some View { Text(due).font(.system(size: 10, weight: .bold)).foregroundStyle(urgent ? GymStyle.orange : GymStyle.forest).padding(.horizontal, 8).padding(.vertical, 5).background(urgent ? Color.orange.opacity(0.12) : GymStyle.mint.opacity(0.4), in: Capsule()) }
}
private struct EmptyState: View {
    let title: String; let message: String
    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: "magnifyingglass").font(.system(size: 25)).foregroundStyle(GymStyle.muted)
            Text(title).font(.system(size: 14, weight: .bold)).foregroundStyle(GymStyle.ink)
            Text(message).font(.system(size: 12)).foregroundStyle(GymStyle.muted).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity).padding(23).background(.white, in: RoundedRectangle(cornerRadius: 16))
    }
}
private func normalizedPhone(_ phone: String) -> String { String(phone.filter(\.isNumber).suffix(10)) }
private func rupees(_ amount: Int) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency; f.currencyCode = "INR"; f.locale = Locale(identifier: "en_IN"); f.maximumFractionDigits = 0
    return f.string(from: NSNumber(value: amount)) ?? ("₹" + String(amount))
}
