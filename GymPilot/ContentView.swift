import SwiftUI

private enum Style {
    static let ink = Color(red: 0.09, green: 0.13, blue: 0.11)
    static let forest = Color(red: 0.09, green: 0.30, blue: 0.23)
    static let mint = Color(red: 0.72, green: 0.95, blue: 0.81)
    static let canvas = Color(red: 0.96, green: 0.97, blue: 0.95)
    static let muted = Color(red: 0.44, green: 0.50, blue: 0.47)
    static let border = Color(red: 0.88, green: 0.91, blue: 0.88)
    static let orange = Color(red: 0.68, green: 0.34, blue: 0.20)
}

private struct Member: Identifiable {
    let id: UUID
    var name: String
    var phone: String
    var plan: String
    var fee: Int
    var due: String
    var checkedIn: Bool
    init(id: UUID = UUID(), name: String, phone: String, plan: String, fee: Int, due: String, checkedIn: Bool = false) {
        self.id = id; self.name = name; self.phone = phone; self.plan = plan; self.fee = fee; self.due = due; self.checkedIn = checkedIn
    }
    static let samples = [
        Member(name: "Aman Sharma", phone: "98765 43210", plan: "Monthly", fee: 1200, due: "Today", checkedIn: true),
        Member(name: "Priya Verma", phone: "98901 23456", plan: "Quarterly", fee: 3000, due: "22 Oct"),
        Member(name: "Rahul Kumar", phone: "98111 22334", plan: "Monthly", fee: 1200, due: "Tomorrow"),
        Member(name: "Neha Singh", phone: "98770 11223", plan: "Monthly", fee: 1200, due: "25 Oct"),
        Member(name: "Arjun Malik", phone: "99911 22334", plan: "Half-yearly", fee: 6000, due: "28 Oct"),
        Member(name: "Simran Kaur", phone: "98140 22110", plan: "Monthly", fee: 1200, due: "Overdue")
    ]
}
private enum Tab: String, CaseIterable, Identifiable {
    case home, members, attendance, dues
    var id: String { rawValue }
    var title: String { switch self { case .home: "Home"; case .members: "Members"; case .attendance: "Check-in"; case .dues: "Dues" } }
    var icon: String { switch self { case .home: "square.grid.2x2.fill"; case .members: "person.2.fill"; case .attendance: "checkmark.circle.fill"; case .dues: "indianrupeesign.circle.fill" } }
}

struct ContentView: View {
    @State private var members = Member.samples
    @State private var tab: Tab = .home
    @State private var addOpen = false
    @State private var search = ""
    private var urgent: [Member] { members.filter { ["Overdue", "Today", "Not paid"].contains($0.due) } }

