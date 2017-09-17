defmodule Knot.Block.Miner do
  @moduledoc """
  Provides an example of a working miner.

  It is not recommended to use it as such, as it is extremely slow compared to
  anything running at a lower level, eg C code.
  """

  alias Knot.{Block, Hash}

  @doc """
  Find a nonce matching the given block's difficulty.

  ## Examples

      iex> b = Knot.Block.Miner.mine %Knot.Block{}
      iex> [b.height, b.nonce, Knot.Hash.to_string(b.hash, short: true)]
      [0, 224, "00551db3"]
  """
  @spec mine(Block.t) :: Block.t
  def mine(block) do
    mining block, block.component_hash, 0, Block.difficulty(block.height)
  end

  @spec mining(Block.t, Hash.t, Block.nonce, Block.difficulty) :: Block.t
  defp mining(block, hash, nonce, diff) do
    candidate = Hash.perform [hash, nonce]
    case Hash.ensure_hardness candidate, diff do
      {:error, :unmet_difficulty} -> mining block, hash, nonce + 1, diff
                              :ok -> %{block | nonce: nonce, hash: candidate}
    end
  end
end
