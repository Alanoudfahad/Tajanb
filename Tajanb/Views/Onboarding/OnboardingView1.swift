import SwiftUI

struct OnboardingView1: View {
    @Binding var hasSeenOnboarding: Bool
    @Binding var justCompletedOnboarding: Bool

    var body: some View {
        VStack {
            Spacer()

            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 182, height: 183)
                .foregroundColor(Color.green)
                .padding(.bottom, 30)

            Text("Welcome to Tajanb!")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(Color("TextColor"))
                .padding(.bottom, 8)

            Text("Enjoy Your food, Avoid Allergens")
                .font(.system(size: 20))
                .foregroundColor(.white)

            Spacer()
        }
        .background(Color("CustomBackground").edgesIgnoringSafeArea(.all))
    }
}

#Preview {
    OnboardingView1(hasSeenOnboarding: .constant(false), justCompletedOnboarding: .constant(false))
}
