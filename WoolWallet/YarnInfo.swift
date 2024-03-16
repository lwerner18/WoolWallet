//
//  YarnInfo.swift
//  WoolWallet
//
//  Created by Mac on 3/15/24.
//

import Foundation
import SwiftUI

struct YarnInfo: View {
    let yarn : Yarn
    
    var body: some View {
        ScrollView {
            VStack {
                Button("Edit") {
                    
                }
                
                Button("Delete") {
                    
                }
                
                Image(uiImage: UIImage(data: yarn.image ?? Data()) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cardBackground()
                    .padding(20)
//                    .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 5)
                
                HStack {
                    Text("Name: ").font(.headline)
                    Text(yarn.name!)
                }
                .padding(.vertical, 10)
                
                Divider()
                
                HStack {
                    Text("Dyer: ").font(.headline)
                    Text(yarn.dyer!)
                }
                .padding(.vertical, 10)
                
                
            }
            .foregroundStyle(Color.black)
        }
        .background(Color.white)
       
    }
    
    init(yarn: Yarn) {
        self.yarn = yarn
    }
}
