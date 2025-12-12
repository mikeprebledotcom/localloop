import Foundation
import GoogleSignIn
import GoogleAPIClientForREST_Drive

class GoogleDriveService: ObservableObject {
    static let shared = GoogleDriveService()

    @Published var isSignedIn = false
    @Published var userEmail: String?
    @Published var targetFolderId: String?

    private let driveService = GTLRDriveService()

    private init() {
        restorePreviousSignIn()
    }

    // MARK: - Authentication

    func signIn(presenting: UIViewController) async throws {
        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: presenting,
            hint: nil,
            additionalScopes: ["https://www.googleapis.com/auth/drive.file"]
        )

        configureService(with: result.user)
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isSignedIn = false
        userEmail = nil
    }

    private func restorePreviousSignIn() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            if let user {
                self?.configureService(with: user)
            }
        }
    }

    private func configureService(with user: GIDGoogleUser) {
        driveService.authorizer = user.fetcherAuthorizer
        isSignedIn = true
        userEmail = user.profile?.email

        // Load saved folder ID
        targetFolderId = UserDefaults.standard.string(forKey: "driveFolderId")
    }

    // MARK: - Folder Selection

    func setTargetFolder(id: String, name: String) {
        targetFolderId = id
        UserDefaults.standard.set(id, forKey: "driveFolderId")
        UserDefaults.standard.set(name, forKey: "driveFolderName")
    }

    func getTargetFolderName() -> String? {
        UserDefaults.standard.string(forKey: "driveFolderName")
    }

    // MARK: - Upload

    func uploadFile(at localURL: URL, filename: String) async throws -> String {
        guard let folderId = targetFolderId else {
            throw GoogleDriveError.noFolderSelected
        }

        // Create file metadata
        let metadata = GTLRDrive_File()
        metadata.name = filename
        metadata.parents = [folderId]

        // Read file data
        let data = try Data(contentsOf: localURL)
        let uploadParameters = GTLRUploadParameters(data: data, mimeType: "audio/mp4")

        // Create upload query
        let query = GTLRDriveQuery_FilesCreate.query(withObject: metadata, uploadParameters: uploadParameters)
        query.fields = "id, name"

        // Execute upload
        return try await withCheckedThrowingContinuation { continuation in
            driveService.executeQuery(query) { _, file, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let file = file as? GTLRDrive_File, let fileId = file.identifier {
                    continuation.resume(returning: fileId)
                } else {
                    continuation.resume(throwing: GoogleDriveError.uploadFailed)
                }
            }
        }
    }

    // MARK: - Folder Listing (for picker)

    func listFolders() async throws -> [DriveFolder] {
        let query = GTLRDriveQuery_FilesList.query()
        query.q = "mimeType='application/vnd.google-apps.folder' and trashed=false"
        query.fields = "files(id, name)"
        query.pageSize = 100

        return try await withCheckedThrowingContinuation { continuation in
            driveService.executeQuery(query) { _, result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let fileList = result as? GTLRDrive_FileList {
                    let folders = (fileList.files ?? []).compactMap { file -> DriveFolder? in
                        guard let id = file.identifier, let name = file.name else { return nil }
                        return DriveFolder(id: id, name: name)
                    }
                    continuation.resume(returning: folders)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }
}

struct DriveFolder: Identifiable {
    let id: String
    let name: String
}

enum GoogleDriveError: LocalizedError {
    case noFolderSelected
    case uploadFailed
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .noFolderSelected: return "No Google Drive folder selected"
        case .uploadFailed: return "Upload failed"
        case .notSignedIn: return "Not signed in to Google"
        }
    }
}
