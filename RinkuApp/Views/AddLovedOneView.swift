import SwiftUI
import PhotosUI

struct AddLovedOneView: View {
    @ObservedObject var store: AppStore
    @Binding var selectedTab: TabItem
    @ObservedObject private var languageManager = LanguageManager.shared

    @State private var fullName = ""
    @State private var familiarName = ""
    @State private var relationship = ""
    @State private var memoryPrompt = ""

    @State private var fullNameError: String? = nil
    @State private var relationshipError: String? = nil

    @State private var fullNameTouched = false
    @State private var relationshipTouched = false

    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastType = .success

    // Photo picker state
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isProcessingPhotos = false
    @State private var photoError: String? = nil

    private var isFormValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !relationship.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedImages.isEmpty
    }

    private func validate() -> Bool {
        var valid = true

        if fullName.trimmingCharacters(in: .whitespaces).isEmpty {
            fullNameError = "Full name is required"
            valid = false
        } else {
            fullNameError = nil
        }

        if relationship.trimmingCharacters(in: .whitespaces).isEmpty {
            relationshipError = "Relationship is required"
            valid = false
        } else {
            relationshipError = nil
        }

        if selectedImages.isEmpty {
            photoError = "At least one photo is required"
            valid = false
        } else {
            photoError = nil
        }

        return valid
    }

    private func handleSubmit() {
        fullNameTouched = true
        relationshipTouched = true

        if validate() {
            isProcessingPhotos = true

            Task {
                await saveLovedOneWithPhotos()
            }
        }
    }

    private func saveLovedOneWithPhotos() async {
        let personId = UUID().uuidString
        let authService = AuthService.shared
        let supabaseService = SupabaseService.shared

        do {
            // Save photos to local storage first (for fast local access)
            let fileNames = try await PhotoStorage.shared.savePhotos(selectedImages, forPersonId: personId)

            // Verify faces exist in photos using AWS (if configured)
            var validPhotoCount = fileNames.count
            if AWSConfig.isConfigured {
                validPhotoCount = 0
                for fileName in fileNames {
                    if let image = await PhotoStorage.shared.loadPhoto(fileName: fileName) {
                        do {
                            let hasFace = try await AWSRekognitionService.shared.detectFace(in: image)
                            if hasFace {
                                validPhotoCount += 1
                            }
                        } catch {
                            print("Face detection check failed: \(error)")
                            // Still count it if we can't verify
                            validPhotoCount += 1
                        }
                    }
                }
            }

            // Add loved one to store (this also syncs metadata to Supabase)
            await MainActor.run {
                store.addLovedOne(
                    id: personId,
                    fullName: fullName.trimmingCharacters(in: .whitespaces),
                    familiarName: familiarName.isEmpty ? nil : familiarName.trimmingCharacters(in: .whitespaces),
                    relationship: relationship.trimmingCharacters(in: .whitespaces),
                    memoryPrompt: memoryPrompt.isEmpty ? nil : memoryPrompt.trimmingCharacters(in: .whitespaces),
                    photoFileNames: fileNames,
                    enrolled: validPhotoCount > 0
                )
            }
            
            // Upload photos to Supabase Storage if signed in
            if authService.isSignedIn {
                var uploadedCount = 0
                for image in selectedImages {
                    do {
                        _ = try await supabaseService.uploadPhoto(image: image, lovedOneId: personId)
                        uploadedCount += 1
                    } catch {
                        print("Failed to upload photo to Supabase: \(error)")
                    }
                }
                print("Uploaded \(uploadedCount) photos to Supabase")
            }

            await MainActor.run {
                isProcessingPhotos = false

                if AWSConfig.isConfigured {
                    let syncMsg = authService.isSignedIn ? " (synced to cloud)" : ""
                    toastMessage = "Added with \(validPhotoCount) photo(s) ready for recognition!\(syncMsg)"
                    toastType = .success
                } else {
                    toastMessage = "Added! Configure AWS credentials to enable face recognition."
                    toastType = .info
                }
                showToast = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    selectedTab = .lovedOnes
                    resetForm()
                }
            }
        } catch {
            await MainActor.run {
                isProcessingPhotos = false
                toastMessage = "Failed to save photos: \(error.localizedDescription)"
                toastType = .error
                showToast = true
            }
        }
    }

    private func resetForm() {
        fullName = ""
        familiarName = ""
        relationship = ""
        memoryPrompt = ""
        fullNameError = nil
        relationshipError = nil
        photoError = nil
        fullNameTouched = false
        relationshipTouched = false
        showToast = false
        selectedItems = []
        selectedImages = []
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("add_loved_one_title".localized)
                            .font(.system(size: Theme.FontSize.h1, weight: .bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        Spacer()
                    }

                    // Photo Picker Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("add_loved_one_photos".localized)
                                .font(.system(size: Theme.FontSize.body, weight: .medium))
                                .foregroundColor(Theme.Colors.textPrimary)

                            Text("*")
                                .foregroundColor(Theme.Colors.danger)

                            Spacer()

                            Text("\(selectedImages.count) selected")
                                .font(.system(size: Theme.FontSize.caption))
                                .foregroundColor(Theme.Colors.textSecondary)
                        }

                        // Photo Grid
                        if !selectedImages.isEmpty {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 100)
                                            .clipped()
                                            .cornerRadius(8)

                                        // Remove button
                                        Button {
                                            selectedImages.remove(at: index)
                                            if index < selectedItems.count {
                                                selectedItems.remove(at: index)
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.white)
                                                .shadow(radius: 2)
                                        }
                                        .padding(4)
                                    }
                                }
                            }
                        }

                        // Photo Picker Button
                        PhotosPicker(
                            selection: $selectedItems,
                            maxSelectionCount: 10,
                            matching: .images
                        ) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text(selectedImages.isEmpty ? "add_loved_one_add_photos".localized : "add_loved_one_add_photos".localized)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.Colors.primaryLight)
                            .foregroundColor(Theme.Colors.primary)
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                        .onChange(of: selectedItems) { _, newItems in
                            Task {
                                await loadSelectedPhotos(newItems)
                            }
                        }

                        if let error = photoError {
                            Text(error)
                                .font(.system(size: Theme.FontSize.caption))
                                .foregroundColor(Theme.Colors.danger)
                        }

                        Text("Add clear photos of their face for better recognition. Multiple photos from different angles work best.")
                            .font(.system(size: Theme.FontSize.caption))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(Theme.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .stroke(photoError != nil ? Theme.Colors.danger : Theme.Colors.border, lineWidth: 1)
                    )

                    // Form
                    VStack(spacing: 20) {
                        RinkuTextField(
                            label: "add_loved_one_full_name".localized,
                            text: $fullName,
                            placeholder: "add_loved_one_full_name_placeholder".localized,
                            errorText: fullNameTouched ? fullNameError : nil,
                            isRequired: true
                        )
                        .onChange(of: fullName) { _, _ in
                            if fullNameTouched { _ = validate() }
                        }

                        RinkuTextField(
                            label: "add_loved_one_familiar_name".localized,
                            text: $familiarName,
                            placeholder: "add_loved_one_familiar_name_placeholder".localized
                        )

                        RinkuTextField(
                            label: "add_loved_one_relationship".localized,
                            text: $relationship,
                            placeholder: "add_loved_one_relationship_placeholder".localized,
                            errorText: relationshipTouched ? relationshipError : nil,
                            isRequired: true
                        )
                        .onChange(of: relationship) { _, _ in
                            if relationshipTouched { _ = validate() }
                        }

                        RinkuTextField(
                            label: "add_loved_one_memory_prompt".localized,
                            text: $memoryPrompt,
                            placeholder: "add_loved_one_memory_prompt_placeholder".localized,
                            isMultiline: true
                        )
                    }

                    // Actions
                    VStack(spacing: 12) {
                        RinkuButton(
                            title: "action_save".localized,
                            variant: .primary,
                            size: .large,
                            isLoading: isProcessingPhotos,
                            isDisabled: !isFormValid
                        ) {
                            handleSubmit()
                        }

                        RinkuButton(
                            title: "action_cancel".localized,
                            variant: .secondary,
                            size: .large,
                            isDisabled: isProcessingPhotos
                        ) {
                            selectedTab = .lovedOnes
                            resetForm()
                        }
                    }
                    .padding(.top, 16)

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 32)
            }
            .background(Theme.Colors.background)

            // Toast
            if showToast {
                ToastContainer {
                    ToastView(
                        type: toastType,
                        message: toastMessage
                    ) {
                        showToast = false
                    }
                }
            }
        }
        .id(languageManager.currentLanguage) // Force refresh when language changes
    }

    private func loadSelectedPhotos(_ items: [PhotosPickerItem]) async {
        var images: [UIImage] = []

        for item in items {
            if let image = await UIImage.from(item) {
                images.append(image)
            }
        }

        await MainActor.run {
            selectedImages = images
            if !images.isEmpty {
                photoError = nil
            }
        }
    }
}

#Preview {
    AddLovedOneView(store: AppStore.shared, selectedTab: .constant(.add))
}
