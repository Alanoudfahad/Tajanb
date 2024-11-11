import SwiftUI

struct OnboardingContainerView: View {
    @Binding var hasSeenOnboarding: Bool
    @Binding var justCompletedOnboarding: Bool
    @State private var currentIndex = 0 // Track the current onboarding index
    @ObservedObject var cameraViewModel: CameraViewModel
    
    var body: some View {
        VStack {
            // Custom progress indicator
            HStack(alignment: .center) {
                HStack {
                    Capsule()
                        .fill(currentIndex == 0 ? Color("PrimeryButton") : Color("SecondaryButton"))
                        .frame(width: 30, height: 4)
                    Capsule()
                        .fill(currentIndex == 1 ? Color("PrimeryButton") : Color("SecondaryButton"))
                        .frame(width: 30, height: 4)
                    Capsule()
                        .fill(currentIndex == 2 ? Color("PrimeryButton") : Color("SecondaryButton"))
                        .frame(width: 30, height: 4)
                }
                .padding(.leading, 140.0)
                .padding(.top)
                
                Spacer()

                // Show Skip button or placeholder to keep layout consistent
                if currentIndex < 2 {
                    Button(action: {
                        currentIndex = 2
                    }) {
                        Text("Skip")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color("PrimeryButton"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .cornerRadius(10)
                    }
                    .padding(.trailing, 20)
                    .padding(.top)
                } else {
                    // Placeholder to keep alignment consistent
                    Text("Skip")
                        .font(.headline)
                        .foregroundColor(Color.clear)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .cornerRadius(10)
                        .padding(.trailing, 20)
                        .padding(.top)
                }
                
            }
            
            TabView(selection: $currentIndex) {
                OnboardingView1(hasSeenOnboarding: $hasSeenOnboarding, justCompletedOnboarding: $justCompletedOnboarding)
                    .tag(0)
                OnboardingView2(hasSeenOnboarding: $hasSeenOnboarding, justCompletedOnboarding: $justCompletedOnboarding)
                    .tag(1)
                OnboardingView3(cameraViewModel: cameraViewModel, hasSeenOnboarding: $hasSeenOnboarding, justCompletedOnboarding: $justCompletedOnboarding)
                    .tag(2)

                
            }
            
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Hide default page indicator
            .background(Color("CustomBackground").edgesIgnoringSafeArea(.all))
        }

        .background(Color("CustomBackground").edgesIgnoringSafeArea(.all))
    }
}

// Preview for OnboardingContainerView
#Preview {
    OnboardingContainerView(
        hasSeenOnboarding: .constant(false),
        justCompletedOnboarding: .constant(false), cameraViewModel: CameraViewModel()
    )
}
