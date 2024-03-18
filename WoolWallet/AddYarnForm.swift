//
//  ContentView.swift
//  WoolWallet
//
//  Created by Mac on 3/8/24.
//

import SwiftUI
import PhotosUI


struct AddYarnForm: View {
    @Binding var showSheet: Bool
    @Binding var toast: Toast?
    
    @State private var name: String = ""
    @State private var dyer: String = ""
    @State private var yards: Int = 1
    @State private var grams: Int = 1
    @State private var skeins: Int = 1
    @State private var weight: String = ""
    @State private var notes: String = ""
    @State private var caked: Bool = false
    @State private var image: UIImage?
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var showCamera = false
    
    @State private var formToast: Toast? = nil
    
    @FocusState private var focusedField: Field?
    
    private enum Field: Int, Hashable {
        case name, dyer, weight, notes
    }
    
    @Environment(\.managedObjectContext) var managedObjectContext
        
    var body: some View {
        ScrollView {
            VStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .edgesIgnoringSafeArea(.all)
                        .scaledToFit()
                        .overlay(
                            Button(action: {
                                // Delete action
                                self.image = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.black)
                                    .font(.title)
                            }
                                .padding(10)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                                .offset(x: 10, y: -10),
                            alignment: .topTrailing
                        )
                } else {
                    HStack {
                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Text("Upload a photo")
                        }
                        .onChange(of: selectedItem) {
                            newItem in
                            Task {
                                if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                                    image = UIImage(data: data)
                                }
                                print("Failed to load the image")
                            }
                        }
                        
                        Text("or")
                        
                        Button("Take a photo") {
                            self.showCamera.toggle()
                        }
                        .fullScreenCover(isPresented: self.$showCamera) {
                            accessCameraView(selectedImage: self.$image)
                        }
                    }
                    .padding(.vertical, 64)
                    
                    Divider()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "volleyball.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .padding(.trailing, 8)
                        
                        Text("Name")
                        
                        Spacer()
                    }
                    .padding(.bottom, 8)
              
                    
                    TextField("Enter text", text: $name)
                        .frame(height: 48)
                        .textFieldStyle(
                            MyTextFieldStyle()
                        )
                        .modifier(
                            ClearButton(text: $name)
                        )
                        .focused($focusedField, equals: .name)
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture { focusedField = .name }
                }
                .padding()
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .padding(.trailing, 8)
                        Text("Dyer")
                        
                        Spacer()
                    }
                    .padding(.bottom, 8)
                
                    
                    TextField("Enter text", text: $dyer)
                        .frame(height: 48)
                        .textFieldStyle(
                            MyTextFieldStyle()
                        )
                        .modifier(
                            ClearButton(text: $dyer)
                        )
                        .focused($focusedField, equals: .dyer)
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture { focusedField = .dyer }
                }
                .padding()
                
                Divider()
                
//                HStack {
//                    TextField("", value: $yards, format: .number)
//                        .keyboardType(.numberPad)
//                    Text("yards")
//                    Spacer()
//                    Text("/")
//                    Spacer()
//                    TextField("", value: $grams, format: .number)
//                        .keyboardType(.numberPad)
//                    Text("grams")
//                }
//                .padding()
                
//                Divider()
                
                HStack(spacing : 8) {
                    Image(systemName: "number")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .padding(.trailing, 8)
                    
                    Text("Skeins")
                    
                    Spacer()
                    
                    Button(action: {
                        skeins = max(skeins - 1, 1)
                    }) {
                        Image(systemName: "minus.circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                    }
                    
                    
                    Text("\(skeins)")
                        .padding(.horizontal, 20.0)
                        .font(.headline)
                    
                    Button(action: {
                        skeins = skeins + 1
                    }) {
                        Image(systemName: "plus.circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                    }
                }
                .padding()
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "scalemass.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .padding(.trailing, 8)
                        
                        Text("Weight")
                        
                        Spacer()
                    }
                    .padding(.bottom, 8)
                 
                    
                    TextField("Enter text", text: $weight)
                        .frame(height: 48)
                        .textFieldStyle(
                            MyTextFieldStyle()
                        )
                        .modifier(
                            ClearButton(text: $weight)
                        )
                        .focused($focusedField, equals: .weight)
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture { focusedField = .weight }
                }
                .padding()
                
                Divider()
                
                HStack(spacing : 8) {
                    Image(systemName: "birthday.cake.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .padding(.trailing, 8)
                    
                    Toggle("Caked?", isOn: $caked)
                }
                .padding()
               
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "note.text")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .padding(.trailing, 8)
                        
                        Text("Notes")
                        
                        Spacer()
                    }
                    .padding(.bottom, 8)
                 
                    
                    TextField(
                        "Enter text",
                        text: $notes,
                        axis: .vertical
                    )
                    .lineLimit(5...10)
                    .textFieldStyle(
                        MyTextFieldStyle()
                    )
                    .modifier(
                        ClearButton(text: $notes)
                    )
                    .focused($focusedField, equals: .notes)
                    .contentShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture { focusedField = .notes }
                }
                .padding()
                
                Divider()
                
                HStack {
                    Button("Clear") {
                        clearForm()
                        hideKeyboard()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Spacer()
                    
                    Button("Create") {
                        let yarn = Yarn(context: managedObjectContext)
                        
                        yarn.name = name
                        yarn.dyer = dyer
                        yarn.skeins = Int16(skeins)
                        yarn.weight = weight
                        yarn.isCaked = caked
                        yarn.notes = notes
                        
                        guard let imageData = image!.jpegData(compressionQuality: 1.0) else {
                            // Handle error if unable to convert UIImage to Data
                            return
                        }
                        
                        yarn.image = imageData
                        
                        PersistenceController.shared.save()
                        
                        toast = Toast(style: .success, message: "Successfully saved yarn!")
                        clearForm()
                        hideKeyboard()
                        showSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(name == "" && image == nil)
                }
                .padding()
            }
            
            // Additional form elements can be added here
        }
        .onTapGesture() {
            hideKeyboard()
        }
        .toastView(toast: $formToast)
    }
    
    func clearForm() {
        name = ""
        dyer = ""
        yards = 1
        grams = 1
        skeins = 1
        weight = ""
        notes = ""
        caked = false
        image = nil
    }
}


struct AddYarnForm_Previews: PreviewProvider {
    static var previews: some View {
        let toast = Toast(style: ToastStyle.success, message: "test")
        
        AddYarnForm(showSheet : .constant(true), toast: .constant(toast))
    }
}




