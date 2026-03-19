import SwiftUI

// MARK: - Projects ViewModel
@MainActor
final class ProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = [] { didSet { save() } }
    @Published var showAdd   = false
    @Published var newName   = ""
    @Published var newEmoji  = "📁"

    private let key = "projects_v1"

    init() { load() }

    var activeProjects:   [Project] { projects.filter { !$0.isArchived } }
    var archivedProjects: [Project] { projects.filter {  $0.isArchived } }

    func addProject() {
        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let colors = ["#8A4AF3", "#60A5FA", "#34D399", "#F87171", "#A78BFA"]
        let hex = colors[activeProjects.count % colors.count]
        projects.append(Project(name: newName.trimmingCharacters(in: .whitespaces),
                                emoji: newEmoji, colorHex: hex))
        newName = ""; newEmoji = "📁"; showAdd = false
    }

    func rename(_ project: Project, name: String, emoji: String) {
        guard let idx = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[idx].name  = name.trimmingCharacters(in: .whitespaces)
        projects[idx].emoji = emoji
    }

    func archive(_ project: Project) {
        guard let idx = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[idx].isArchived = true
    }

    func unarchive(_ project: Project) {
        guard let idx = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[idx].isArchived = false
    }

    func delete(_ project: Project) {
        projects.removeAll { $0.id == project.id }
    }

    // MARK: - Persistence
    private func save() {
        if let d = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(d, forKey: key)
        }
    }

    private func load() {
        guard let d = UserDefaults.standard.data(forKey: key),
              let p = try? JSONDecoder().decode([Project].self, from: d) else { return }
        projects = p
    }
}

