defmodule Redix.Stream do
  @moduledoc """
  Documentation for Redix.Stream.
  """

  @type redix :: pid() | atom()
  @type t :: String.t()
  @type handler :: {module(), atom(), list(any())}

  @doc """
  Produces a new single message into a Redis stream.

  Note: if values are not strings, they will be converted to strings.

  ## Examples

      iex> {:ok, msg_id} = Redix.Stream.produce(:redix, "topic", %{"temperature" => 55})
      iex> Enum.count(String.split(msg_id, "-"))
      2
  """
  @spec produce(redix, t, %{String.t() => any()}) :: {:ok, String.t()} | {:error, any()}
  def produce(redix, stream, key_values) do
    redis_command =
      key_values
      |> Enum.reduce(["*", stream, "XADD"], fn {k, v}, acc ->
        [to_string(v) | [k | acc]]
      end)
      |> Enum.reverse()

    case Redix.command(redix, redis_command) do
      {:ok, id} when is_binary(id) -> {:ok, id}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Provides a supervisable specification for a consumer which consumes
  from the given topic or topics.

  ## Examples

      iex> Redix.Stream.consumer_spec(:redix, "topic", fn msg -> msg end)[:id]
      Redix.Stream.Consumer

      iex> Redix.Stream.consumer_spec(:redix, "topic", {Module, :function, [:arg1, :arg2]})[:id]
      Redix.Stream.Consumer

      iex> Redix.Stream.consumer_spec(:redix, "topic", {Module, :function, [:arg1, :arg2]}, id: MyConsumer)[:id]
      MyConsumer
  """
  @spec consumer_spec(redix, t, function() | handler(), keyword()) :: Supervisor.child_spec()
  def consumer_spec(redix, stream, callback, opts \\ []) do
    Redix.Stream.Consumer.child_spec({redix, stream, callback, opts})
  end
end
