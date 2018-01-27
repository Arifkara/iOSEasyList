//
//  EndlessVM.swift
//  ListExample-iOS
//
//  Created by Mostafa Taghipour on 1/5/18.
//  Copyright © 2018 RainyDay. All rights reserved.
//

import RxSwift
import iOSEasyList

class SectionedVM{
    var items=Variable<[MovieSection]>([])
    
    
    init() {
        loadTopMovies(page: 1)
    }
    
    func loadTopMovies(page:Int){
        
        
        
        API.getTopRatedMovies(page: page, success: { movies in
            
            let newItems : [MovieSection] = movies.grouped(by: { (movie) -> Character in
                return (movie.title.characters.first)!
            })
                .sorted{ $0.key < $1.key }
                .map{  MovieSection(firstLetter: String($0.key), items: $0.value) }
            
            
            
            
            self.items.value=newItems
            
        }) { error in
        }
        
    }
    
}



struct MovieSection {
    let firstLetter:String
    let items:[Movie]
}

extension MovieSection:SectionDiffable{
    var sectionItems: Array<Diffable> {
        return items
    }
    
    var diffIdentifier: String {
        return firstLetter
    }
}

