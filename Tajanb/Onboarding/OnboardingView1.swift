//
//  OnboardingView1.swift
//  Tajanb
//
//  Created by Alanoud Alshuaibi on 22/04/1446 AH.
//


import SwiftUI

struct OnboardingView1: View {
    var body: some View {
        NavigationView {
            VStack {
                
                Spacer()
                
                // Progress Indicator هذا مدري شلون اسويه
                HStack(spacing: 8) {
                    Capsule()
                        .fill(Color(red: 163 / 255, green: 234 / 255, blue: 11 / 255))
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
                    .foregroundColor(Color(red: 140 / 255, green: 200 / 255, blue: 12 / 255))
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
                NavigationLink(destination: OnboardingView2()) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 163 / 255, green: 234 / 255, blue: 11 / 255)) // Custom button color
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                Spacer()

            }
            .background(Color(red: 29 / 255, green: 29 / 255, blue: 31 / 255).edgesIgnoringSafeArea(.all))

        }
                      .navigationBarHidden(true)
                  }
              }


              struct OnboardingView1_Previews: PreviewProvider {
                  static var previews: some View {
                      OnboardingView1()
                  }
              }
