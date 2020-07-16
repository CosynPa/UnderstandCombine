//
//  FilterPublisher1.swift
//  UnderstandCombine
//
//  Created by CosynPa on 2020/7/14.
//  Copyright © 2020 Pan Yusheng. All rights reserved.
//

import Foundation
import Combine

extension Publisher {
    func map1<T>(_ transform: @escaping (Output) -> T) -> MapPublisher1<Self, T> {
        return MapPublisher1(upstream: self, transform: transform)
    }
}

struct MapPublisher1<Upstream: Publisher, Output>: Publisher {
    typealias Failure = Upstream.Failure
    typealias Transform = (Upstream.Output) -> Self.Output

    class MapSubscription1<S: Subscriber>: Subscription where S.Input == Output, S.Failure == Failure {
        let publisher: MapPublisher1
        var subscriber: S?
        // Use weak to avoid retain cycle.
        // The sink closure retains the subscription, so the subscription shouldn't retain the sink
        weak var sink: Subscribers.Sink<Upstream.Output, Failure>?
        var numberSent = 0
        var demand = Subscribers.Demand.none

        init(publisher: MapPublisher1, subscriber: S) {
            self.publisher = publisher
            self.subscriber = subscriber
        }

        func request(_ demand: Subscribers.Demand) {
            self.demand = demand

            guard numberSent < demand else {
                subscriber = nil
                return
            }

            let aSink = Subscribers.Sink<Upstream.Output, Failure>(receiveCompletion: { [self] (completion) in
                self.subscriber?.receive(completion: completion)
                self.subscriber = nil
            }) { [self] (value) in
                if let subscriber = self.subscriber {
                    self.demand += subscriber.receive(self.publisher.transform(value))
                    self.numberSent += 1

                    if self.numberSent >= self.demand {
                        self.subscriber = nil
                        self.sink?.cancel()
                    }
                }
            }

            sink = aSink

            // Don't use the sink function, that way the first value may be received before you assign cancelHandler
            publisher.upstream.subscribe(aSink)
        }

        func cancel() {
            subscriber = nil
            sink?.cancel()
        }
    }

    let upstream: Upstream
    let transform: Transform

    init(upstream: Upstream, transform: @escaping Transform) {
        self.upstream = upstream
        self.transform = transform
    }

    func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Output == S.Input {
        let subscription = MapSubscription1(publisher: self, subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }
}
