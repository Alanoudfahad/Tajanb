//
//  OnboardingView2.swift
//  Tajanab
//
//  Created by Ahad on 21/04/1446 AH.
//
import SwiftUI
// هذي السكرين على البركة يبي لها تضبيط مقاسات وخط وكل شيء
// حتى البوتون اظن مفروض فوق بعد
struct OnboardingView2: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        NavigationView {
            VStack {
                // Back Button
                    HStack {
                        
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.white)
                                Text("Back")
                                    .foregroundColor(.white)
                            }
                        }
                        Spacer()
                    }
                    .padding(.leading)
//                    .padding(.top, 20)
                
                Spacer()
                
                // Progress Indicator
                HStack(spacing: 8) {
                    Capsule()
                        .fill(Color(red: 163 / 255, green: 234 / 255, blue: 11 / 255))
                        .frame(width: 30, height: 4)
                    Capsule()
                        .fill(Color(red: 163 / 255, green: 234 / 255, blue: 11 / 255))
                        .frame(width: 30, height: 4)
                    Capsule()
                        .fill(Color.white)
                        .frame(width: 30, height: 4)
                }

                .padding(.bottom, 65)
                
                Text("How it works")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundColor(Color(red: 140 / 255, green: 200 / 255, blue: 12 / 255))
                    .frame(width: 330, height: 24)
                    .padding(.trailing, 190)
                    .padding(.bottom, 20)
                
                HStack(alignment: .top) {
                    VStack {
                        ZStack {
                            Circle()
                                .fill(Color(red: 88 / 255, green: 88 / 255, blue: 88 / 255))
                                .frame(width: 45, height: 45)
                            Image(systemName: "doc.text.magnifyingglass") // First icon
                                .foregroundColor(Color(red: 140 / 255, green: 200 / 255, blue: 12 / 255)) // Icon green color
                                .font(.system(size: 18.57))
                        }
                        
                        // Line between icons
                        Rectangle()
                            .fill(Color(red: 88 / 255, green: 88 / 255, blue: 88 / 255))
                            .frame(width: 2, height: 170)
                            .padding(.vertical, 5)
                        
                        ZStack {
                            Circle()
                                .fill(Color(red: 88 / 255, green: 88 / 255, blue: 88 / 255)) // Background circle color
                                .frame(width: 45, height: 45)
                            Image(systemName: "square.and.arrow.up") // Second icon
                                .foregroundColor(Color(red: 140 / 255, green: 200 / 255, blue: 12 / 255)) // Icon green color
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
                            
                            Image("PhotoScan")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 150)
                                .cornerRadius(10)
                                .clipped()
                        }
                        
                        // Upload Photo section
                        VStack(alignment: .leading) {
                            Text("Upload Photo")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Check for allergens in your photos by selecting an image from your camera roll to scan for potentially harmful ingredients.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Image("UploadPhoto") // Replace with actual image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 150)
                                .cornerRadius(10)
                                .clipped()
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.leading, 30)
                .padding(.bottom, 40)
                .padding(.trailing, 30)

                
            
                NavigationLink(destination: OnboardingView3()) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 163 / 255, green: 234 / 255, blue: 11 / 255))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                Spacer()
                Spacer()
                Spacer()
            
            } 
                
            .background(Color(red: 29 / 255, green: 29 / 255, blue: 31 / 255).edgesIgnoringSafeArea(.all))
        }
        .navigationBarHidden(true)
    } 
}










// هنا بس حطيت الانبوردينق ٣ فاضية، عند أفراح
struct OnboardingView3: View {
    var body: some View {
        Text("Here Onboarding3")
    }
}
struct OnboardingView2_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView2()
    }
}
