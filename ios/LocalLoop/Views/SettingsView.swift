import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel.shared
    @StateObject private var driveService = GoogleDriveService.shared
    @State private var showFolderPicker = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Google Drive Section
                Section("Google Drive") {
                    if driveService.isSignedIn {
                        HStack {
                            Text("Signed in as")
                            Spacer()
                            Text(driveService.userEmail ?? "Unknown")
                                .foregroundStyle(.secondary)
                        }

                        Button("Sign Out") {
                            driveService.signOut()
                        }
                        .foregroundStyle(.red)

                        // Folder selection
                        Button {
                            showFolderPicker = true
                        } label: {
                            HStack {
                                Text("Upload Folder")
                                Spacer()
                                Text(driveService.getTargetFolderName() ?? "Not selected")
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)
                    } else {
                        Button("Sign in with Google") {
                            Task {
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let rootVC = windowScene.windows.first?.rootViewController {
                                    try? await driveService.signIn(presenting: rootVC)
                                }
                            }
                        }
                    }
                }

                // Upload Settings
                Section("Upload") {
                    Toggle("Wi-Fi only", isOn: $viewModel.wifiOnly)
                    Toggle("Require charging", isOn: $viewModel.requireCharging)

                    Picker("Upload mode", selection: $viewModel.uploadMode) {
                        Text("Batch (on Wi-Fi)").tag(UploadMode.batch)
                        Text("Immediate").tag(UploadMode.immediate)
                    }
                }

                // Recording Settings
                Section("Recording") {
                    Picker("Chunk duration", selection: $viewModel.chunkDuration) {
                        Text("5 minutes").tag(300)
                        Text("10 minutes").tag(600)
                        Text("15 minutes").tag(900)
                    }
                }

                // Stats
                Section("Statistics") {
                    HStack {
                        Text("Pending uploads")
                        Spacer()
                        Text("\(ChunkManager.shared.pendingChunks.count)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Total uploaded")
                        Spacer()
                        Text("\(ChunkManager.shared.uploadedChunks.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showFolderPicker) {
                FolderPickerView()
            }
        }
    }
}

struct FolderPickerView: View {
    @StateObject private var driveService = GoogleDriveService.shared
    @State private var folders: [DriveFolder] = []
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading folders...")
                } else if folders.isEmpty {
                    ContentUnavailableView("No Folders", systemImage: "folder")
                } else {
                    List(folders) { folder in
                        Button {
                            driveService.setTargetFolder(id: folder.id, name: folder.name)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "folder")
                                Text(folder.name)
                                Spacer()
                                if driveService.targetFolderId == folder.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("Select Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                do {
                    folders = try await driveService.listFolders()
                } catch {
                    print("Failed to load folders: \(error)")
                }
                isLoading = false
            }
        }
    }
}

#Preview {
    SettingsView()
}
