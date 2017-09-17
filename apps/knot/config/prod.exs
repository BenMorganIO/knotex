use Mix.Config

config :knot,
  block_store_backend: :dets,
  genesis_data: %{
    timestamp: 1490926154,
    nonce: 3492211,
    parent_hash: Base.decode16!(
      "0000000000000000000000000000000000000000000000000000000000000000"
    ),
    content_hash: Base.decode16!(
      "1CB4F6428A67E932852B9DDF1B71F6668487B62D5E7A1F808A9173726EDCB5F3"
    ),
    component_hash: Base.decode16!(
      "C5387350D983F75ED62EEF3A5E904E7ECB0F182AF6ECB9A0966D521D39747BBB"
    ),
    hash: Base.decode16!(
      "0000007B5786C03293981D893C65DA1193123C9367A1FDDC56CD8A3658A93470"
    )
  }
