//
//  SplashScreenView.swift
//  Tajanb
//
//  Created by Alanoud Alshuaibi on 22/04/1446 AH.
//


//
//  SplashScreen.swift
//  Tajanab
//
//  Created by Ahad on 21/04/1446 AH.

import SwiftUI
// سويتها أي كلام عاد زبطوها زي ما تبون

struct SplashScreenView: View {
    @State private var animateLogo = false
    @State private var isActive = false
    @ObservedObject var cameraViewModel = CameraViewModel()

    var body: some View {
        VStack {
            if isActive {
                CameraView(viewModel: cameraViewModel, photoViewModel: PhotoViewModel(viewmodel: cameraViewModel))
            } else {
                ZStack {
                    Color(red: 29 / 255, green: 29 / 255, blue: 31 / 255)
                        .ignoresSafeArea()

                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .foregroundColor(Color(red: 140 / 255, green: 200 / 255, blue: 12 / 255))
                        .scaleEffect(animateLogo ? 1 : 0.5)
                        .opacity(animateLogo ? 1 : 0)
                        .animation(.easeInOut(duration: 1.5))

                }
                .onAppear {
                    withAnimation {
                        self.animateLogo = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}
