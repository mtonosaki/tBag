//
//  IconView.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2026-02-07.
//

import SwiftUI
import PhotosUI
import Tono
import ImageIO

struct IconEditView: View {
    @Bindable var item: Item

    @Environment(\.displayToast) var toast
    
    @State private var selectedPhotoPickerItem: PhotosPickerItem?
    @State private var icon: Image = Image(.no)

    init(_ item: Item) {
        self.item = item
    }

    var body: some View {
        PhotosPicker(selection: $selectedPhotoPickerItem, matching: .images) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .onChange(of: selectedPhotoPickerItem) { _, newItem in
            Task {
                await saveIconToLocal(from: newItem)
            }
        }
        .onAppear {
            guard let iconFileName = item.iconFileName else { return }
            if let image = LocalImageStore.loadImage(folder: .icons, fileName: iconFileName) {
                self.icon = image
            }
        }
    }
    
    @MainActor
    func saveIconToLocal(from photoItem: PhotosPickerItem?) async {
        guard let photoItem else { return }
        
        do {
            guard let originalImageData = try await photoItem.loadTransferable(type: Data.self)  else { return }
            var originalImage: Image?
#if os(macOS)
            if let nsImage = NSImage(data: originalImageData) {
                originalImage = Image(nsImage: nsImage)
            }
#else
            if let uiImage = UIImage(data: originalImageData) {
                originalImage = Image(uiImage: uiImage)
            }
#endif
            guard let originalImage else { return }
            
            let image = ImageUtil.resizeImage(originalImage, maxPixel: 96)
            guard let resizedImage = image?.image else { return }
            guard let resizedImageData = image?.data else { return }
            self.icon = resizedImage
            
            let normalizedImage: Image
            if let source = CGImageSourceCreateWithData(originalImageData as CFData, nil),
               let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
                normalizedImage = Image(decorative: cgImage, scale: 1.0)
            } else {
                normalizedImage = originalImage
            }
            
            let imageHash = ImageHash.computeHashCode(normalizedImage)
            let fileName = "\(imageHash).png"
            
#if os(iOS)
            print("--- iOS 　: saving : icon filename = \(fileName)")
#else
            print("--- macOS: saving : icon filename = \(fileName)")
#endif
            
            LocalImageStore.save(data: resizedImageData, folder: .icons, fileName: fileName)
            item.iconFileName = fileName
        } catch {
            toast?("Failed to set image: \(error.localizedDescription)")
        }
    }
}
