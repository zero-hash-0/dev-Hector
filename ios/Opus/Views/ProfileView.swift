import SwiftUI
import PhotosUI

// MARK: - Profile View
struct ProfileView: View {
    @AppStorage("userName")      private var userName     = "Hector"
    @AppStorage("userHandle")    private var userHandle   = "@hector"
    @AppStorage("userBio")       private var userBio      = "Building things that matter."
    @AppStorage("profileImgData") private var imgData: Data = Data()

    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var isEditingName   = false
    @State private var editedName      = ""
    @State private var isEditingHandle = false
    @State private var editedHandle    = ""
    @State private var isEditingBio    = false
    @State private var editedBio       = ""

    let streak: Int
    let momentum: Int
    let completedCount: Int
    let geo: GeometryProxy

    // MARK: Body
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                profileHero
                statsRow
                activityCard
                achievementsCard
                Spacer().frame(height: geo.safeAreaInsets.bottom + 140)
            }
            .padding(.top, geo.safeAreaInsets.top + 16)
        }
        .onAppear { loadSavedImage() }
        .onChange(of: selectedPhoto) { _, item in
            Task {
                guard let data = try? await item?.loadTransferable(type: Data.self),
                      let ui   = UIImage(data: data) else { return }
                profileImage = ui
                imgData = data
            }
        }
    }

    // MARK: Profile Hero
    private var profileHero: some View {
        VStack(spacing: 20) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Group {
                        if let img = profileImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                        } else {
                            ZStack {
                                LinearGradient(
                                    colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                                Text(String(userName.prefix(1)).uppercased())
                                    .font(.system(size: 44, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "#A78BFA"), Color(hex: "#8A4AF3").opacity(0.4)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 2.5
                            )
                    )
                    .shadow(color: Color(hex: "#8A4AF3").opacity(0.45), radius: 24, x: 0, y: 10)
                }

                // Camera badge
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 30, height: 30)
                        .overlay(Circle().stroke(Color(hex: "#0D0D10"), lineWidth: 2.5))
                    Image(systemName: "camera.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
            }

            // Name + handle + bio
            VStack(spacing: 6) {
                // Name
                if isEditingName {
                    TextField("Name", text: $editedName)
                        .font(.system(size: 24, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .submitLabel(.done)
                        .onSubmit { userName = editedName; isEditingName = false }
                } else {
                    Button { editedName = userName; isEditingName = true } label: {
                        HStack(spacing: 6) {
                            Text(userName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            Image(systemName: "pencil.line")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                }

                // Handle
                if isEditingHandle {
                    TextField("@handle", text: $editedHandle)
                        .font(.system(size: 14, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(hex: "#8A4AF3").opacity(0.8))
                        .submitLabel(.done)
                        .onSubmit { userHandle = editedHandle; isEditingHandle = false }
                } else {
                    Button { editedHandle = userHandle; isEditingHandle = true } label: {
                        Text(userHandle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#8A4AF3").opacity(0.8))
                    }
                }

                // Bio
                if isEditingBio {
                    TextField("Bio", text: $editedBio)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.55))
                        .submitLabel(.done)
                        .onSubmit { userBio = editedBio; isEditingBio = false }
                } else {
                    Button { editedBio = userBio; isEditingBio = true } label: {
                        Text(userBio)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.45))
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: Stats Row
    private var statsRow: some View {
        HStack(spacing: 10) {
            statTile(value: "\(streak)", label: "Day Streak", badge: "🔥")
            statTile(value: "\(completedCount)", label: "Completed", badge: "✅")
            statTile(value: "\(momentum)", label: "Momentum", badge: "⚡️")
        }
        .padding(.horizontal, 16)
    }

    private func statTile(value: String, label: String, badge: String) -> some View {
        VStack(spacing: 8) {
            Text(badge)
                .font(.system(size: 22))
            Text(value)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: "#1A1A1E"))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.07), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: Activity Card
    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Activity")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("Last 7 weeks")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.32))
            }

            StreakHeatmap(activeDays: min(streak, 49))
                .frame(maxWidth: .infinity, alignment: .center)

            // Legend
            HStack(spacing: 5) {
                Text("Less")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.28))
                ForEach([0.12, 0.35, 0.58, 0.8, 1.0], id: \.self) { op in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "#8A4AF3").opacity(op))
                        .frame(width: 9, height: 9)
                }
                Text("More")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.28))
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#1A1A1E"))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.07), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 16)
    }

    // MARK: Achievements
    private var achievementsCard: some View {
        let badges: [(String, String, Bool)] = [
            ("🔥", "On Fire",        streak >= 3),
            ("⚡️", "Week Warrior",  streak >= 7),
            ("💎", "Month Master",   streak >= 30),
            ("🚀", "High Momentum",  momentum >= 80),
            ("✅", "Task Crusher",   completedCount >= 10),
            ("🎯", "Perfectionist",  momentum == 100),
        ]

        return VStack(alignment: .leading, spacing: 14) {
            Text("Achievements")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(badges, id: \.1) { emoji, title, unlocked in
                    VStack(spacing: 8) {
                        Text(emoji)
                            .font(.system(size: 28))
                            .opacity(unlocked ? 1 : 0.2)
                            .grayscale(unlocked ? 0 : 1)
                        Text(title)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(unlocked ? .white.opacity(0.75) : .white.opacity(0.2))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(unlocked
                                  ? Color(hex: "#8A4AF3").opacity(0.12)
                                  : Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(unlocked
                                            ? Color(hex: "#8A4AF3").opacity(0.3)
                                            : Color.white.opacity(0.05), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#1A1A1E"))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.07), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 16)
    }

    // MARK: Helpers
    private func loadSavedImage() {
        guard !imgData.isEmpty, let ui = UIImage(data: imgData) else { return }
        profileImage = ui
    }
}
