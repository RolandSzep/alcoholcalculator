//
//  NewRoundViewController.swift
//  alcoholcalculator
//
//  Created by Szép Roland on 2021. 12. 07..
//

import UIKit
import CoreData

class NewRoundViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    let drinkingRound = DrinkingRound()
    var weightArray: [Int] = [Int](repeating: 0, count: 81)
    var alcohol: [String] = []
    var rounds: [NSManagedObject] = []
    var weight = 70
    
    @IBOutlet weak var weightPicker: UIPickerView!
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var alcoholPicker: UIPickerView!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var counterLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        for i in 40...120 {
            weightArray[i-40] = i
        }
        
        weightPicker.dataSource = self
        weightPicker.delegate = self
        var selectRow = 30
        let preferences = UserDefaults.standard
        if preferences.object(forKey: "weight") != nil {
            weight = preferences.integer(forKey: "weight")
            selectRow = weight - 40
        }
        weightPicker.selectRow(selectRow, inComponent: 0, animated: false)
        
        timePicker.minimumDate = Date.now.addingTimeInterval(TimeInterval(-24*60*60))
        timePicker.maximumDate = Date.now
        
        alcoholPicker.dataSource = self
        alcoholPicker.delegate = self
        
        stepper.wraps = true
        stepper.autorepeat = true
        stepper.maximumValue = 10
        stepper.stepValue = 0.5
        
        drinkingRound.time = timePicker.date
        drinkingRound.alcohol = drinkingRound.alcoholArray[0]
    }
    
    func save() {
        
        let preferences = UserDefaults.standard
        preferences.set(weight, forKey: "weight")

        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        // 1
        let managedContext =  appDelegate.persistentContainer.viewContext
        
        // 2
        let entity = NSEntityDescription.entity(forEntityName: "Round", in: managedContext)!
        
        let round = NSManagedObject(entity: entity, insertInto: managedContext)
        
        // 3
        round.setValue(drinkingRound.time, forKeyPath: "time")
        round.setValue(drinkingRound.alcohol, forKeyPath: "alcohol")
        round.setValue(drinkingRound.amount, forKeyPath: "amount")
        
        // 4
        do {
            try managedContext.save()
            rounds.append(round)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 0 {
            return weightArray.count
        } else {
            return drinkingRound.alcoholArray.count
        }
    }
    
    // The data to return fopr the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 0 {
            return String(weightArray[row]) + " kg"
        } else {
            return drinkingRound.alcoholArray[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 0 {
            weight = weightArray[row]
        } else {
            drinkingRound.alcohol = drinkingRound.alcoholArray[row]
        }
    }
    
    @IBAction func timeValueChanged(_ sender: UIDatePicker) {
        drinkingRound.time = sender.date
    }
    
    @IBAction func stepperValueChanged(_ sender: UIStepper) {
        addButton.isEnabled = Float(sender.value.description) != 0
        drinkingRound.amount = sender.value
        counterLabel.text = sender.value.description + " dl"
    }
    
    @IBAction func addButtonClicked(_ sender: UIButton) {
        save()
        self.navigationController?.popViewController(animated: true)
    }
}
