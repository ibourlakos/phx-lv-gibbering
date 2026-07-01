defmodule Gibbering.EventBus.PubSub do
  @moduledoc """
  `Gibbering.EventBus` adapter backed by `Phoenix.PubSub`.
  Used in production and in integration tests where the full PubSub server runs.
  """

  @behaviour Gibbering.EventBus

  @pubsub Gibbering.PubSub

  @impl Gibbering.EventBus
  def broadcast(topic, message) do
    Phoenix.PubSub.broadcast(@pubsub, topic, message)
  end

  @impl Gibbering.EventBus
  def broadcast_batch(topic, batch) do
    Phoenix.PubSub.broadcast(@pubsub, topic, batch)
  end

  @impl Gibbering.EventBus
  def subscribe(topic) do
    Phoenix.PubSub.subscribe(@pubsub, topic)
  end

  @impl Gibbering.EventBus
  def unsubscribe(topic) do
    Phoenix.PubSub.unsubscribe(@pubsub, topic)
  end
end
