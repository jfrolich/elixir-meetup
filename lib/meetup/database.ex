defmodule Meetup.Database do
  @num_people 20

  defp random_seed(num \\ 101) do
    :rand.seed(:exsplus, {num, 1, 103})
  end

  defp pick_friend(friend_ids), do: Enum.random(friend_ids)

  defp pick_friends(potential_friend_ids, num, friend_ids \\ MapSet.new())
  defp pick_friends(_, 0, friend_ids), do: friend_ids

  defp pick_friends(potential_friend_ids, num, friend_ids) do
    new_friend = pick_friend(potential_friend_ids)
    potential_friend_ids = MapSet.delete(potential_friend_ids, new_friend)
    friend_ids = MapSet.put(friend_ids, new_friend)

    pick_friends(potential_friend_ids, num - 1, friend_ids)
  end

  defp all_friend_ids() do
    1..@num_people
    |> MapSet.new()
  end

  def get_friend_ids(id, opts \\ []) do
    IO.puts("GET  friend_ids: #{id}")
    first = Keyword.get(opts, :first, 5)
    random_seed(id)

    all_friend_ids()
    |> MapSet.delete(id)
    |> pick_friends(first)
  end

  def get_user(id) do
    IO.puts("GET  user: #{id}...")
    all()[id]
  end

  def get_many_users(ids) do
    IO.puts("MGET users: #{Enum.join(ids, ", ")}")

    for {id, user} <- all(), id in ids, into: %{} do
      {id, user}
    end
  end

  defp pick_best_friend_id(id) do
    random_seed(id)

    all_friend_ids()
    |> MapSet.delete(id)
    |> pick_friend()
  end

  defp build_person(id) do
    name = FakerElixir.Name.name()

    %{
      id: id,
      name: name,
      email_address: FakerElixir.Internet.email(name),
      best_friend_id: pick_best_friend_id(id)
    }
  end

  def all() do
    random_seed()

    Enum.map(1..@num_people, &{&1, build_person(&1)})
    |> Enum.into(%{})
  end
end
