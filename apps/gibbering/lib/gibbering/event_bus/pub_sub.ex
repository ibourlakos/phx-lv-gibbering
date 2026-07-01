defmodule Gibbering.EventBus.PubSub do
  @moduledoc """
  `GibberingEngine.EventBus` adapter backed by `Phoenix.PubSub`.
  Used in production and in integration tests where the full PubSub server runs.
  """

  @behaviour GibberingEngine.EventBus

  @pubsub Gibbering.PubSub

  @impl GibberingEngine.EventBus
  def broadcast(topic, message) do
    Phoenix.PubSub.broadcast(@pubsub, topic, message)
  end

  @impl GibberingEngine.EventBus
  def broadcast_batch(topic, batch) do
    Phoenix.PubSub.broadcast(@pubsub, topic, batch)
  end

  @impl GibberingEngine.EventBus
  def subscribe(topic) do
    Phoenix.PubSub.subscribe(@pubsub, topic)
  end

  @impl GibberingEngine.EventBus
  def unsubscribe(topic) do
    Phoenix.PubSub.unsubscribe(@pubsub, topic)
  end
end
