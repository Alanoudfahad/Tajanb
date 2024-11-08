import SwiftUI

struct OnboardingView2: View {
    @Binding var hasSeenOnboarding: Bool
    @Binding var justCompletedOnboarding: Bool

    var body: some View {
        VStack {
            Spacer()

            Text("How it works")
                .font(.system(size: 25, weight: .bold))
                .foregroundColor(Color("TextColor"))
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 40)

            HStack(alignment: .top) {
                VStack {
                    ZStack {
                        Circle()
                            .fill(Color("GrayList"))
                            .frame(width: 45, height: 45)
                        Image(systemName: "doc.text.magnifyingglass")
                            .foregroundColor(Color("PrimeryButton"))
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
                            .foregroundColor(Color("PrimeryButton"))
                            .font(.system(size: 18.45))
                    }

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Ingredient Scanner")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Scan the product's ingredient and check its suitability for you. Make sure to capture all components to ensure accurate results.")
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
                        
                        Text("You can check for allergens by selecting an image from your camera roll to search for potentially harmful ingredients.")
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
                    
                    Spacer()
                    
               
                    
                    
                }
                .padding(.horizontal, 10)
                
                
            }
            .padding(.horizontal, 16)

            Spacer()
            
            // Disclaimer Text
            VStack(alignment: .leading) {
                Text("Disclaimer")
                    .foregroundColor(Color("TextColor"))
                    .font(.headline)
                    .bold()
                
                Text("The app is not responsible for failing to capture all components during scanning.")
                    .foregroundColor(Color("WhiteText"))
                    .lineSpacing(4)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)


            }
            .padding(.bottom, 20)
            .padding(.leading,20)

            
            
            
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
