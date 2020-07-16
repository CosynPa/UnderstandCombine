//
//  FilterPublisher2.swift
//  UnderstandCombine
//
//  Created by CosynPa on 2020/7/14.
//  Copyright © 2020 Pan Yusheng. All rights reserved.
//

import Foundation
import Combine

extension Publisher {
    func map2<T>(_ transform: @escaping (Output) -> T) -> MapPublisher2<Self, T> {
        return MapPublisher2(upstream: self, transform: transform)
    }
}

struct MapPublisher2<Upstream: Publisher, Output>: Publisher {
    typealias Failure = Upstream.Failure
    typealias Transform = (Upstream.Output) -> Self.Output

    class MapSubscriber2<S: Subscriber>: Subscriber where S.Input == Output, S.Failure == Failure {
        typealias Input = Upstream.Output

        let downstream: S
        let transform: Transform

        init(downstream: S, transform: @escaping Transform) {
            self.downstream = downstream
            self.transform = transform
        }

        func receive(subscription: Subscription) {
            downstream.receive(subscription: subscription)
        }

        func receive(_ input: Input) -> Subscribers.Demand {
            // Here you have some extra freedom to manage the demand. Not needed here in Map though.
            return downstream.receive(transform(input))
        }

        func receive(completion: Subscribers.Completion<Failure>) {
            downstream.receive(completion: completion)
        }
    }

    let upstream: Upstream
    let transform: Transform

    init(upstream: Upstream, transform: @escaping Transform) {
        self.upstream = upstream
        self.transform = transform
    }

    func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Output == S.Input {
        let mapSubscriber = MapSubscriber2(downstream: subscriber, transform: transform)
        upstream.receive(subscriber: mapSubscriber)
    }
}
