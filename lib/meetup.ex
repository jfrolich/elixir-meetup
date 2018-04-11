defmodule Meetup do
  alias Meetup.Database
  import Defer

  defmodule Users do
    def get(id) do
      Database.get_user(id)
    end

    def get_friend_ids(user_id, opts \\ []) do
      Database.get_friend_ids(user_id, opts)
    end
  end

  defmodule LazyUsers do
    defer def get(id) do
      Lazyloader.get(:database, :get_user, id)
    end

    defer def get_friend_ids(user_id, _opts \\ []) do
      Lazyloader.get(:database, :get_friend_ids, user_id)
    end
  end

  defer def lazy_load_friend(id) do
    friend = await(LazyUsers.get(id))
    best_friend = await(LazyUsers.get(friend.best_friend_id))

    %{
      name: friend.name,
      best_friend: %{
        name: best_friend.name
      }
    }
  end

  defer def lazy_load_profile do
    user = await(LazyUsers.get(1))
    best_friend = await(LazyUsers.get(user.best_friend_id))
    friend_ids = await(LazyUsers.get_friend_ids(user.id, first: 5))
    friends = await(Enum.map(friend_ids, &lazy_load_friend(&1)))

    %{
      name: user.name,
      best_friend: %{
        name: best_friend.name
      },
      friends: friends
    }
  end

  def load_friend(id) do
    friend = Users.get(id)
    best_friend = Users.get(friend.best_friend_id)

    %{
      name: friend.name,
      best_friend: %{
        name: best_friend.name
      }
    }
  end

  def load_profile() do
    user = Users.get(1)
    best_friend = Users.get(user.best_friend_id)
    friend_ids = Users.get_friend_ids(user.id)
    friends = Enum.map(friend_ids, &load_friend(&1))

    %{
      name: user.name,
      best_friend: %{
        name: best_friend.name
      },
      friends: friends
    }
  end

  def main(["lazyloader"]) do
    source = Dataloader.KV.new(&query(&1, &2))

    loader =
      Dataloader.new()
      |> Dataloader.add_source(:database, source)

    lazy_load_profile()
    IO.inspect(Defer.run(lazy_load_profile(), dataloader: loader))
  end

  def main(_args) do
    IO.inspect(load_profile())
  end

  defp query(:get_user, ids) do
    Database.get_many_users(ids)
  end

  defp query(:get_friend_ids, ids) do
    for id <- ids, into: %{} do
      {id, Database.get_friend_ids(id)}
    end
  end
end
