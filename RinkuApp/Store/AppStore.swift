import Foundation
import SwiftUI
internal import Combine

@MainActor
final class AppStore: ObservableObject {
    static let shared = AppStore()

    @Published var lovedOnes: [LovedOne] = []
    @Published var permissions = PermissionState()
    @Published var recognitionState = RecognitionState()
    @Published var recognizedPerson: LovedOne? = nil
    @Published var isSyncing = false
    @Published var syncError: String?

    private let storageKey = "loved_ones_data"
    private let authService = AuthService.shared
    private let supabaseService = SupabaseService.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadLovedOnes()
        setupAuthObserver()
    }
    
    // MARK: - Auth Observer
    
    private func setupAuthObserver() {
        // Watch for auth state changes
        authService.$isSignedIn
            .dropFirst() // Skip initial value
            .sink { [weak self] isSignedIn in
                Task { @MainActor in
                    if isSignedIn {
                        await self?.syncWithSupabase()
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Local Persistence

    private func loadLovedOnes() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([LovedOne].self, from: data) else {
            // Load sample data if nothing saved
            lovedOnes = [
                LovedOne(
                    id: "1",
                    fullName: "Gabriela Martinez",
                    familiarName: "Gabi",
                    relationship: "Daughter",
                    memoryPrompt: "She loves painting and always brings flowers on Sundays.",
                    enrolled: false,
                    photoFileNames: []
                ),
                LovedOne(
                    id: "2",
                    fullName: "Michael Chen",
                    familiarName: "Mike",
                    relationship: "Son",
                    memoryPrompt: "He works as a teacher and visits every Wednesday.",
                    enrolled: false,
                    photoFileNames: []
                )
            ]
            return
        }
        lovedOnes = decoded
    }

    private func saveLovedOnes() {
        if let data = try? JSONEncoder().encode(lovedOnes) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    // MARK: - Supabase Sync
    
    /// Sync data with Supabase (fetch remote data, download photos, and merge)
    func syncWithSupabase() async {
        guard authService.isSignedIn else { return }
        
        isSyncing = true
        syncError = nil
        
        do {
            // Fetch loved ones from Supabase
            let remoteLovedOnes = try await supabaseService.fetchLovedOnes()
            
            // Process each remote loved one
            var mergedLovedOnes: [LovedOne] = []
            
            for dto in remoteLovedOnes {
                let lovedOneId = dto.id ?? ""
                
                // Check if we have local photos for this person
                var localPhotoFileNames = lovedOnes.first { $0.id == lovedOneId }?.photoFileNames ?? []
                
                // Fetch photo records from Supabase
                if let photos = try? await supabaseService.fetchPhotos(forLovedOneId: lovedOneId) {
                    // Download any photos we don't have locally
                    for photo in photos {
                        let localFileName = "\(lovedOneId)_\(photo.fileName)"
                        
                        // Check if we already have this photo locally
                        let exists = await PhotoStorage.shared.photoExists(fileName: localFileName)
                        
                        if !exists {
                            // Download and save locally
                            do {
                                let image = try await supabaseService.downloadPhoto(storagePath: photo.storagePath)
                                let savedFileName = try await PhotoStorage.shared.savePhoto(image, forPersonId: lovedOneId)
                                if !localPhotoFileNames.contains(savedFileName) {
                                    localPhotoFileNames.append(savedFileName)
                                }
                                print("Downloaded photo: \(photo.fileName)")
                            } catch {
                                print("Failed to download photo \(photo.fileName): \(error)")
                            }
                        } else if !localPhotoFileNames.contains(localFileName) {
                            localPhotoFileNames.append(localFileName)
                        }
                    }
                }
                
                let lovedOne = dto.toLovedOne(photoFileNames: localPhotoFileNames)
                mergedLovedOnes.append(lovedOne)
            }
            
            // Handle local-only entries (upload them to Supabase)
            for local in lovedOnes {
                if !mergedLovedOnes.contains(where: { $0.id == local.id }) {
                    // This is a local-only entry, upload it to Supabase
                    let dto = LovedOneDTO.from(local)
                    if let created = try? await supabaseService.createLovedOne(dto) {
                        var updatedLocal = local
                        updatedLocal.id = created.id ?? local.id
                        mergedLovedOnes.append(updatedLocal)
                        
                        // Also upload the photos for this local entry
                        for fileName in local.photoFileNames {
                            if let image = await PhotoStorage.shared.loadPhoto(fileName: fileName) {
                                _ = try? await supabaseService.uploadPhoto(image: image, lovedOneId: updatedLocal.id)
                            }
                        }
                    }
                }
            }
            
            lovedOnes = mergedLovedOnes
            saveLovedOnes()
            isSyncing = false
            
            print("Sync complete: \(lovedOnes.count) loved ones")
        } catch {
            syncError = error.localizedDescription
            isSyncing = false
            print("Sync error: \(error)")
        }
    }
    
    /// Upload a loved one to Supabase
    private func uploadToSupabase(_ lovedOne: LovedOne) async {
        guard authService.isSignedIn else { return }
        
        do {
            let dto = LovedOneDTO.from(lovedOne)
            _ = try await supabaseService.createLovedOne(dto)
        } catch {
            print("Failed to upload to Supabase: \(error)")
        }
    }
    
    /// Update loved one in Supabase
    private func updateInSupabase(_ lovedOne: LovedOne) async {
        guard authService.isSignedIn else { return }
        
        do {
            let dto = LovedOneDTO.from(lovedOne)
            try await supabaseService.updateLovedOne(dto)
        } catch {
            print("Failed to update in Supabase: \(error)")
        }
    }
    
    /// Delete loved one from Supabase
    private func deleteFromSupabase(id: String) async {
        guard authService.isSignedIn else { return }
        
        do {
            try await supabaseService.deleteLovedOne(id: id)
        } catch {
            print("Failed to delete from Supabase: \(error)")
        }
    }

    // MARK: - Loved Ones Management

    /// Add a loved one with photos (new flow)
    func addLovedOne(
        id: String = UUID().uuidString,
        fullName: String,
        familiarName: String?,
        relationship: String,
        memoryPrompt: String?,
        photoFileNames: [String] = [],
        enrolled: Bool = false
    ) {
        let newPerson = LovedOne(
            id: id,
            fullName: fullName,
            familiarName: familiarName?.isEmpty == true ? nil : familiarName,
            relationship: relationship,
            memoryPrompt: memoryPrompt?.isEmpty == true ? nil : memoryPrompt,
            enrolled: enrolled,
            photoFileNames: photoFileNames
        )
        lovedOnes.append(newPerson)
        saveLovedOnes()
        
        // Sync to Supabase
        Task {
            await uploadToSupabase(newPerson)
        }
    }

    func getLovedOne(byId id: String) -> LovedOne? {
        lovedOnes.first { $0.id == id }
    }

    func updateLovedOne(_ lovedOne: LovedOne) {
        if let index = lovedOnes.firstIndex(where: { $0.id == lovedOne.id }) {
            lovedOnes[index] = lovedOne
            saveLovedOnes()
            
            // Sync to Supabase
            Task {
                await updateInSupabase(lovedOne)
            }
        }
    }

    func deleteLovedOne(id: String) {
        lovedOnes.removeAll { $0.id == id }
        saveLovedOnes()

        // Delete from Supabase
        Task {
            await deleteFromSupabase(id: id)
        }
        
        // Also delete local photos
        Task {
            await PhotoStorage.shared.deleteAllPhotos(forPersonId: id)
        }
    }

    func enrollPerson(id: String) {
        if let index = lovedOnes.firstIndex(where: { $0.id == id }) {
            lovedOnes[index].enrolled = true
            saveLovedOnes()
            
            // Sync to Supabase
            Task {
                await updateInSupabase(lovedOnes[index])
            }
        }
    }

    func addPhotos(toPersonId id: String, fileNames: [String]) {
        if let index = lovedOnes.firstIndex(where: { $0.id == id }) {
            lovedOnes[index].photoFileNames.append(contentsOf: fileNames)
            saveLovedOnes()
            // Note: Photos are stored locally, not synced to Supabase storage yet
        }
    }

    // MARK: - Permissions

    func grantPermission(_ type: PermissionType) {
        switch type {
        case .camera:
            permissions.camera = true
        case .microphone:
            permissions.microphone = true
        }
    }

    var hasAllPermissions: Bool {
        permissions.allGranted
    }

    // MARK: - Recognition

    func setRecognizedPerson(_ person: LovedOne?) {
        recognizedPerson = person
    }
}

enum PermissionType {
    case camera
    case microphone
}
