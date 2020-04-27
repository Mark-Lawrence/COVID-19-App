//
//  timelineData.swift
//  Covid-19 App
//
//  Created by Mark Lawrence on 4/19/20.
//  Copyright © 2020 Mark Lawrence. All rights reserved.
//

import Foundation

struct TimelineData{
    
    var date: String!
    var cases: Int!
    
    init(date: String, cases: Int){
        self.cases = cases
        self.date = date
        //formateDate(dateToFormat: date)
    }
    
    mutating func incrementCases(by: Int){
        self.cases += by
    }
    
    func getFormatedDate() -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let asDate = dateFormatter.date(from:date)!
        
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: asDate)
    }
    
}
