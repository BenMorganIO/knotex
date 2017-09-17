defmodule Knot.HashTest do
  use ExUnit.Case, async: true
  doctest Knot.Hash
  alias Knot.Hash

  @hashable "a"
  @hash     <<202, 151, 129,  18, 202,  27, 189, 202,
              250, 194,  49, 179, 154,  35, 220,  77,
              167, 134, 239, 248,  20, 124,  78, 114,
              185, 128, 119, 133, 175, 238,  72, 187>>
  @short    "ca978112"
  @readable "ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb"

  describe "#hash" do
    test "uses SHA-256" do
      hash_of_a = Hash.perform @hashable
      assert hash_of_a == @hash
    end
  end

  describe "#readable" do
    test "downcases the result"do
      hash_readable = Hash.readable @hash
      assert hash_readable == @readable
    end

    test "allows option to change case" do
      hash_readable = Hash.readable @hash, case: :upper
      assert hash_readable == String.upcase(@readable)
    end
  end

  describe "#readable_short" do
    test "cuts the result" do
      hash_readable = Hash.readable_short @hash
      assert hash_readable == @short
    end

    test "allows option to change case" do
      hash_readable = Hash.readable_short @hash, case: :upper
      assert hash_readable == String.upcase(@short)
    end
  end

  describe "#ensure_hardness" do
    @bin_zer <<1, 1, 1, 1>>
    @bin_one <<0, 1, 1, 1>>
    @bin_two <<0, 0, 1, 1>>

    test "is true with enough zeros" do
      assert Hash.ensure_hardness(@bin_zer, 0) == :ok
      assert Hash.ensure_hardness(@bin_one, 1) == :ok
      assert Hash.ensure_hardness(@bin_two, 2) == :ok
    end

    test "is false with missing zeros" do
      assert Hash.ensure_hardness(@bin_zer, 1) == {:error, :unmet_difficulty}
      assert Hash.ensure_hardness(@bin_one, 2) == {:error, :unmet_difficulty}
      assert Hash.ensure_hardness(@bin_two, 3) == {:error, :unmet_difficulty}
    end
  end
end
