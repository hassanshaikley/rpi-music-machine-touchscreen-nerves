defmodule RpiDrumMachineNerves.Component.StepIndicator do
  use Scenic.Scene, has_children: false
  import Scenic.Primitives
  import Scenic.Components

  def add_to_graph(
        graph,
        data \\ nil,
        [button_width: button_width, button_padding: button_padding, num_cols: num_cols] = _opts
      ) do
    # button_width = Keyword.get(opts, :button_width)
    # button_padding = Keyword.get(opts, :button_padding)
    # num_cols = Keyword.get(opts, :num_cols)

    graph
    |> group(
      fn graph ->
        Enum.map(0..(num_cols - 1), fn x ->
          {(button_width + button_padding) * x, button_padding, Integer.to_string(x)}
        end)
        |> Enum.reduce(
          graph,
          fn obj, graph ->
            x = elem(obj, 0)
            y = elem(obj, 1)
            index = elem(obj, 2)

            graph
            |> rect({button_width, 10},
              fill: :red,
              translate: {x, y},
              id: "h_#{index}"
            )
          end
        )
      end,
      t: {16, 160}
    )
  end

  def info(_data) do
  end

  def verify(_any) do
  end
end
