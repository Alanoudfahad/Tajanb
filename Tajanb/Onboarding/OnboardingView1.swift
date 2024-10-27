//
//  OnboardingView1.swift
//  Tajanb
//
//  Created by Alanoud Alshuaibi on 22/04/1446 AH.
//


import SwiftUI

struct OnboardingView1: View {
    @Binding var hasSeenOnboarding: Bool
    @Binding var justCompletedOnboarding: Bool // Add this binding

    var body: some View {
        NavigationView {
            VStack {
                
                Spacer()
                
                // Progress Indicator هذا مدري شلون اسويه
                HStack(spacing: 8) {
                    Capsule()
                        .fill(Color("CustomGreen"))
                        .frame(width: 30, height: 4)
                    
                    Capsule()
                        .fill(Color.white)
                        .frame(width: 30, height: 4)
                    
                    Capsule()
                        .fill(Color.white)
                        .frame(width: 30, height: 4)
                }
                .padding(.bottom, 90)
                
                Spacer()
                Spacer()

                // The Logo
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 182, height: 183)
                    .foregroundColor(Color.green)
                    .padding(.bottom, 30)
                
                Spacer()

                // Welcome Text
                Text("Welcome to Tajanb!")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color("CustomGreen"))
                    .padding(.bottom, 8)
                
                // Subtitle Text
                Text("Scan Fast for Sure Protection")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                
                Spacer()
                Spacer()
                Spacer()
                Spacer()

                Spacer()
                // Navigation Button to the next onboarding screen
                NavigationLink(destination: OnboardingView2(hasSeenOnboarding: $hasSeenOnboarding, justCompletedOnboarding: $justCompletedOnboarding)) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("CustomGreen"))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
              
                Spacer()
                Spacer()
            }
            .background(Color("CustomBackground").edgesIgnoringSafeArea(.all))
        }
        .navigationBarHidden(true)
    }
}

