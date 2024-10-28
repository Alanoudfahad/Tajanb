import SwiftUI

struct OnboardingView2: View {
    @Binding var hasSeenOnboarding: Bool
    @Binding var justCompletedOnboarding: Bool

    var body: some View {
        VStack {
            Spacer()

            Text("How it works")
                .font(.system(size: 25, weight: .bold))
                .foregroundColor(Color("CustomGreen"))
                .padding(.bottom, 20)

            HStack(alignment: .top) {
                VStack {
                    ZStack {
                        Circle()
                            .fill(Color("GrayList"))
                            .frame(width: 45, height: 45)
                        Image(systemName: "doc.text.magnifyingglass")
                            .foregroundColor(Color("CustomGreen"))
                            .font(.system(size: 18.57))
                    }

                    Rectangle()
                        .fill(Color("textGray"))
                        .frame(width: 2, height: 200)
                        .padding(.vertical, 5)

                    ZStack {
                        Circle()
                            .fill(Color("GrayList"))
                            .frame(width: 45, height: 45)
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Color("CustomGreen"))
                            .font(.system(size: 18.45))
                    }

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Ingredient Scanner")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Scan a list of ingredients product, and find out if it is suitable for you.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Image("PhotoScan")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 150)
                            .cornerRadius(10)
                            .clipped()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Upload Photo")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Check for allergens in your photos by selecting an image from your camera roll to scan for potentially harmful ingredients.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Image("UploadPhoto")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 150)
                            .cornerRadius(10)
                            .clipped()
                    }
                }
                .padding(.horizontal, 10)
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .background(Color("CustomBackground").edgesIgnoringSafeArea(.all))
    }
}

// Preview for testing
#Preview {
    OnboardingView2(
        hasSeenOnboarding: .constant(true),
        justCompletedOnboarding: .constant(false)
    )
}
