defmodule Gibbering.EventBus do
  @moduledoc """
  Port for the event bus (E) in the polytope compound bus B = (C, E).

  All cross-context event broadcasts and subscriptions go through this module.
  No bounded context calls `Phoenix.PubSub` directly — that is an adapter
  implementation detail.

  Active adapter is read from application config at call time:

      config :gibbering, Gibbering.EventBus, adapter: Gibbering.EventBus.PubSub

  Available adapters:
  - `Gibbering.EventBus.PubSub` — Phoenix.PubSub (production, integration tests)
  - `Gibbering.EventBus.Local`  — synchronous in-memory (unit tests, no PubSub process)

  See `docs/papers/polytope-architecture.md` §3.3, §6.3, §10.3.
  """

  @doc "Broadcast a message to all subscribers of `topic`."
  @callback broadcast(topic :: String.t(), message :: term()) :: :ok | {:error, term()}

  @doc "Broadcast a `%Gibbering.Events.EventBatch{}` to all subscribers of `topic`."
  @callback broadcast_batch(topic :: String.t(), batch :: struct()) :: :ok | {:error, term()}

  @doc "Subscribe the calling process to `topic`."
  @callback subscribe(topic :: String.t()) :: :ok | {:error, term()}

  @doc "Unsubscribe the calling process from `topic`."
  @callback unsubscribe(topic :: String.t()) :: :ok | {:error, term()}

  defp adapter do
    Application.get_env(:gibbering, __MODULE__, [])
    |> Keyword.get(:adapter, Gibbering.EventBus.PubSub)
  end

  @doc "Broadcast a message to all subscribers of `topic`."
  def broadcast(topic, message), do: adapter().broadcast(topic, message)

  @doc "Broadcast a `%Gibbering.Events.EventBatch{}` to all subscribers of `topic`."
  def broadcast_batch(topic, batch), do: adapter().broadcast_batch(topic, batch)

  @doc "Subscribe the calling process to `topic`."
  def subscribe(topic), do: adapter().subscribe(topic)

  @doc "Unsubscribe the calling process from `topic`."
  def unsubscribe(topic), do: adapter().unsubscribe(topic)
end
