//
//  DrinkingRound.swift
//  alcoholcalculator
//
//  Created by Szép Roland on 2021. 12. 08..
//

import Foundation

class DrinkingRound {
    
    var alcoholArray = ["Sör 5%", "Sör 10%", "Sör 15%", "Bor 8%", "Bor 10%", "Bor 12%", "Bor 14%", "Pezsgő 10%",
                        "Cider 5%", "Cider 6%", "Cider 8%", "Bacardi 40%", "Baileys 17%", "Gin 40%", "Jägermeister 37%",
                        "Martini 16%", "Pálinka 40%", "Rum 40%", "Tequila 40%", "Unicum 40%", "Vodka 40%", "Whiskey 40%", "Whiskey 55%"]
    
    var time: Date?
    var alcohol = ""
    var amount = 0.0
    
    func toString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        
        return dateFormatter.string(from: time ?? Date.now) + " - " + String(amount) + " dl " + alcohol.lowercased()
    }
}
