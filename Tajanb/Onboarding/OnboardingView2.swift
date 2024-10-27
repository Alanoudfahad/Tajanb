//
//  OnboardingView2.swift
//  Tajanab
//
//  Created by Ahad on 21/04/1446 AH.
//
import SwiftUI
struct OnboardingView2: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding var hasSeenOnboarding: Bool
    @Binding var justCompletedOnboarding: Bool // Add this binding

    var body: some View {
        NavigationView {
            VStack {
          //       Back Button
                    HStack {
                        
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.white)
                      
                            }
                        }
                        Spacer()
                    }
                    .padding(.leading)
                
                Spacer()
                
                // Progress Indicator
                HStack(spacing: 8) {
                    Capsule()
                        .fill(Color("CustomGreen"))
                        .frame(width: 30, height: 4)
                    Capsule()
                        .fill(Color("CustomGreen"))
                        .frame(width: 30, height: 4)
                    Capsule()
                        .fill(Color.white)
                        .frame(width: 30, height: 4)
                }

                .padding(.bottom, 65)
                
                Text("How it works")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundColor(Color("CustomGreen"))
                    .frame(width: 330, height: 24)
                    .padding(.trailing, 190)
                    .padding(.bottom, 20)
                
                HStack(alignment: .top) {
                    VStack {
                        ZStack {
                            Circle()
                                .fill(Color("GrayList"))
                                .frame(width: 45, height: 45)
                            Image(systemName: "doc.text.magnifyingglass") // First icon
                                .foregroundColor(Color("CustomGreen")) // Icon green color
                                .font(.system(size: 18.57))
                        }
                        
                        // Line between icons
                        Rectangle()
                            .fill(Color("textGray"))
                            .frame(width: 2, height: 200)
                            .padding(.vertical, 5)
                        
                        ZStack {
                            Circle()
                                .fill(Color("GrayList")) // Background circle color
                                .frame(width: 45, height: 45)
                            Image(systemName: "square.and.arrow.up") // Second icon
                                .foregroundColor(Color("CustomGreen")) // Icon green color
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
                                  .fixedSize(horizontal: false, vertical: true) // Allows text to wrap

                              Image("PhotoScan")
                                  .resizable()
                                  .aspectRatio(contentMode: .fill)
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
                                  .fixedSize(horizontal: false, vertical: true) // Ensures text wraps to multiple lines
                            
                            Image("UploadPhoto") // Replace with actual image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .cornerRadius(10)
                                .clipped()
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()

                NavigationLink(destination: OnboardingView3(hasSeenOnboarding: $hasSeenOnboarding, justCompletedOnboarding: $justCompletedOnboarding)) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("CustomGreen"))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                }
                
                
           
            } 
            .padding()
            .background(Color("CustomBackground").edgesIgnoringSafeArea(.all))
        }
        .navigationBarHidden(true)
    } 
}

#Preview{
    OnboardingView2(hasSeenOnboarding: .constant(true), justCompletedOnboarding: Binding<Bool>(get: { false }, set: { _ in }))
}


