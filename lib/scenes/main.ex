defmodule DrumMachineNerves.Scene.Main do
  @moduledoc """
  Main scene
  """

  use Scenic.Scene

  alias Scenic.Graph
  alias Scenic.Primitive
  import Scenic.Primitives

  alias DrumMachineNerves.Components.{
    Header,
    OffButton,
    PushButtons,
    StepIndicator,
    VolumeSlider
  }

  @bpm 80
  @bpm_in_ms trunc(60_000 / @bpm)

  @width 800
  @height 480

  @num_rows 5
  @num_cols 4

  # @button_width 46 * 1.5
  # @button_height @button_width
  # @button_padding 2 * 1.5

  @button_width 60
  @button_height @button_width
  @button_padding 4

  # Tuples for every button containing {the left most x value, the top most y value, and the unique button id}
  # This is only used to build the UI
  @buttons Enum.map(0..(@num_cols - 1), fn x ->
             Enum.map(0..(@num_rows - 1), fn y ->
               {(@button_width + @button_padding) * x, (@button_height + @button_padding) * y,
                {x, y}}
             end)
           end)
           |> List.flatten()

  @main_menu_graph Graph.build(font: :roboto, font_size: 16)
                   #  |> rect({@width, @height},
                   #    id: :background,
                   #    fill: {50, 50, 50}
                   #  )
                   |> Header.add_to_graph()
                   #  |> OffButton.add_to_graph()
                   |> VolumeSlider.add_to_graph()
                   |> StepIndicator.add_to_graph(nil,
                     button_width: @button_width,
                     button_padding: @button_padding,
                     num_cols: @num_cols
                   )
                   |> PushButtons.add_to_graph(
                     button_width: @button_width,
                     button_height: @button_height,
                     buttons: @buttons
                   )

  def init(_, _) do
    state =
      @main_menu_graph
      |> Map.put(:iteration, 0)
      |> Map.put(
        :button_state,
        Enum.reduce(0..(@num_cols - 1), %{}, fn col, acc ->
          acc
          |> Map.put(:"#{col}_0", false)
          |> Map.put(:"#{col}_1", false)
          |> Map.put(:"#{col}_2", false)
          |> Map.put(:"#{col}_3", false)
          |> Map.put(:"#{col}_4", false)
        end)
      )

    :os.cmd('espeak -ven+f5 -k5 -w /tmp/out.wav Hello')
    :os.cmd('aplay -q /tmp/out.wav')

    # Start after a second to give the app a chance to initialize
    Process.send_after(self(), :loop, 1000, [])

    {:ok, state, push: state}
  end

  # ============================================================================
  # event handlers
  # --------------------------------------------------------

  def filter_event({:click, {col, row, :up} = id}, _context, state) do
    updated_state =
      toggle_button(id, true, state)
      |> update_state(row, col, true)

    {:noreply, updated_state, push: updated_state}
  end

  def filter_event({:click, {col, row, :down} = id}, _context, state) do
    updated_state =
      toggle_button(id, false, state)
      |> update_state(row, col, false)

    {:noreply, updated_state, push: updated_state}
  end

  def filter_event({:click, "shutdown"}, _context, state) do
    spawn(fn -> :os.cmd('sudo shutdown -h now') end)
    {:noreply, state}
  end

  def filter_event({:value_changed, _id, value}, _context, state) do
    AudioPlayer.set_volume(value)
    {:noreply, state}
  end

  # Code that is run each beat
  def handle_info(:loop, state) do
    # start_time = Time.utc_now()

    current_iteration = state.iteration
    next_iteration = get_next_iteration(current_iteration)

    if sound_playing?(current_iteration, 0, state), do: AudioPlayer.play_sound("hihat.wav")
    if sound_playing?(current_iteration, 1, state), do: AudioPlayer.play_sound("snare.wav")
    if sound_playing?(current_iteration, 2, state), do: AudioPlayer.play_sound("triangle.wav")
    if sound_playing?(current_iteration, 3, state), do: AudioPlayer.play_sound("runnerskick.wav")
    if sound_playing?(current_iteration, 4, state), do: AudioPlayer.play_sound("hitoms.wav")

    updated_state =
      state
      |> update_step_indicator
      |> Map.put(:iteration, next_iteration)

    Process.send_after(self(), :loop, @bpm_in_ms)

    # Time.diff(start_time, Time.utc_now(), :microsecond) |> IO.inspect()
    {:noreply, updated_state, push: updated_state}
  end

  def handle_input(_msg, _, state) do
    {:noreply, state}
  end

  ####### '.###
  # Private.` #
  ########### `

  defp sound_playing?(iteration, row, state) do
    Map.get(state.button_state, :"#{iteration}_#{row}")
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

  defp update_step_indicator(state) do
    state
    |> Graph.modify({state.iteration, :h}, fn p ->
      Primitive.put_style(p, :fill, :blue)
    end)
    |> Graph.modify({get_previous_iteration(state.iteration), :h}, fn p ->
      Primitive.put_style(p, :fill, :red)
    end)
  end

  defp update_state(state, row, col, button_down) do
    new_button_state = Map.put(state.button_state, :"#{col}_#{row}", button_down)
    Map.put(state, :button_state, new_button_state)
  end

  defp get_next_iteration(iteration) when iteration == 0, do: 1
  defp get_next_iteration(iteration) when iteration == 1, do: 2
  defp get_next_iteration(iteration) when iteration == 2, do: 3
  # defp get_next_iteration(iteration) when iteration == 3, do: 4
  # defp get_next_iteration(iteration) when iteration == 4, do: 5
  # defp get_next_iteration(iteration) when iteration == 5, do: 6
  # defp get_next_iteration(iteration) when iteration == 6, do: 7
  # defp get_next_iteration(iteration) when iteration == 7, do: 8
  # -- kill this one defp get_next_iteration(iteration) when iteration == 8, do: 0
  defp get_next_iteration(iteration) when iteration == @num_cols - 1, do: 0

  defp get_previous_iteration(iteration) when iteration == 0, do: @num_cols - 1
  defp get_previous_iteration(iteration) when iteration == 1, do: 0
  defp get_previous_iteration(iteration) when iteration == 2, do: 1
  defp get_previous_iteration(iteration) when iteration == 3, do: 2
  # defp get_previous_iteration(iteration) when iteration == 4, do: 3
  # defp get_previous_iteration(iteration) when iteration == 5, do: 4
  # defp get_previous_iteration(iteration) when iteration == 6, do: 5
  # defp get_previous_iteration(iteration) when iteration == 7, do: 6
  # defp get_previous_iteration(iteration) when iteration == 8, do: 7

  defp debug(g), do: Graph.modify(g, :debug, &text(&1, output))

end
