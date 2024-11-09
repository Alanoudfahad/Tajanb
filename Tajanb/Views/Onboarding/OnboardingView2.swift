import SwiftUI

struct OnboardingView2: View {
    @Binding var hasSeenOnboarding: Bool
    @Binding var justCompletedOnboarding: Bool
    // Create a computed property for the styled disclaimer text
       var disclaimerText: AttributedString {
           var attributedText = AttributedString(NSLocalizedString("Disclaimer: The app is not responsible for failing to capture all components during scanning.", comment: ""))
           
           // Apply styling to the word "Disclaimer"
           if let range = attributedText.range(of: NSLocalizedString("Disclaimer", comment: "")) {
               attributedText[range].foregroundColor = Color("TextColor")  // Apply custom color
               attributedText[range].underlineStyle = .single  // Underline the word
           }
           
           return attributedText
       }

    var body: some View {
        VStack {
            Spacer()

            Text("How it works")
                .font(.system(size: 26, weight: .bold))
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
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.bottom,2)
                        Text("Scan the product's ingredient and check its suitability for you. Make sure to capture all components to ensure accurate results.")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom,4)
                        Image("PhotoScan")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 150)
                            .cornerRadius(10)
                            .clipped()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Upload Photo")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.bottom,2)
                        
                        Text("You can check for allergens by selecting an image from your camera roll to search for potentially harmful ingredients.")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom,4)
                        
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
            
        // Disclaimer Text
                      VStack(alignment: .leading) {
                          // Use the computed property for the attributed text
                          Text(disclaimerText)
                              .foregroundColor(Color("WhiteText"))
                              .font(.system(size: 16))
                              .lineSpacing(4)
                              .multilineTextAlignment(.leading)
                              .fixedSize(horizontal: false, vertical: true)
                              .padding(.bottom, 20)
                              .padding(.leading, 20)
                      }
                      .padding()
            
            
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
