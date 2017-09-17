defmodule Knot.Block do
  @moduledoc """
  Models the functionality of a block.

  A `Block` exposes a number of hashes that are computed based on
  the block's underlying data.

  The block's height, timestamp, parent hash and content hash are user defined,
  while the component hash, the nonce and the hash should be computed by this
  module.
  """
  alias __MODULE__, as: Block
  alias Knot.Hash
  alias Knot.Block.Store

  @zero_hash Hash.zero()
  @genesis_data Application.get_env :knot, :genesis

  @type          id :: String.t | Hash.t
  @type   timestamp :: non_neg_integer
  @type      height :: non_neg_integer
  @type  difficulty :: non_neg_integer
  @type       nonce :: non_neg_integer

  @type mismatch_error :: {:error, :component_hash_mismatch | :hash_mismatch}

  @type t :: %Block{
    # Variable fields, user-accessible.
                height: height,
             timestamp: Block.timestamp,
           parent_hash: Hash.t,
          content_hash: Hash.t,
    # Those are automatically handled.
        component_hash: Hash.t,
    # These are for the block hash.
                 nonce: nonce,
                  hash: Hash.t
  }

  defstruct [
    # Variable fields, user-accessible.
                height: 0,
             timestamp: nil,
           parent_hash: Hash.invalid,
          content_hash: Hash.invalid,
    # Those are automatically handled.
        component_hash: Hash.invalid,
    # These are for the block hash.
                 nonce: 0,
                  hash: Hash.invalid
  ]

  @doc """
  Creates a new block given a timestamp and a content hash.

  ## Examples

      iex> Knot.Block.new <<1>>, 382_921_200
      %Knot.Block{content_hash: <<1>>, timestamp: 382_921_200}

  """
  @spec new(Hash.t, Block.timestamp) :: Block.t
  def new(content_hash, timestamp) do
    %Block{timestamp: timestamp, content_hash: content_hash}
  end

  @doc """
  Assigns a parent block to a given block, and sets the hashes and height
  accordingly.
  """
  @spec as_child_of(Block.t, Block.t) :: Block.t
  def as_child_of(block, %{height: p_height, hash: p_hash}) do
    %{block | height: p_height + 1, parent_hash: p_hash}
  end

  @doc """
  Returns the genesis block. A genesis block should have its parent hash set to
  a 32 bytes zero'ed binary and have a height of 0.

  ## Example

      iex> g = Knot.Block.genesis()
      iex> [g.height, g.nonce, g.timestamp]
      [0, 3492211, 1490926154]
  """
  @spec genesis :: Block.t
  def genesis, do: Map.merge %Block{}, @genesis_data

  @doc """
  Verifies the validity of a single block by checking that:
  - `parent_hash`, `content_hash`, `component_hash` or `hash` are valid,
  - The content and component hash were properly sealed,
  - The block's hash and nonce are a solution.
  """
  @spec ensure_final(Block.t) :: boolean | mismatch_error
  def ensure_final(block) do
    check = block
      |> strip
      |> seal
      |> hash

    cond do
      check.component_hash != block.component_hash ->
        {:error, :component_hash_mismatch}
      check.hash != block.hash ->
        {:error, :hash_mismatch}
      true ->
        Hash.ensure_hardness check.hash, Block.difficulty(check.height)
    end
  end

  @doc """
  Hashes the block components to prevent any further modification.

  Once a block is sealed, it can safelly be mined. Sealing a block that was
  already sealed is acceptable, and often performed to verify whether the new
  seal matches the previous one, ensuring that the previous seal was correct.

  ## Examples

      iex> %Knot.Block{}
      iex>   |> Knot.Block.seal
      iex>   |> Map.get(:component_hash)
      iex>   |> Knot.Hash.readable_short
      "e3f001a9"
  """
  @spec seal(Block.t) :: Block.t
  def seal(block) do
    [block.height, block.timestamp, block.parent_hash, block.content_hash]
      |> Enum.join("_")
      |> hash_into(block, :component_hash)
  end

  @spec strip(Block.t) :: Block.t
  defp strip(
    %{height: h, timestamp: t, parent_hash: p, content_hash: c, nonce: n}
  ) do
    %Block{height: h, timestamp: t, parent_hash: p, content_hash: c, nonce: n}
  end

  @spec hash(Block.t) :: Block.t
  defp hash(%{component_hash: h, nonce: n} = block) do
    %{block | hash: Hash.perform([h, n])}
  end

  @spec hash_into(String.t, Block.t, atom) :: Block.t
  defp hash_into(value, block, key) do
    %{block | key => Hash.perform(value)}
  end

  # ====================================================================== #

  @doc """
  Verifies whether a given `block` was properly mined or not.

  The checks ensure that:
  - The block's ancestry is well known,
  - The block is final.
  """
  @spec mined?(Block.t) :: boolean
  def mined?(block) do
    with :ok <- ensure_known_parent(block),
         :ok <- Block.ensure_final(block)
      do true
    else
      _ -> false
    end
  end

  @doc "Given a `block`, returns its full ancestry chain."
  @spec ancestry(Block.t, integer)
                :: {:ok, list(Block.t)} | {:error, atom}
  def ancestry(block, n \\ -1) do
    ancestry block, n, []
  end
  @spec ancestry(Block.t, integer, list(Block.t))
                :: {:ok, list(Block.t)} | {:error, atom}
  def ancestry(%{parent_hash: p_hash}, n, ancestors)
      when n == 0 or p_hash == @zero_hash do
    {:ok, Enum.reverse ancestors}
  end
  def ancestry(%{parent_hash: p_hash}, n, ancestors) do
    case Store.find_by_hash(p_hash) do
      {:ok, parent} -> ancestry parent, n - 1, [parent] ++ ancestors
                err -> err
    end
  end

  @doc "Verifies all of a given `block`'s parents are well known."
  @spec ensure_known_parent(Block.t) :: :ok
  def ensure_known_parent(%{height: height, parent_hash: p_hash}) do
    case Store.find_by_hash_and_height(p_hash, height - 1) do
      {:ok, _}    -> :ok
      {:error, _} -> {:error, :unknown_parent}
    end
  end

  @doc "Checks whether a given `block`'s ancestry contains a `block` or not."
  @spec ancestry_contains?(Block.t, Block.t | Hash.t) :: boolean
  def ancestry_contains?(b, %Block{} = a), do: ancestry_contains? b, a.hash
  def ancestry_contains?(%{parent_hash: ph}, ph), do: true
  def ancestry_contains?(%{parent_hash: @zero_hash}, _), do: false
  def ancestry_contains?(%{parent_hash: p_hash}, hash) do
    case Store.find_by_hash p_hash do
      {:ok, parent} -> ancestry_contains? parent, hash
                err -> err
    end
  end

  @doc "Given a block's `height`, computes its required difficulty."
  @spec difficulty(Block.t | Block.height) :: difficulty
  def difficulty(%Block{height: h}), do: difficulty h
  def difficulty(height) do
    height
      |> Kernel./(128)
      |> Float.floor
      |> round
      |> Kernel.+(1)
  end
end
