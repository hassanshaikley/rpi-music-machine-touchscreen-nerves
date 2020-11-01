defmodule DrumMachineNerves.Components.PushButtons do
  @moduledoc """
  Push Buttons component

  With scenic we use two buttons to create the illusion of changing a buttons color.
  When a button is pressed, it is hidden and the opposite state button that sits directly
  underneath it is revealed.
  """

  # use Scenic.Scene, has_children: false
  use Scenic.Component, has_children: true

  import Scenic.{Components, Primitives}

  alias Scenic.{Graph, Primitive}

  def init(
        [button_width: button_width, button_height: button_height, buttons: buttons],
        _opts
      ) do
    graph =
      Graph.build()
      |> group(
        fn graph ->
          Enum.reduce(
            buttons,
            graph,
            fn obj, graph ->
              graph
              |> push_button(obj, button_width, button_height, :up, {200, 200, 200})
              |> push_button(obj, button_width, button_height, :down, {50, 240, 50})
            end
          )
        end,
        t: {16, 140}
      )

    state = %{
      graph: graph
    }

    {:ok, state, push: graph}
  end

  def verify(_), do: {:ok, nil}

  defp push_button(graph, obj, button_width, button_height, direction, background) do
    x = elem(obj, 0)
    y = elem(obj, 1)
    label = elem(obj, 2)
    id = Tuple.append(label, direction)
    # Initialize the down (pressed) button as hidden
    hidden = direction == :down

    button(graph, "",
      theme: %{
        text: :white,
        background: background,
        active: background,
        border: :green
      },
      hidden: hidden,
      id: id,
      translate: {x, y},
      height: button_height,
      width: button_width
    )
  end

  def handle_info(:loop, state \\ %{}) do
    IO.inspect("HELLLO FROM LOOP FROM PUSH BUTTONS PLS WOWRK")

    {:noreply, %{}, push: %{}}
  end

  def filter_event({:click, {col, row, :up} = id} = event, _context, state) do
    graph = toggle_button(id, true, state.graph)
    state = Map.put(state, :graph, graph)

    {:cont, event, state, push: graph}
  end

  def filter_event({:click, {col, row, :down} = id} = event, _context, state) do
    graph = toggle_button(id, false, state.graph)
    state = Map.put(state, :graph, graph)

    {:cont, event, state, push: graph}
  end

  # In scenic to show that a button is down you need two buttons
  # One for how it looks when it is up and another for how it looks when it is down
  # And then hide the inactive button
  defp toggle_button({col, row, _down}, button_down, state) do
    state
    |> Graph.modify({col, row, :down}, fn p ->
      Primitive.put_style(p, :hidden, !button_down)
    end)
    |> Graph.modify({col, row, :up}, fn p ->
      Primitive.put_style(p, :hidden, button_down)
    end)
  end
end