    var body: some View {
        VStack(spacing: 0) {
            header
            Group {
                switch tab {
                case .home: dashboard
                case .members: membersScreen
                case .attendance: attendanceScreen
                case .dues: duesScreen
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            bottomBar
        }
        .background(Style.canvas.ignoresSafeArea())
        .preferredColorScheme(.light)
        .sheet(isPresented: $addOpen) {
            AddMemberSheet { name, phone, plan in
                members.insert(Member(name: name, phone: phone, plan: plan, fee: fee(plan), due: "Not paid"), at: 0)
                tab = .members
                addOpen = false
            }
        }
    }

    private var header: some View {
        HStack(spacing: 11) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 21, weight: .bold)).foregroundStyle(Style.mint)
                .frame(width: 43, height: 43).background(Style.forest, in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 2) {
                Text("GYMPILOT").font(.system(size: 10, weight: .heavy)).tracking(2).foregroundStyle(Style.muted)
                Text("Your gym, in control.").font(.system(size: 15, weight: .bold)).foregroundStyle(Style.ink)
            }
            Spacer()
            if tab == .members {
                Button { addOpen = true } label: { Image(systemName: "plus").font(.system(size: 17, weight: .bold)).foregroundStyle(.white).frame(width: 40, height: 40).background(Style.forest, in: RoundedRectangle(cornerRadius: 13)) }
                    .accessibilityLabel("Add member")
            } else {
                Image(systemName: "bell").foregroundStyle(Style.ink).frame(width: 40, height: 40).background(Style.canvas, in: Circle())
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 12).background(.white)
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases) { item in
                Button { withAnimation(.easeInOut(duration: 0.15)) { tab = item } } label: {
                    VStack(spacing: 5) {
                        Image(systemName: item.icon).font(.system(size: 18, weight: .semibold))
                        Text(item.title).font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(tab == item ? Style.forest : Style.muted)
                    .frame(maxWidth: .infinity).padding(.top, 10).padding(.bottom, 7).contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
        }.background(.white).overlay(alignment: .top) { Rectangle().fill(Style.border).frame(height: 1) }
    }

    private var dashboard: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 17) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("FRIDAY, 16 OCTOBER").font(.system(size: 10, weight: .heavy)).tracking(1.2).foregroundStyle(Style.muted)
                    Text("Good evening 👋").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(Style.ink)
                    Text("Here’s what’s happening at your gym.").font(.system(size: 13)).foregroundStyle(Style.muted)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("ESTIMATED COLLECTION").font(.system(size: 10, weight: .heavy)).tracking(1.1).foregroundStyle(Style.mint)
                    Text(rupees(members.filter { $0.due != "Overdue" && $0.due != "Not paid" }.reduce(0) { $0 + $1.fee }))
                        .font(.system(size: 30, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    Text("Sample total from demo member records").font(.system(size: 11)).foregroundStyle(.white.opacity(0.75))
                    Rectangle().fill(.white.opacity(0.18)).frame(height: 1).padding(.vertical, 4)
                    Label("Connect payments to show live collections.", systemImage: "info.circle").font(.system(size: 11)).foregroundStyle(.white.opacity(0.85))
                }.padding(19).frame(maxWidth: .infinity, alignment: .leading).background(Style.forest, in: RoundedRectangle(cornerRadius: 23))

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Metric(title: "Active members", value: "(members.count)", subtitle: "Across all plans", icon: "person.2.fill")
                        Metric(title: "Checked in", value: "(members.filter(\.checkedIn).count)", subtitle: "Today's attendance", icon: "checkmark.seal.fill")
                    }
                    HStack(spacing: 10) {
                        Metric(title: "Fee alerts", value: "(urgent.count)", subtitle: "Needs follow-up", icon: "bell.badge.fill", warning: true)
                        Metric(title: "Overdue", value: "(members.filter { $0.due == "Overdue" }.count)", subtitle: "Past due date", icon: "calendar.badge.exclamationmark", warning: true)
                    }
                }
                HStack {
                    Text("Quick actions").font(.system(size: 17, weight: .bold)).foregroundStyle(Style.ink)
                    Spacer(); Button("See all") { tab = .members }.font(.system(size: 12, weight: .bold)).foregroundStyle(Style.forest)
                }
                HStack(spacing: 9) {
                    QuickAction(title: "Add member", icon: "person.badge.plus") { addOpen = true }
                    QuickAction(title: "Attendance", icon: "checkmark.circle") { tab = .attendance }
                    QuickAction(title: "Fee dues", icon: "indianrupeesign.circle") { tab = .dues }
                }
                HStack {
                    Text("Needs attention").font(.system(size: 17, weight: .bold)).foregroundStyle(Style.ink)
                    Spacer(); Button("View all") { tab = .dues }.font(.system(size: 12, weight: .bold)).foregroundStyle(Style.forest)
                }
                ForEach(urgent.prefix(3)) { m in MemberRow(member: m) { tab = .dues } }
                Text("DEMO MODE · DATA IS NOT YET SYNCED").font(.system(size: 9, weight: .medium)).tracking(0.4).foregroundStyle(Style.muted)
            }.padding(20)
        }
    }

    private var membersScreen: some View {
        VStack(alignment: .leading, spacing: 12) {
            heading("Members", subtitle: "(members.count) members in your directory")
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass").foregroundStyle(Style.muted)
                TextField("Search name or phone…", text: $search).font(.system(size: 14)).autocorrectionDisabled()
            }.padding(13).background(.white, in: RoundedRectangle(cornerRadius: 15)).overlay(RoundedRectangle(cornerRadius: 15).stroke(Style.border, lineWidth: 1))
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(members.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) || $0.phone.localizedCaseInsensitiveContains(search) }) { m in
                        MemberCard(member: m, actionTitle: m.checkedIn ? "Undo check-in" : "Check in") { toggle(m.id) }
                    }
                }.padding(.bottom, 18)
            }
        }.padding(.horizontal, 20).padding(.top, 20)
    }

    private var attendanceScreen: some View {
        VStack(alignment: .leading, spacing: 13) {
            heading("Attendance", subtitle: "Tap check-in to record today's attendance.")
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("TODAY'S CHECK-INS").font(.system(size: 10, weight: .heavy)).tracking(1).foregroundStyle(Style.mint)
                    Text("(members.filter(\.checkedIn).count) / (members.count)").font(.system(size: 27, weight: .bold, design: .rounded)).foregroundStyle(.white)
                }
                Spacer(); Image(systemName: "checkmark.seal.fill").font(.system(size: 31)).foregroundStyle(Style.mint)
            }.padding(17).background(Style.forest, in: RoundedRectangle(cornerRadius: 18))
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(members) { m in MemberCard(member: m, actionTitle: m.checkedIn ? "Undo" : "Check in") { toggle(m.id) } }
                }.padding(.bottom, 20)
            }
        }.padding(.horizontal, 20).padding(.top, 20)
    }

    private var duesScreen: some View {
        let dues = members.filter { ["Overdue", "Today", "Not paid"].contains($0.due) }
        return VStack(alignment: .leading, spacing: 13) {
            heading("Fee tracker", subtitle: "Find outstanding fees and follow-ups.")
            HStack(spacing: 10) {
                Summary(title: "NEEDS ATTENTION", value: "(dues.count)")
                Summary(title: "OVERDUE", value: "(members.filter { $0.due == "Overdue" }.count)")
            }
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(dues) { m in
                        VStack(spacing: 11) {
                            HStack(spacing: 10) {
                                Avatar(name: m.name)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(m.name).font(.system(size: 14, weight: .bold)).foregroundStyle(Style.ink)
                                    Text("(m.plan) · Due (m.due.lowercased())").font(.system(size: 11)).foregroundStyle(Style.muted)
                                }
                                Spacer(); Text(rupees(m.fee)).font(.system(size: 14, weight: .bold)).foregroundStyle(Style.ink)
                            }
                            HStack {
                                DueBadge(due: m.due); Spacer()
                                Button("Mark as paid") { markPaid(m.id) }.font(.system(size: 12, weight: .bold)).foregroundStyle(Style.forest)
                            }
                        }.padding(14).background(.white, in: RoundedRectangle(cornerRadius: 18))
                    }
                }.padding(.bottom, 20)
            }
        }.padding(.horizontal, 20).padding(.top, 20)
    }

    private func heading(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 27, weight: .bold, design: .rounded)).foregroundStyle(Style.ink)
            Text(subtitle).font(.system(size: 13)).foregroundStyle(Style.muted)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func toggle(_ id: UUID) {
        guard let i = members.firstIndex(where: { $0.id == id }) else { return }
        members[i].checkedIn.toggle()
    }
    private func markPaid(_ id: UUID) {
        guard let i = members.firstIndex(where: { $0.id == id }) else { return }
        members[i].due = "Paid"
    }
}

