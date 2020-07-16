//
//  main.swift
//  UnderstandCombine
//
//  Created by CosynPa on 2020/7/14.
//  Copyright © 2020 Pan Yusheng. All rights reserved.
//

import Foundation
import Combine

class MySubscriber: Subscriber, Cancellable {
    typealias Output = Int
    typealias Failure = Never

    let demand: Subscribers.Demand
    let cancelWhenDemandMet: Bool

    var numberReceived = 0

    var subscription: Cancellable?

    init(demand: Subscribers.Demand, cancelWhenDemandMet: Bool = true) {
        self.demand = demand
        self.cancelWhenDemandMet = cancelWhenDemandMet
    }

    func receive(_ input: Output) -> Subscribers.Demand {
        NSLog("value \(input)")
        numberReceived += 1

        if cancelWhenDemandMet {
            // Some implementation of publisher or subscription don't cancel it when the demand is met.
            // That can cause holding the resource by the publisher or retaining the subscriber for a long time
            // So we do it explicitly
            if numberReceived >= demand {
                subscription?.cancel()
                subscription = nil
            }
        }

        return .none
    }

    func receive(completion: Subscribers.Completion<Failure>) {
        NSLog("complete")
    }

    func receive(subscription: Subscription) {
        NSLog("subscribtion")
        self.subscription = subscription
        subscription.request(demand)
    }

    func cancel() {
        subscription?.cancel()
    }

    deinit {
        NSLog("deinit subscriber")
    }
}

func getSubject() -> PassthroughSubject<Int, Never> {
    let subject = PassthroughSubject<Int, Never>()

    for i in 0 ..< 5 {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)) {
            subject.send(i)

            if i == 5 - 1 {
                subject.send(completion: .finished)
            }
        }
    }

    return subject
}

// The publishers returned by getSubject and getFlatMapped are basically the same.
// But some implementation details may cause some slightly different behaviors.
func getFlatMapped() -> AnyPublisher<Int, Never> {
    return (0 ..< 5).publisher
        .flatMap { (x) in
            Just(x).delay(for: .seconds(Double(x)), scheduler: DispatchQueue.main)
        }
        .eraseToAnyPublisher()
}

getSubject()
    .map1 { x in x + 1 }
    .subscribe(MySubscriber(demand: .max(3)))

DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
    NSLog("exit")
    exit(EXIT_SUCCESS)
}

dispatchMain()
