defmodule Cache.CacheAgent do
  @moduledoc """
  Maintains a LRU cache.

  Uses an an Agent to maintain the values.
  """

  use Agent

  @max_size 3

  @doc """
  Use this so can clear it between tests, for independent runs.
  """
  def clear_state() do
    Agent.update(__MODULE__, fn _state -> initial_state() end)
  end

  def initial_state() do
    %{map: %{}, tree: :gb_trees.empty()}
  end

  def start_link(_initial_value) do
    state = initial_state()

    Agent.start_link(fn -> state end, name: __MODULE__)
  end

  @doc """
  Returns the Agent state, for dev/debugging.
  """
  def get_state() do
    Agent.get(__MODULE__, fn state -> state end)
    |> prep_state_for_output()
  end

  defp prep_state_for_output(state) do
    %{map: state_map, tree: state_tree} = state
    %{map: state_map, tree: :gb_trees.to_list(state_tree)}
  end

  @doc """
  Get the value associated with key, updating internal state to
  mark this key's relative access time as being touched.

  The Agent's state is a Map %{map: state_map, tree: state_tree}.

  state_map: Map of key => {val, id}, where id is a
  monotonically-increasing unique identifier.
  state_tree: A :gb_trees instance of id => key_from_state_map

  Calls `Agent.get_and_update/2` to get the current value for key, and update
    the Agent's state Map's value for key to a fresh id.

  That Map update is done via `Map.get_and_update/2`, which returns the current
  {val, current_ts} for key, and the new state.
  """
  def get(key) do
    Agent.get_and_update(__MODULE__, fn state ->
      # Return from this fn passed to Agent.get_and_update/2
      # is a tuple of the val to return and the new state
     %{map: state_map, tree: state_tree} = state

      case map_get_and_update(state_map, key) do
        {nil, _state} ->
          # key was not found
          {nil, state}

        {{val, id_cur}, state_map_new} ->
          # Delete id_cur from gb_tree
          state_tree = :gb_trees.delete_any(id_cur, state_tree)

          # Add {id_new, key) to gb_tree
          {_val, id_new} = state_map_new[key]
          state_tree = :gb_trees.enter(id_new, key, state_tree)

          {val, %{state | map: state_map_new, tree: state_tree}}
      end
    end)
  end

  @doc """
  Return: {value_obtained_for_key, state_map_new}

  state_map_new will have a new value for key inserted, being
  {val, id_new}

  value_obtained_for_key will be nil if key is not found.
  """
  def map_get_and_update(state_map, key) do
    Map.get_and_update(state_map, key, fn
      # Return from this fn passed into Map.get_and_update/2
      # {value, new_value}, or :pop if not found
      nil ->
        :pop

      {val, _ts_cur} = tup ->
        id_new = generate_id()
        {tup, {val, id_new}}
    end)
  end

  @doc """
  Add key => val, setting a unique identifier in internal state to
  mark this insertion's relative access time as being just inserted.

  The Agent's state is a Map %{map: state_map, tree: state_tree}.

  state_map: Map of key => {val, id}, where id is a
  monotonically-increasing unique identifier.
  state_tree: A :gb_trees instance of id => key_from_state_map

  Calls `Agent.get_and_update/2` to get the current value for key, and put
    the Agent's state Map's value for val and new_ts.

  That Map update is done via `Map.get_and_update/2`, which returns the current
  {val, current_ts} for key, and the new state.
  """
  def put(key, val) do
    Agent.get_and_update(__MODULE__, fn state ->
      # Return from this fn passed to Agent.get_and_update/2
      # is a tuple of the val to return and the new state
      #%{map: state_map, tree: state_tree} = state
      size = map_size(state.map)

      state =
        cond do
          # No need to remove is not full yet
          size < @max_size ->
            state

          # At max size, but we're just going to be replacing key,
          # resulting in same size, so no need to remove
          size == @max_size and Map.has_key?(state.map, key) ->
            state

          # At max size, and adding new key, so need to remove oldest
          # resulting in same size, so no need to remove
          size == @max_size and not Map.has_key?(state.map, key) ->
            remove_oldest(state)

          # Intentionally it it fail if size > @max_size, as that should never happen
        end

      %{map: state_map, tree: state_tree} = state

      case map_put_and_update(state_map, key, val) do
        {nil, state_map_new} ->
          # key was not found
          # Add {id_new, key) to gb_tree
          {_val, id_new} = state_map_new[key]
          state_tree = :gb_trees.enter(id_new, key, state_tree)

          {val, %{state | map: state_map_new, tree: state_tree}}

        {{_val_cur, id_cur}, state_map_new} ->
          # Delete id_cur from gb_tree
          state_tree = :gb_trees.delete_any(id_cur, state_tree)

          # Add {id_new, key) to gb_tree
          {_val, id_new} = state_map_new[key]
          state_tree = :gb_trees.enter(id_new, key, state_tree)

          {val, %{state | map: state_map_new, tree: state_tree}}
      end
    end)
  end

  @doc """
  Remove the oldest state entry.

  Get/remove the smallest entry from state_tree, which is
  a :gb_trees instance of id => key_from_state_map.

  Use key_from_state_map to remove entry from state_map.
  """
  def remove_oldest(state) do
    %{map: state_map, tree: state_tree} = state

    {_ts, key_from_state_map, state_tree} = :gb_trees.take_smallest(state_tree)

    # Raises if key is not present, since that would an error.
    {_popped, state_map} = Map.pop!(state_map, key_from_state_map)

    %{state | map: state_map, tree: state_tree}
  end

  @doc """
  TODO:
  Return: {value_obtained_for_key, state_map_new}

  state_map_new will have a new value for key inserted, being
  {val, id_new}

  value_obtained_for_key will be nil if key is not found.
  """
  def map_put_and_update(state_map, key, val) do
    Map.get_and_update(state_map, key, fn
      val_ts_cur_or_nil ->
        id_new = generate_id()
        {val_ts_cur_or_nil, {val, id_new}}
    end)
  end

  defp generate_id() do
    System.unique_integer([:positive, :monotonic])
  end

end
