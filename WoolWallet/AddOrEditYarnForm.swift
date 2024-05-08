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
    @State private var weight: String = "Select One"
    @State private var unitOfMeasure: String = "yards"
    @State private var length: Double = 0
    @State private var grams: Int = 0
    @State private var skeins: Double = 1
    @State private var totalGrams: Int = 0
    @State private var notes: String = ""
    @State private var caked: Bool = false
    @State private var image: UIImage?
    
    // Computed property to calculate the totalLength
    var totalLength: String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0 // Minimum number of digits after decimal
        formatter.maximumFractionDigits = 2 // Maximum number of digits after decimal
        formatter.numberStyle = .decimal // Set the number style
        
        var totalLength = 0.0
        
        if totalGrams != 0 {
            totalLength = (length * Double(totalGrams)) / Double(grams)
        } else {
            totalLength = length * skeins
        }
        
        return formatter.string(from: NSNumber(value: totalLength)) ?? ""
    }
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var showCamera = false
    
    @State private var formToast: Toast? = nil
    
    @FocusState private var focusedField: Field?
    
    private enum Field: Int, Hashable {
        case name, dyer, length, grams, weight, notes, totalGrams, skeins
    }
    
    let weights = [
        "Select One",
        "0 - Lace",
        "1 - Fingering",
        "2 - Sport", 
        "3 - DK",
        "4 - Worsted",
        "5 - Chunky",
        "6 - Super Bulky",
        "7 - Jumbo"
    ]
    
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
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "scalemass.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .padding(.trailing, 8)
                        
                        Text("Weight")
                        
                        Spacer()
                        
                        Picker("Weight", selection: $weight) {
                            ForEach(weights, id: \.self) { weight in
                                Text(weight).tag(weight)
                            }
                        }
                        .foregroundStyle(Color.black)
                        .pickerStyle(.menu)
//                        .frame(width: 200, height: 75, alignment: .center) // Set your desired size
//                        .clipped()
                    }
                }
                .padding()
                
                Divider()
                
                HStack {
                    TextField("", value: $length, format: .number)
                        .keyboardType(.numberPad)
                        .frame(height: 48)
                        .textFieldStyle(
                            MyTextFieldStyle()
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                        .focused($focusedField, equals: .length)
                        .onTapGesture { focusedField = .length }
                    
                    Picker("Unit of Measure", selection: $unitOfMeasure) {
                        Text("yards").tag("yards")
                        Text("meters").tag("meters")
                    }
                    .onChange(of: unitOfMeasure) { newValue in
                        let yardsToMeters = 0.9144
                        if (newValue == "meters") {
                            length = Double(String(format : "%.2f", yardsToMeters * length))!
                        } else {
                            length = Double(String(format : "%.2f", length / yardsToMeters))!
                        }
                    }
                    .foregroundStyle(Color.black)
                    .pickerStyle(.wheel)
                    .frame(width: 100, height: 100, alignment: .center) // Set your desired size
                    .clipped()
                   
                    
                    Spacer()
                    Text("/")
                        .foregroundStyle(Color.black)
                        .font(.system(size: 20))
                        .padding(.trailing, 10)
                    Spacer()
                    
                    TextField("", value: $grams, format: .number)
                        .keyboardType(.numberPad)
                        .frame(height: 48)
                        .textFieldStyle(
                            MyTextFieldStyle()
                        )
                        .focused($focusedField, equals: .grams)
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture { focusedField = .grams }
                    
                    Text("grams")
                        .foregroundStyle(Color.black)
                        .font(.system(size: 20))
                }
                .padding()
                
                Divider()
                
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
                    
                    TextField("", value: $skeins, format: .number)
                        .keyboardType(.decimalPad)
                        .frame(width: 65, height: 48)
                        .textFieldStyle(
                            MyTextFieldStyle()
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                        .focused($focusedField, equals: .skeins)
                        .onTapGesture { focusedField = .skeins }
//                        .onChange(of: skeins) { newValue in
//                            if length > 0 {
//                                let newTotalGrams = length * newValue
//                                if newTotalGrams - totalGrams == length {
//                                    totalGrams = newTotalGrams
//                                }
//                            }
//                        }
                       
                    
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
                
                HStack(spacing : 8) {
                    HStack {
                        Image(systemName: "dumbbell.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .padding(.trailing, 8)
                        
                        Text("Total Grams")
                        
                        Spacer()
                        
                        TextField("", value: $totalGrams, format: .number)
                            .keyboardType(.numberPad)
                            .frame(width: 75, height: 48)
                            .textFieldStyle(
                                MyTextFieldStyle()
                            )
                            .contentShape(RoundedRectangle(cornerRadius: 8))
                            .focused($focusedField, equals: .totalGrams)
                            .onTapGesture { focusedField = .totalGrams }
                    }
                }
                .padding()
                
                Divider()
                
                if length > 0 && grams > 0 {
                    HStack(spacing : 8) {
                        Image(systemName: "ruler.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .padding(.trailing, 8)
                        
                        Text("Total Length")
                        Spacer()
                        Text("\(totalLength) \(unitOfMeasure)")
                    }
                    .padding()
                    
                    Divider()
                }
                
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
                        yarn.weight = weight
                        yarn.unitOfMeasure = unitOfMeasure
                        yarn.length = length
                        yarn.grams = Int16(grams)
                        yarn.skeins = skeins
                        yarn.totalGrams = Int16(totalGrams)
                        yarn.totalLength = totalLength
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
        weight = ""
        unitOfMeasure = "yards"
        length = 0
        grams = 0
        skeins = 1
        totalGrams = 0
        notes = ""
        caked = false
        image = nil
    }
}


//struct AddYarnForm_Previews: PreviewProvider {
//    static var previews: some View {
//        let toast = Toast(style: ToastStyle.success, message: "test")
//        
//        AddYarnForm(showSheet : .constant(true), toast: .constant(toast))
//    }
//}




