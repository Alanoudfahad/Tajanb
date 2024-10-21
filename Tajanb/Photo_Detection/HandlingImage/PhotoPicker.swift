import SwiftUI
import Photos

struct PhotoPicker: View {
    @State private var photos: [PHAsset] = []
    @State private var selectedImage: UIImage?
    
    var body: some View {
        VStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .padding()
            }
            Button("Load Photos") {
                loadPhotos()
            }
            .padding()
            
            // Display photos in a grid
            GridView(photos: photos, onPhotoSelect: { asset in
                loadImage(asset: asset) { image in
                    selectedImage = image
                }
            })
        }
        .onAppear {
            requestAuthorization()
        }
    }
    
    // Request authorization to access photo library
    private func requestAuthorization() {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                loadPhotos()
            }
        }
    }

    // Fetch photos from the library
    private func loadPhotos() {
        DispatchQueue.global(qos: .userInitiated).async {
            let fetchedPhotos = fetchPhotos()
            DispatchQueue.main.async {
                self.photos = fetchedPhotos
            }
        }
    }

    // Fetch PHAssets
    private func fetchPhotos() -> [PHAsset] {
        var assets: [PHAsset] = []
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        fetchResult.enumerateObjects { (asset, _, _) in
            assets.append(asset)
        }
        
        return assets
    }

    // Load image from PHAsset
    private func loadImage(asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true

        imageManager.requestImage(for: asset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFill, options: requestOptions) { (image, _) in
            completion(image)
        }
    }
}

// GridView to display photos in a grid layout
struct GridView: View {
    let photos: [PHAsset]
    let onPhotoSelect: (PHAsset) -> Void
    
    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
        
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(photos, id: \.self) { asset in
                PhotoThumbnail(asset: asset, onPhotoSelect: onPhotoSelect)
            }
        }
        .padding()
    }
}

// PhotoThumbnail to represent each photo in the grid
struct PhotoThumbnail: View {
    let asset: PHAsset
    let onPhotoSelect: (PHAsset) -> Void
    @State private var image: UIImage?
    
    var body: some View {
        Button(action: {
            onPhotoSelect(asset)
        }) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 100)
                    .clipped()
            } else {
                Color.gray // Placeholder while loading
                    .frame(height: 100)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true

        imageManager.requestImage(for: asset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFill, options: requestOptions) { (uiImage, _) in
            self.image = uiImage
        }
    }
}

// Main App Entry Point
@main
struct PhotoPickerApp: App {
    var body: some Scene {
        WindowGroup {
            PhotoPicker()
        }
    }
}
