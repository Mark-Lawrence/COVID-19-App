//
//  GraphView.swift
//  Covid-19 App
//
//  Created by Mark Lawrence on 4/19/20.
//  Copyright © 2020 Mark Lawrence. All rights reserved.
//

import UIKit

class GraphView: UIView {
    
    var graphData = [[TimelineData]]()
    
    var graph = UIStackView()
    var scrollview = UIScrollView()
    let topAxisLabel = UILabel()
    let midAxisLabel = UILabel()


    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    //initWithCode to init view from xib or storyboard
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initScroll()
        self.layer.cornerRadius = 7
    }
    
    func initScroll(){
        
        self.addSubview(scrollview)
        
        scrollview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollview.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            scrollview.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            scrollview.topAnchor.constraint(equalTo: self.topAnchor),
            scrollview.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        self.addSubview(scrollview)
        scrollview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollview.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            scrollview.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            scrollview.topAnchor.constraint(equalTo: self.topAnchor),
            scrollview.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        topAxisLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        midAxisLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        self.addSubview(topAxisLabel)
        //self.addSubview(midAxisLabel)
        topAxisLabel.translatesAutoresizingMaskIntoConstraints = false
        //midAxisLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topAxisLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            topAxisLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
            //midAxisLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: (self.frame.height/2)+10),
           // midAxisLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5)
        ])
    }
    
    func reloadGraph() {
        //scrollview = UIScrollView()        
        for view in self.scrollview.subviews {
            view.removeFromSuperview()
        }
        
        let hStack = UIStackView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        hStack.axis = .horizontal
        hStack.alignment = .fill
        hStack.distribution = .fill
        hStack.spacing = 10
        scrollview.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Attaching the content's edges to the scroll view's edges
            hStack.leadingAnchor.constraint(equalTo: scrollview.leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: scrollview.trailingAnchor),
            hStack.topAnchor.constraint(equalTo: scrollview.topAnchor),
            hStack.bottomAnchor.constraint(equalTo: scrollview.bottomAnchor),
            
            // Satisfying size constraints
            hStack.heightAnchor.constraint(equalTo: scrollview.heightAnchor)
        ])
        let maxCases = getMaxNumberOfCases()
        if maxCases == 0{
            return
        }
        
        //Add x axis data
        topAxisLabel.text = "\(maxCases)"
        midAxisLabel.text = "\(Int(maxCases/2))"

        
        
        var index = 0
        if graphData.count != 0 {
            for data in graphData[0]{
                let dateStack = UIStackView()
                dateStack.axis = .vertical
                
                
                let typeStack = UIStackView()
                typeStack.axis = .horizontal
                typeStack.spacing = 3
                typeStack.distribution = .fillEqually
                
                let confirmSpacer = UIView()
                let confirmStack = UIStackView()
                confirmStack.axis = .vertical
                confirmStack.spacing = 0
                let confirmedBar = UIView()
                let confirmHeight = CGFloat(Double(data.cases)/Double(maxCases)*220.0)
                confirmedBar.heightAnchor.constraint(equalToConstant: confirmHeight).isActive = true
                confirmedBar.backgroundColor = UIColor(named: "yellow")
                confirmedBar.layer.cornerRadius = 6
                
                confirmStack.addArrangedSubview(confirmSpacer)
                confirmStack.addArrangedSubview(confirmedBar)
                typeStack.addArrangedSubview(confirmStack)
                
                if graphData.count == 2{
                    let deadSpacer = UIView()
                    let deadStack = UIStackView()
                    deadStack.axis = .vertical
                    deadStack.spacing = 0
                    let deadBar = UIView()
                    let deadHeight = CGFloat(Double(graphData[1][index].cases)/Double(maxCases)*220.0)
                    deadBar.heightAnchor.constraint(equalToConstant: deadHeight).isActive = true
                    deadBar.backgroundColor = UIColor(named: "blue")
                    deadBar.layer.cornerRadius = 6
                    
                    deadStack.addArrangedSubview(deadSpacer)
                    deadStack.addArrangedSubview(deadBar)
                    typeStack.addArrangedSubview(deadStack)
                }
                
                let label = UILabel()
                label.text = data.getFormatedDate()
                label.textAlignment = .center
                label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
                
                
                
                dateStack.addArrangedSubview(typeStack)
                dateStack.addArrangedSubview(label)
                hStack.addArrangedSubview(dateStack)
                dateStack.translatesAutoresizingMaskIntoConstraints = false
                dateStack.widthAnchor.constraint(equalToConstant: 30).isActive = true
                index += 1
                
            }
        }
        if graphData.count != 0{
            let bottomOffset = CGPoint(x: 33*graphData[0].count, y: 0)
            scrollview.setContentOffset(bottomOffset, animated: true)
        }
    }
    
    func getMaxNumberOfCases() -> Int{
        var maxCases = 0
        
        for i in graphData{
            for j in i{
                if j.cases > maxCases{
                    maxCases = j.cases
                }
            }
        }
        return maxCases
    }
    
}
