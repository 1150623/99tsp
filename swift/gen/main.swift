//
//  main.swift
//  pl
//
//  Created by Michael Scaria on 11/28/16.
//  Copyright © 2016 michaelscaria. All rights reserved.
//

import Foundation

struct City {
    var x = 0.0
    var y = 0.0

    init() {

    }

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    func distance(from city: City) -> Double {
        let x_delta = x - city.x
        let y_delta = y - city.y
        return sqrt(pow(x_delta, 2) + pow(y_delta, 2))
    }
}

extension City: Equatable {
    static func ==(lhs: City, rhs: City) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

var allCities = [City]()

struct Tour {
    var cities = [City]() {
        didSet {
            fitness = 0.0
            distance = 0.0
        }
    }

    var size: Int {
        get {
            return cities.count
        }
    }


    var fitness = 0.0
    var distance = 0.0

    init() {
        for _ in 0..<allCities.count {
            cities.append(City())
        }
    }


    subscript(index: Int) -> City {
        get {
            return cities[index]
        }
        set {
            cities[index] = newValue
        }
    }


    func contains(city: City) -> Bool {
        return cities.contains(city)
    }

    mutating func getFitness() -> Double {
        if fitness == 0 {
            fitness = 1/getDistance()
        }
        return fitness
    }

    mutating func getDistance() -> Double {
        if distance == 0 {
            for (index, city) in cities.enumerated() {
                if index < cities.count - 1 {
                    distance += city.distance(from: cities[index + 1])
                }
            }
        }
        return distance
    }

    mutating func generateIndividual() {
        cities = allCities
        cities.sort { _,_ in arc4random_uniform(2) == 0 }
    }

}

struct Population {
    private var tours = [Tour]()

    var size: Int {
        get {
            return tours.count
        }
    }


    init(size: Int, initialize: Bool) {
        if initialize {
            for _ in 0..<size {
                var tour = Tour()
                tour.generateIndividual()
                tours.append(tour)
            }
        }
    }

    subscript(index: Int) -> Tour {
        get {
            return tours[index]
        }
        set {
            tours[index] = newValue
        }
    }

    func getFittest() -> Tour {
        var fittest = tours.first!
        for i in 0..<tours.count {
            var tour = tours[i]
            if fittest.getFitness() < tour.getFitness() {
                fittest = tour
            }
        }
        return fittest
    }


    mutating func add(tour: Tour) {
        tours.append(tour)
    }

}


struct Genetic {
    let mutationRate = 0.015
    let tournamentSize = 5
    let elitism = true

    func evolve(population: Population) -> Population {
        var newPop = Population(size: population.size, initialize: false)

        var offset = 0
        if elitism {
            newPop.add(tour: population.getFittest())
            offset = 1
        }

        for _ in offset..<population.size {
            let parent1 = select(from: population)
            let parent2 = select(from: population)
            let child = crossover(parent1: parent1, parent2: parent2)
            newPop.add(tour: child)
        }

        for i in offset..<population.size {
            newPop[i] = mutate(tour: newPop[i])
        }
        return newPop
    }

    func crossover(parent1: Tour, parent2: Tour) -> Tour {
        var child = Tour()

        var start = Int(arc4random_uniform(UInt32(parent1.size)))
        var end = Int(arc4random_uniform(UInt32(parent1.size)))
        // make sure start is less than end
        if start > end {
            let oldEnd = end
            end = start
            start = oldEnd
        }

        var takenSlots = [Int]()
        for i in 0..<allCities.count {
            if i > start && i < end {
                child[i] = parent1[i]
                takenSlots.append(i)
            }
        }

        for i in 0..<allCities.count {
            if !child.contains(city: parent2[i]) {
                for j in 0..<allCities.count {
                    if !takenSlots.contains(j) {
                        child[j] = parent2[j]
                        takenSlots.append(j)
                    }
                }
            }
        }

        return child
    }

    func mutate(tour t: Tour) -> Tour {
        var tour = t
        for pos1 in 0..<tour.size {
            if Double(arc4random_uniform(1000))/1000.0 < mutationRate {
                let pos2 = Int(arc4random_uniform(UInt32(tour.size)))

                let city1 = tour[pos1]
                let city2 = tour[pos2]

                tour[pos2] = city1
                tour[pos1] = city2
            }
        }
        return tour
    }

    func select(from population: Population) -> Tour {
        var tournamentPop = Population(size: tournamentSize, initialize: false)

        for i in 0..<tournamentSize {
            let random = Int(arc4random_uniform(UInt32(population.size)))
            tournamentPop[i] = population[random]
        }

        return tournamentPop.getFittest()
    }


}

func parse(file: [String]) {
    var i = 0
    for line in file {
        if (i > 5) {
            let comps = line.components(separatedBy: " ").filter { return $0 != "" }
            if comps.count == 3 {
                let city = City(x: Double(comps[1])!, y: Double(comps[2])!)
                allCities.append(city)
            }
        }
        i += 1
    }

    let genetic = Genetic()


    var pop = Population(size: allCities.count, initialize: true)
    var tour = pop.getFittest()
    print("Starting: \(tour.getDistance())")

    pop = genetic.evolve(population: pop)
}

let arguments = CommandLine.arguments
if arguments.count > 1 {
    let file = arguments[1]
    do {
        let content = try String(contentsOfFile:file, encoding: String.Encoding.utf8)
        parse(file: content.components(separatedBy: "\n"))
    } catch _ as NSError {}
}
