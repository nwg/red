//
//  ContentView.swift
//  Red
//
//  Created by Nathaniel W Griswold on 6/8/20.
//  Copyright © 2020 ManicMind. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var text = ""
//    lazy var textView : TextView = {
//        return TextView(text: self.$text)
//    }()
    var body: some View {
//        ScrollView(
//            .vertical,
//            showsIndicators: true) {
        GeometryReader { hProxy in
            HStack {
                GeometryReader { vProxy in
                    VStack {
                        TextView(text: self.$text)
                        TextView(text: self.$text)
                    }

                }
                GeometryReader { vProxy in
                    VStack {
                        TextView(text: self.$text)
                        TextView(text: self.$text)
//                            .offset(x: 0, y: hProxy.size.height / 2)
                    }
                }
            }

        }
            
//        }
    }
    
    func row() -> some View {
        Text("blah")
            .border(Color.red) // uncomment to see border
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