// MARK: - Projects View
struct ProjectsView: View {
    @StateObject private var vm = ProjectsViewModel()
    @State private var expandedProject: Project? = nil
    @State private var renamingProject: Project? = nil
    @State private var renameText  = ""
    @State private var renameEmoji = ""
    @State private var showArchived = false
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
        .sheet(item: $renamingProject) { _ in renameSheet }
    }

    // MARK: Header
    private var headerSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Projects")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                Text("\(vm.activeProjects.count) active · \(vm.activeProjects.reduce(0) { $0 + $1.completedCount }) tasks done")
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
        VStack(spacing: 12) {
            if vm.activeProjects.isEmpty && vm.archivedProjects.isEmpty {
                emptyProjectsState
            } else {
                // Active projects
                VStack(spacing: 12) {
                    ForEach(vm.activeProjects) { project in
                        ProjectCard(project: project)
                            .onTapGesture { expandedProject = project }
                            .contextMenu {
                                Button {
                                    renameText  = project.name
                                    renameEmoji = project.emoji
                                    renamingProject = project
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation { vm.archive(project) }
                                } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                                Divider()
                                Button(role: .destructive) {
                                    withAnimation { vm.delete(project) }
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                            }
                    }
                }

                // Archived section
                if !vm.archivedProjects.isEmpty {
                    VStack(spacing: 8) {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                showArchived.toggle()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "archivebox")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.38))
                                Text("Archived (\(vm.archivedProjects.count))")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.38))
                                Spacer()
                                Image(systemName: showArchived ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.25))
                            }
                            .padding(.horizontal, 4)
                        }
                        .buttonStyle(.plain)

                        if showArchived {
                            VStack(spacing: 8) {
                                ForEach(vm.archivedProjects) { project in
                                    ProjectCard(project: project)
                                        .opacity(0.55)
                                        .contextMenu {
                                            Button {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                withAnimation { vm.unarchive(project) }
                                            } label: {
                                                Label("Unarchive", systemImage: "arrow.uturn.up")
                                            }
                                            Divider()
                                            Button(role: .destructive) {
                                                withAnimation { vm.delete(project) }
                                            } label: {
                                                Label("Delete", systemImage: "trash.fill")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: Rename Sheet
    private var renameSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0D0D10").ignoresSafeArea()
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        TextField("Emoji", text: $renameEmoji)
                            .font(.system(size: 28))
                            .multilineTextAlignment(.center)
                            .frame(width: 60)
                            .padding(12)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("Project name", text: $renameText)
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "#8A4AF3").opacity(0.3), lineWidth: 1))
                    }

                    Button {
                        if let project = renamingProject {
                            vm.rename(project, name: renameText, emoji: renameEmoji)
                        }
                        renamingProject = nil
                    } label: {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding()
                            .background(LinearGradient(colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                                                       startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(renameText.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(renameText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Rename Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { renamingProject = nil }.foregroundColor(.white.opacity(0.55))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
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
                .fill(Color(hex: "#130E1E"))
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

    @State private var showAddTask    = false
    @State private var newTaskTitle   = ""
    @State private var newTaskCategory: TaskCategory = .work

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
                            HStack {
                                Text("Tasks")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                                Button { showAddTask = true } label: {
                                    Label("Add Task", systemImage: "plus")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color(hex: "#8A4AF3"))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(Color(hex: "#8A4AF3").opacity(0.12))
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(Color(hex: "#8A4AF3").opacity(0.3), lineWidth: 1))
                                }
                            }
                            .padding(.horizontal, 20)

                            if project.tasks.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 32, weight: .thin))
                                        .foregroundColor(.white.opacity(0.2))
                                    Text("No tasks yet")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(32)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(project.tasks) { task in
                                        HStack(spacing: 12) {
                                            Button {
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                if let idx = project.tasks.firstIndex(where: { $0.id == task.id }) {
                                                    project.tasks[idx].isCompleted.toggle()
                                                    onSave(project)
                                                }
                                            } label: {
                                                ZStack {
                                                    if task.isCompleted {
                                                        Circle().fill(Color(hex: "#34D399").opacity(0.15)).frame(width: 24, height: 24)
                                                    }
                                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(task.isCompleted ? Color(hex: "#34D399") : .white.opacity(0.25))
                                                }
                                            }
                                            Circle().fill(task.category.color).frame(width: 6, height: 6)
                                            Text(task.title)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(task.isCompleted ? .white.opacity(0.32) : .white.opacity(0.9))
                                                .strikethrough(task.isCompleted, color: .white.opacity(0.2))
                                                .lineLimit(1)
                                            Spacer()
                                            Text(task.category.rawValue)
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundColor(task.category.color)
                                                .padding(.horizontal, 7)
                                                .padding(.vertical, 3)
                                                .background(task.category.color.opacity(0.12))
                                                .clipShape(Capsule())
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background {
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(Color(hex: "#1A1A1E"))
                                                .overlay(RoundedRectangle(cornerRadius: 14)
                                                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5))
                                        }
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                project.tasks.removeAll { $0.id == task.id }
                                                onSave(project)
                                            } label: {
                                                Label("Delete", systemImage: "trash.fill")
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
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
        .sheet(isPresented: $showAddTask) { addTaskToProjectSheet }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    // MARK: - Add task to project sheet
    private var addTaskToProjectSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0D0D10").ignoresSafeArea()
                VStack(spacing: 20) {
                    TextField("Task title", text: $newTaskTitle)
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(hex: "#8A4AF3").opacity(0.3), lineWidth: 1))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TaskCategory.allCases) { cat in
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    newTaskCategory = cat
                                } label: {
                                    HStack(spacing: 6) {
                                        Circle().fill(cat.color).frame(width: 7, height: 7)
                                        Text(cat.rawValue)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(newTaskCategory == cat ? cat.color : .white.opacity(0.45))
                                    }
                                    .padding(.horizontal, 14).padding(.vertical, 9)
                                    .background(newTaskCategory == cat ? cat.color.opacity(0.15) : Color.white.opacity(0.06), in: Capsule())
                                    .overlay(Capsule().stroke(newTaskCategory == cat ? cat.color.opacity(0.45) : Color.clear, lineWidth: 1))
                                    .animation(.spring(response: 0.3), value: newTaskCategory)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Button {
                        guard !newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        let task = OpusTask(title: newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                                           category: newTaskCategory, schedule: .today)
                        project.tasks.append(task)
                        onSave(project)
                        newTaskTitle    = ""
                        newTaskCategory = .work
                        showAddTask     = false
                    } label: {
                        Text("Add Task")
                            .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding()
                            .background(LinearGradient(colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                                                       startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddTask = false }.foregroundColor(.white.opacity(0.55))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}
