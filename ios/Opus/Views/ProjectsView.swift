import SwiftUI

// MARK: - Projects ViewModel
@MainActor
final class ProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var showAdd = false
    @Published var newName = ""
    @Published var newEmoji = "📁"

    func addProject() {
        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let colors = ["#8A4AF3", "#60A5FA", "#34D399", "#F87171", "#A78BFA"]
        let hex = colors[projects.count % colors.count]
        projects.append(Project(name: newName.trimmingCharacters(in: .whitespaces),
                                emoji: newEmoji, colorHex: hex))
        newName = ""; newEmoji = "📁"; showAdd = false
    }
}

// MARK: - Projects View
struct ProjectsView: View {
    @StateObject private var vm = ProjectsViewModel()
    @State private var expandedProject: Project? = nil
    let geo: GeometryProxy

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                headerSection
                projectGrid
                Spacer().frame(height: geo.safeAreaInsets.bottom + 140)
            }
            .padding(.top, geo.safeAreaInsets.top + 16)
        }
        .sheet(isPresented: $vm.showAdd) { addProjectSheet }
        .sheet(item: $expandedProject) { project in
            ProjectDetailSheet(project: project) { updated in
                if let idx = vm.projects.firstIndex(where: { $0.id == updated.id }) {
                    vm.projects[idx] = updated
                }
            }
        }
    }

    // MARK: Header
    private var headerSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Projects")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                Text("\(vm.projects.count) active · \(vm.projects.reduce(0) { $0 + $1.completedCount }) tasks done")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.38))
            }
            Spacer()
            Button { vm.showAdd = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        LinearGradient(colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(Circle())
                    .shadow(color: Color(hex: "#8A4AF3").opacity(0.55), radius: 12, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: Grid
    private var projectGrid: some View {
        Group {
            if vm.projects.isEmpty {
                emptyProjectsState
            } else {
                VStack(spacing: 12) {
                    ForEach(vm.projects) { project in
                        ProjectCard(project: project)
                            .onTapGesture { expandedProject = project }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var emptyProjectsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(
                    LinearGradient(colors: [Color(hex: "#A78BFA"), Color(hex: "#8A4AF3")],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            Text("No projects yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            Text("Tap the + button to create your first project")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.40))
                .multilineTextAlignment(.center)

            Button { vm.showAdd = true } label: {
                Label("New Project", systemImage: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                                       startPoint: .leading, endPoint: .trailing),
                        in: Capsule()
                    )
                    .shadow(color: Color(hex: "#8A4AF3").opacity(0.5), radius: 12, x: 0, y: 4)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "#1A1A1E"))
                .overlay(RoundedRectangle(cornerRadius: 24)
                    .stroke(Color(hex: "#8A4AF3").opacity(0.2), lineWidth: 1))
        }
        .padding(.horizontal, 16)
    }

    // MARK: Add Sheet
    private var addProjectSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0D0D10").ignoresSafeArea()
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        TextField("Emoji", text: $vm.newEmoji)
                            .font(.system(size: 28))
                            .multilineTextAlignment(.center)
                            .frame(width: 60)
                            .padding(12)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("Project name", text: $vm.newName)
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "#8A4AF3").opacity(0.3), lineWidth: 1))
                    }

                    Button(action: vm.addProject) {
                        Text("Create Project")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding()
                            .background(LinearGradient(colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                                                       startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(vm.newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(vm.newName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { vm.showAdd = false }.foregroundColor(.white.opacity(0.55))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Project Card
struct ProjectCard: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack(spacing: 10) {
                Text(project.emoji)
                    .font(.system(size: 24))
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    Text("\(project.tasks.count) tasks")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.38))
                }
                Spacer()
                Text("\(Int(project.progress * 100))%")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(hex: "#A78BFA"), project.color],
                                       startPoint: .leading, endPoint: .trailing)
                    )
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.07)).frame(height: 6)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color(hex: "#6E6BF5"), project.color],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * project.progress, height: 6)
                        .animation(.spring(response: 1.0, dampingFraction: 0.72), value: project.progress)
                }
            }
            .frame(height: 6)

            HStack(spacing: 16) {
                Label("\(project.completedCount) done", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#34D399").opacity(0.8))

                Label("\(project.tasks.count - project.completedCount) left", systemImage: "circle")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.38))

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.22))
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#1A1A1E"))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [project.color.opacity(0.35), Color.white.opacity(0.04)],
                                startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1)
                )
                .shadow(color: project.color.opacity(0.10), radius: 14, x: 0, y: 6)
        }
    }
}

// MARK: - Project Detail Sheet
struct ProjectDetailSheet: View {
    @State var project: Project
    let onSave: (Project) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0D0D10").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Progress hero
                        VStack(spacing: 8) {
                            ZStack {
                                Circle().stroke(Color.white.opacity(0.06), lineWidth: 14)
                                    .frame(width: 120, height: 120)
                                Circle()
                                    .trim(from: 0, to: project.progress)
                                    .stroke(
                                        LinearGradient(colors: [Color(hex: "#6E6BF5"), project.color],
                                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                                    )
                                    .frame(width: 120, height: 120)
                                    .rotationEffect(.degrees(-90))
                                    .shadow(color: project.color.opacity(0.7), radius: 10)

                                VStack(spacing: 2) {
                                    Text("\(Int(project.progress * 100))%")
                                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("complete")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.3))
                                        .kerning(0.5)
                                }
                            }
                            Text(project.emoji + " " + project.name)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 8)

                        // Task list
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tasks")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)

                            VStack(spacing: 8) {
                                ForEach(project.tasks) { task in
                                    HStack(spacing: 12) {
                                        Button {
                                            if let idx = project.tasks.firstIndex(where: { $0.id == task.id }) {
                                                project.tasks[idx].isCompleted.toggle()
                                                onSave(project)
                                            }
                                        } label: {
                                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 20))
                                                .foregroundColor(task.isCompleted ? Color(hex: "#34D399") : .white.opacity(0.3))
                                        }
                                        Text(task.title)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(task.isCompleted ? .white.opacity(0.35) : .white.opacity(0.9))
                                            .strikethrough(task.isCompleted, color: .white.opacity(0.2))
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color(hex: "#1A1A1E"))
                                            .overlay(RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.white.opacity(0.06), lineWidth: 0.5))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        Spacer().frame(height: 40)
                    }
                }
            }
            .navigationTitle(project.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "#8A4AF3"))
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}
