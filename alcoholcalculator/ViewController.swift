//
//  ViewController.swift
//  alcoholcalculator
//
//  Created by Szép Roland on 2021. 12. 07..
//

import UIKit
import CoreData

class ViewController: UIViewController {

    var alcohol: [String] = []
    var rounds: [NSManagedObject] = []
    var weight = 0.0
    
    @IBOutlet weak var roundsLabel: UILabel!
    @IBOutlet weak var roundsTableView: UITableView!
    @IBOutlet weak var lineChart: LineChart!
    @IBOutlet weak var bloodAlcoholLevelLabel: UILabel!
    @IBOutlet weak var soberLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        roundsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        lineChart.isCurved = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //1
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Round")
        
        //3
        do {
            rounds = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        // TODO
        self.roundsTableView.reloadData()
        
        let preferences = UserDefaults.standard
        if preferences.object(forKey: "weight") != nil {
            weight = Double(preferences.integer(forKey: "weight"))
        }
        
        calculate()
    }
    
    func calculate() {
        lineChart.dataEntries = calculateGraphPoints()
        let alcoholAmount = calculateResults(referenceDate: Date.now)
        let bloodAlcoholLevel = getBloodAlcoholLevel(alcoholAmount: alcoholAmount.1)
        roundsLabel.text = "Körök - \(Int(alcoholAmount.0.rounded()))g bevitt alkohol"
        bloodAlcoholLevelLabel.text = "A szervezetedben még kb. \(alcoholAmount.1)g tiszta alkohol található.\n\nEz \(bloodAlcoholLevel) ezrelék véralkohol szintnek felel meg."
        if (bloodAlcoholLevel == 0) {
            setSober(isSober: true, time: alcoholAmount.2)
        } else {
            setSober(isSober: false, time: alcoholAmount.2)
        }
    }
    
    private func calculateGraphPoints() -> [PointEntry] {
        let value = calculateResults(referenceDate: Date.now)
        let earliestTimeDifference = Calendar.current.dateComponents([.hour, .minute], from: value.2, to: Date.now)
        let numbers = -(earliestTimeDifference.hour ?? 0) + 1
        print(Date.now)
        
        var result: [PointEntry] = []
        for i in (0...max(numbers, 6)) {
            //let value = Int(arc4random() % 500)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "hh:mm"
            var date = Date()
            date.addTimeInterval(TimeInterval(60*60*i))
            
            let value = calculateResults(referenceDate: date)
            
            result.append(PointEntry(value: Int(value.1), label: formatter.string(from: date)))
        }
        return result
    }
    
    func setSober(isSober: Bool, time: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        soberLabel.text = isSober ? "Józan" : "Ittas eddig: \(formatter.string(from: time))"
        soberLabel.textColor = isSober ? UIColor.systemGreen : UIColor.systemRed
    }
    
    func calculateResults(referenceDate: Date) -> (Double, Double, Date) {
        var alcoholIntake = 0.0
        var alcoholAmount = 0.0
        var drinkingRounds = [DrinkingRound]()
        
        for round in rounds {
            let drinkingRound = DrinkingRound()
            drinkingRound.time = round.value(forKeyPath: "time") as? Date ?? nil
            drinkingRound.alcohol = round.value(forKeyPath: "alcohol") as? String ?? "nil"
            drinkingRound.amount = round.value(forKeyPath: "amount") as? Double ?? 0.0
            drinkingRounds.append(drinkingRound)
        }

        drinkingRounds = drinkingRounds.sorted(by: { $0.time! < $1.time! })
    
        var earliestTime = drinkingRounds.first?.time ?? referenceDate
        
        for drinkingRound in drinkingRounds {
            if let alcoholPercentage = Int.parse(from: drinkingRound.alcohol) {
                //print(drinkingRound.toString())
                //print(drinkingRound.time)
                //print(alcoholPercentage)
                
                alcoholIntake += Double(alcoholPercentage) * drinkingRound.amount * 0.8
                
                let timeRequiredToDecompose = (Double(alcoholPercentage) * drinkingRound.amount * 0.8 / (weight / 10.0))
                //print(timeRequiredToDecompose)
                
                if (drinkingRound.time! > earliestTime) {
                    earliestTime = drinkingRound.time!
                }
                //print("-----")
                //print(earliestTime)
                earliestTime += timeRequiredToDecompose * 60 * 60
                //print("-")
                //print(earliestTime)
                //print("-----")
                
                // TODO
                //let formatter = DateFormatter()
                //formatter.dateFormat = "yyyy/MM/dd HH:mm"
                //let someDateTime = formatter.date(from: "2021/12/08 22:00") // Date.Now
                let earliestTimeDifference = Calendar.current.dateComponents([.hour, .minute], from: earliestTime, to: referenceDate)
                
                var amountLeft = 0.0
                if (earliestTime > referenceDate) {
                    amountLeft += -(Double(earliestTimeDifference.hour ?? 0) + Double(earliestTimeDifference.minute ?? 0) / 60) * (weight / 10.0)
                }
                //print(referenceDate)
                //print("amountLeft: " + String(amountLeft))
                //print("-------------------------")
                
                alcoholAmount = ((amountLeft) * 10).rounded() / 10
            }
        }
        
        if (alcoholAmount <= 0) {
            return (alcoholIntake, 0.0, earliestTime)
        }
        return (alcoholIntake, alcoholAmount, earliestTime)
    }
    
    func getBloodAlcoholLevel(alcoholAmount: Double) -> Double {
        return (alcoholAmount / 50 * 100).rounded() / 100
    }
}

extension Int {
    static func parse(from string: String) -> Int? {
        return Int(string.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rounds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let round = rounds[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let drinkingRound = DrinkingRound()
        drinkingRound.time = round.value(forKeyPath: "time") as? Date ?? nil
        drinkingRound.alcohol = round.value(forKeyPath: "alcohol") as? String ?? "nil"
        drinkingRound.amount = round.value(forKeyPath: "amount") as? Double ?? 0.0
        cell.textLabel?.text = drinkingRound.toString()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        tableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.right)
        
        managedContext.delete(rounds[indexPath.row])
        rounds.remove(at: indexPath.row)
        self.roundsTableView.reloadData()
        self.calculate()
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
}
