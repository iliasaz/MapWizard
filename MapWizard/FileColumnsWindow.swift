//
//  FileColumnsWindow.swift
//  MapWizard
//
//  Created by Ilia Sazonov on 6/16/24.
//

import SwiftUI


struct FileColumnsWindow: View {
    @EnvironmentObject var fileViewModel: FileViewModel

    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                    ForEach(fileViewModel.files) { file in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(file.fileName)
                                .font(.headline)
                                .padding(.bottom, 5)
                            Divider()
                            VStack(alignment: .leading, spacing: 5) {
                                ForEach(file.header, id: \.self) { column in
                                    Text(column)
                                        .background(file.mappedColumns[column])
                                        .padding(.leading, 5)
                                }
                            }
                            .padding(5)
//                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(5)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                                .background(Color.white)
                                .cornerRadius(10)
                        )
                        .shadow(radius: 5)
                    }
                }
                .padding()
            }
            .frame(minWidth: 150, minHeight: 300)

            HStack {
                Button(action: {
                    Task { await fileViewModel.computeEmbeddings() }
                }) {
                    Text("Map it!")
                }
                .padding()
                .disabled(fileViewModel.isComputing) // Disable button while computing

                if fileViewModel.isComputing {
                    ProgressView()
                        .padding()
                }
            }
        }
        .navigationTitle("Entity Relationship Diagram")
    }
}


