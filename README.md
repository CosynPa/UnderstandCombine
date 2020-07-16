# Understand Combine

Combine is a Swift framework that deals with asynchronous events in a declarative manner. In this repository, we implement the `map` Publisher to help us understand how Publishers, Subscribers, Subscriptions work under the hood.

We implement map in two approaches. In the first approach, we create a custom Subscription. This way can help us understand how events happen in order. When the Publisher subscribes to a Subscriber, the `subscribe` function calls through `receive(subscriber:)`. Then a Subscription is created and the subscriber calls `receive(subscription:)`. In this function, the subscriber decides how many values it needs and make the subscription call `request(_ demand:)`. In the request function, the upstream Publisher is started and subscribed to.

Implementing a custom Subscription can let you have full knowledge about how many values the subscriber demands and how you cancel a subscription. But for the map Publisher, the number of events received from the map is exactly the same as the upstream Publisher, and cancelling the map Publisher is equivalent to cancelling the upstream Publisher. In this case, you don't need an extra Subscription, You can directly subscribe to the upstream Publisher and transform the values. This is how the second approach is implemented.
