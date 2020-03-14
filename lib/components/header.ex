defmodule RpiDrumMachineNerves.Component.Header do
  use Scenic.Scene, has_children: false
  import Scenic.Primitives

  def add_to_graph(graph, _data \\ nil, _opts \\ []) do
    graph
    |> group(
      fn graph ->
        graph
        |> rect({780, 75},
          fill: :dark_gray,
          translate: {0, 0}
        )
        |> text("Nerves Drum Machine",
          id: :pos,
          translate: {630, 60},
          font_size: 16,
          fill: :black
        )
      end,
      id: :header,
      t: {10, 10}
    )
  end

  def info(_data) do
  end

  def verify(_any) do
  end
end
