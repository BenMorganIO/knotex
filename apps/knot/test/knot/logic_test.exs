defmodule Knot.LogicTest do
  use ExUnit.Case
  alias Knot.Logic
  doctest Logic
  require Logger

  @uri          URI.parse "tcp://localhost:4001"

  describe "for message handling" do
    setup :logic

    test "allows to query its pid", %{logic: logic} do
      assert logic == GenServer.call(logic, :pid)
    end
  end

  # TODO: Spec :on_listener_terminating, :on_client_socket message,
  # :on_client_ready, :on_client_data and :on_client_closed messages.

  describe "#deserialize" do
    test "correctly de-serializes data" do
      data = {:foo, "bar"}
      assert Knot.Logic.deserialize(Bertex.encode data) == {:ok, data}
    end

    test "describes the error on failure" do
      err = {:error, %ArgumentError{message: "argument error"}}
      assert Knot.Logic.deserialize(:bad_data) == err
    end
  end

  describe "#on_client_data" do
    test "answers when pinged" do
      # TODO: Stub a client and test:
      #   Logic.on_client_data(%{uri: nil}, nil, {:ping, 1})
    end
  end

  describe "#process_block_query" do
    test "handles :genesis query" do
      res = Logic.process_block_query :genesis, state(), nil
      assert res == Block.genesis()
    end

    test "handles :highest query" do
      res = Logic.process_block_query :highest, state(), nil
      assert res == hd(state().chain)
    end

    test "handles :ancestry query when provided with a valid hash" do
      query = {:ancestry, Hash.from_string("d4735e3a265e16eee03f59718b9b5d03019c07d8b6c51f90da3a666eec13ab35")}
      res = Logic.process_block_query query, nil, nil
      assert res == state().chain
    end

    test "handles :ancestry query when provided with an invalid hash" do
      query = {:ancestry, Hash.invalid}
      res = Logic.process_block_query query, nil, nil
      assert res == {:error, :unknown_block_hash}
    end

    test "returns an error when an invalid query is passed" do
      res = Logic.process_block_query {:invalid, "query"}, nil, nil
      assert res == {:error, :invalid_block_query}
    end
  end

  defp logic(ctx) do
    uri = URI.parse "tcp://localhost:4001"
    {:ok, logic} = Logic.start_link uri

    {:ok, Map.put(ctx, :logic, logic)}
  end

  defp state do
    b0 = Block.genesis() |> Block.Store.store
    b1 = make_parented_block 1, b0
    b2 = make_parented_block 2, b1
    b3 = make_parented_block 3, b2
    %Logic.State{uri: @uri, chain: [b3, b2, b1, b0]}
  end

  defp make_parented_block(id, parent) do
    hash = Hash.perform "#{id}"
    hash
      |> Block.new(id)
      |> Map.put(:height, id)
      |> Map.put(:parent_hash, parent.hash)
      |> Map.put(:hash, hash)
      |> Block.seal
      |> Block.Store.store
  end
end
