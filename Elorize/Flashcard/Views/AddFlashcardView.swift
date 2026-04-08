import SwiftUI
import SwiftUI
import SwiftData
import PhotosUI

struct AddFlashCardView: View {

  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var homeViewModel: HomeViewModel
  
  @StateObject private var viewModel = AddFlashCardViewModel()
  @Query private var subjects: [SubjectEntity]
  
  var body: some View {
		NavigationStack {
			ZStack {
				BackgroundColorView()
				Form {
          Section {
            Toggle("Create new card upon save", isOn: $viewModel.keepAdding)
          }
					showSectionFrontText()
					showSectionBackText()
					showSectionTags()
					showSectionSubject()
				}
				.scrollContentBackground(.hidden)
				.listStyle(.plain)
				.textViewStyle(16)
			}
			.onAppear {
        viewModel.localSubjects = subjects
        viewModel.setRepository(FlashcardRepository(context: context))
        viewModel.loadSubjects(subjects, preferredID: homeViewModel.preselectedSubjectForAdd)
			}
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Close") { dismiss() }
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button("Save") {
            let succeeded = viewModel.save(keepOpen: viewModel.keepAdding, context: context)
            if succeeded {
              if !viewModel.keepAdding {
                homeViewModel.preselectedSubjectForAdd = nil
                dismiss()
              }
            }
          }
          .disabled(viewModel.front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    viewModel.back.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    viewModel.localSubjects.isEmpty)
        }
      }
      .fullScreenCover(isPresented: $viewModel.showingFrontCamera) {
        CameraPicker(imageData: $viewModel.frontImageData)
          .ignoresSafeArea()
      }
      .fullScreenCover(isPresented: $viewModel.showingBackCamera) {
        CameraPicker(imageData: $viewModel.backImageData)
          .ignoresSafeArea()
      }
		}
  }
}

private extension AddFlashCardView {
  
  @ViewBuilder
  func showSectionFrontText() -> some View {
    Section("Front") {
      ZStack(alignment: .topLeading) {
        if viewModel.front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          Text("e.g. hello")
            .foregroundStyle(.secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 8)
        }
        TextEditor(text: $viewModel.front)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .frame(minHeight: 80)
      }
      
      // Image picker for front
      if let imageData = viewModel.frontImageData, let uiImage = UIImage(data: imageData) {
        HStack {
          Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 150)
            .cornerRadius(8)
          Spacer()
          Button(role: .destructive) {
            viewModel.frontImageData = nil
          } label: {
            Image(systemName: "trash")
              .foregroundStyle(.red)
          }
        }
      }
      
      HStack {
        PhotosPicker(
          selection: $viewModel.frontImageSelection,
          matching: .images,
          photoLibrary: .shared()
        ) {
          Label("Choose from Library", systemImage: "photo.on.rectangle")
        }
        .buttonStyle(.borderless)
        
        Button {
          viewModel.showingFrontCamera = true
        } label: {
          Label("Take Photo", systemImage: "camera")
        }
        .buttonStyle(.borderless)
      }
      .onChange(of: viewModel.frontImageSelection) { _, newValue in
        Task {
          if let data = try? await newValue?.loadTransferable(type: Data.self) {
            viewModel.frontImageData = data
          }
        }
      }
    }
  }
  
  @ViewBuilder
  func showSectionBackText() -> some View {
    Section("Back") {
      ZStack(alignment: .topLeading) {
        if viewModel.back.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          Text("e.g. hola")
            .foregroundStyle(.secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 8)
        }
        TextEditor(text: $viewModel.back)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .frame(minHeight: 80)
      }
      
      // Image picker for back
      if let imageData = viewModel.backImageData, let uiImage = UIImage(data: imageData) {
        HStack {
          Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 150)
            .cornerRadius(8)
          Spacer()
          Button(role: .destructive) {
            viewModel.backImageData = nil
          } label: {
            Image(systemName: "trash")
              .foregroundStyle(.red)
          }
        }
      }
      
      HStack {
        PhotosPicker(
          selection: $viewModel.backImageSelection,
          matching: .images,
          photoLibrary: .shared()
        ) {
          Label("Choose from Library", systemImage: "photo.on.rectangle")
        }
        .buttonStyle(.borderless)
        
        Button {
          viewModel.showingBackCamera = true
        } label: {
          Label("Take Photo", systemImage: "camera")
        }
        .buttonStyle(.borderless)
      }
      .onChange(of: viewModel.backImageSelection) { _, newValue in
        Task {
          if let data = try? await newValue?.loadTransferable(type: Data.self) {
            viewModel.backImageData = data
          }
        }
      }
    }
  }
  
  @ViewBuilder
  func showSectionSubject() -> some View {
    Section("Subject/Category") {
      if viewModel.localSubjects.isEmpty {
        Button {
          viewModel.showingNewSubjectPrompt = true
        } label: {
          Label("Create new subject/category…", systemImage: "folder.badge.plus")
        }
        .buttonStyle(.borderless)
        .font(.body)
      } else {
        Picker("Subject/Category", selection: Binding(get: { viewModel.selectedSubjectID ?? viewModel.localSubjects.first?.id ?? UUID() }, set: { viewModel.selectedSubjectID = $0 })) {
          ForEach(viewModel.localSubjects) { subject in
            Text(subject.name).tag(subject.id)
          }
        }
        Button {
          viewModel.showingNewSubjectPrompt = true
        } label: {
          Label("+ New subject/category…", systemImage: "folder.badge.plus")
        }
        .buttonStyle(.borderless)
      }
    }
    .alert("New subject/category", isPresented: $viewModel.showingNewSubjectPrompt) {
      TextField("Name", text: $viewModel.newSubjectName)
      Button("Create") { viewModel.createSubject() }
      Button("Cancel", role: .cancel) { viewModel.newSubjectName = "" }
    } message: {
      Text("Enter a name for the new subject/category.")
    }
  }
  
  @ViewBuilder
  func showSectionTags() -> some View {
    Section("Tags") {
      TextField("Comma-separated (e.g. greeting, spanish)", text: $viewModel.tagsText)
    }
  }
}

// MARK: - Camera Picker

struct CameraPicker: UIViewControllerRepresentable {
  @Binding var imageData: Data?
  @Environment(\.dismiss) private var dismiss
  
  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    
    // Check if camera is available
    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
      // If camera not available, dismiss immediately
      DispatchQueue.main.async {
        dismiss()
      }
      return picker
    }
    
    picker.sourceType = .camera
    picker.cameraCaptureMode = .photo
    picker.cameraDevice = .rear
    picker.showsCameraControls = true
    picker.allowsEditing = false
    picker.delegate = context.coordinator
    
    return picker
  }
  
  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let parent: CameraPicker
    
    init(_ parent: CameraPicker) {
      self.parent = parent
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
      // Dismiss picker first
      picker.dismiss(animated: true) {
        // Then process image
        if let image = info[.originalImage] as? UIImage {
          // Compress image to reduce size
          self.parent.imageData = image.jpegData(compressionQuality: 0.8)
        }
        // Finally dismiss the fullScreenCover
        self.parent.dismiss()
      }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      // Dismiss picker first, then the cover
      picker.dismiss(animated: true) {
        self.parent.dismiss()
      }
    }
  }
}