private struct Metric: View {
    let title: String; let value: String; let subtitle: String; let icon: String; var warning = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(warning ? Style.orange : Style.forest)
                .frame(width: 34, height: 34).background(warning ? Color.orange.opacity(0.13) : Style.mint.opacity(0.45), in: RoundedRectangle(cornerRadius: 11))
            Text(value).font(.system(size: 25, weight: .bold, design: .rounded)).foregroundStyle(Style.ink)
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(Style.ink)
            Text(subtitle).font(.system(size: 10)).foregroundStyle(Style.muted).lineLimit(1)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(14).background(.white, in: RoundedRectangle(cornerRadius: 19))
    }
}
private struct QuickAction: View {
    let title: String; let icon: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(Style.forest).frame(width: 40, height: 40).background(Style.mint.opacity(0.5), in: Circle())
                Text(title).font(.system(size: 10, weight: .semibold)).foregroundStyle(Style.ink).lineLimit(1).minimumScaleFactor(0.8)
            }.frame(maxWidth: .infinity).padding(.vertical, 12).background(.white, in: RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain)
    }
}
private struct MemberRow: View {
    let member: Member; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Avatar(name: member.name)
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.name).font(.system(size: 13, weight: .bold)).foregroundStyle(Style.ink)
                    Text("Membership · (rupees(member.fee))").font(.system(size: 11)).foregroundStyle(Style.muted)
                }
                Spacer(); DueBadge(due: member.due)
            }.padding(12).background(.white, in: RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain)
    }
}
private struct MemberCard: View {
    let member: Member; let actionTitle: String; let action: () -> Void
    var body: some View {
        VStack(spacing: 11) {
            HStack(spacing: 10) {
                Avatar(name: member.name)
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.name).font(.system(size: 14, weight: .bold)).foregroundStyle(Style.ink)
                    Text(member.phone).font(.system(size: 12)).foregroundStyle(Style.muted)
                }
                Spacer(minLength: 3); DueBadge(due: member.due)
            }
            Rectangle().fill(Style.border).frame(height: 1)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.plan).font(.system(size: 12, weight: .semibold)).foregroundStyle(Style.ink)
                    Text("(rupees(member.fee)) · Due (member.due)").font(.system(size: 11)).foregroundStyle(Style.muted)
                }
                Spacer()
                Button(actionTitle, action: action).font(.system(size: 11, weight: .bold)).foregroundStyle(Style.forest)
                    .padding(.horizontal, 10).padding(.vertical, 8).background(Style.mint.opacity(0.38), in: RoundedRectangle(cornerRadius: 11))
            }
        }.padding(14).background(.white, in: RoundedRectangle(cornerRadius: 18))
    }
}
private struct Summary: View {
    let title: String; let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 10, weight: .heavy)).foregroundStyle(Style.muted)
            Text(value).font(.system(size: 25, weight: .bold, design: .rounded)).foregroundStyle(Style.ink)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(15).background(.white, in: RoundedRectangle(cornerRadius: 17))
    }
}
private struct Avatar: View {
    let name: String
    private var initials: String { name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined() }
    var body: some View {
        Text(initials).font(.system(size: 12, weight: .bold)).foregroundStyle(Style.forest).frame(width: 42, height: 42).background(Style.mint.opacity(0.5), in: Circle())
    }
}
private struct DueBadge: View {
    let due: String
    private var urgent: Bool { ["Overdue", "Today", "Not paid"].contains(due) }
    var body: some View {
        Text(due).font(.system(size: 10, weight: .bold)).foregroundStyle(urgent ? Style.orange : Style.forest)
            .padding(.horizontal, 9).padding(.vertical, 5).background(urgent ? Color.orange.opacity(0.12) : Style.mint.opacity(0.4), in: Capsule())
    }
}
private struct AddMemberSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var plan = "Monthly"
    let onSave: (String, String, String) -> Void
    private let plans = ["Monthly", "Quarterly", "Half-yearly", "Annual"]
    var body: some View {
        NavigationStack {
            Form {
                Section("Member details") {
                    TextField("Full name", text: $name).textInputAutocapitalization(.words)
                    TextField("Phone number", text: $phone).keyboardType(.phonePad)
                }
                Section("Membership plan") {
                    Picker("Plan", selection: $plan) { ForEach(plans, id: \.self) { Text($0).tag($0) } }
                    HStack { Text("Plan fee"); Spacer(); Text(rupees(fee(plan))).fontWeight(.semibold) }
                }
            }
            .navigationTitle("Add member").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), phone.trimmingCharacters(in: .whitespacesAndNewlines), plan)
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }.tint(Style.forest)
    }
}
private func fee(_ plan: String) -> Int {
    switch plan { case "Quarterly": 3000; case "Half-yearly": 6000; case "Annual": 10000; default: 1200 }
}
private func rupees(_ amount: Int) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency; f.currencyCode = "INR"; f.locale = Locale(identifier: "en_IN"); f.maximumFractionDigits = 0
    return f.string(from: NSNumber(value: amount)) ?? "₹(amount)"
}
