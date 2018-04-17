defmodule ExampleDataloader do
  def get_users(loader) do
    loader =
      loader
      |> Dataloader.load(:db, :get_user, 1)
      |> Dataloader.load(:db, :get_user, 2)
      |> Dataloader.run()

    user_1 = Dataloader.get(loader, :db, :get_user, 1)
    user_2 = Dataloader.get(loader, :db, :get_user, 1)

    %{user_1: user_1, user_2: user_2}
  end
end

defmodule ExampleThen do
  def get_users() do
    [
      Lazyloader.get(:db, :get_user, 1),
      Lazyloader.get(:db, :get_user, 2)
    ]
    |> Defer.then(fn [user_1, user_2] ->
      %{user_1: user_1, user_2: user_2}
    end)
  end

  def get_users(loader) do
    get_users()
    |> Defer.run(%{dataloader: loader})
  end
end

defmodule ExampleDefer do
  import Defer

  defer def get_users() do
    [user_1, user_2] =
      await [
        Lazyloader.get(:db, :get_user, 1),
        Lazyloader.get(:db, :get_user, 2)
      ]

    %{user_1: user_1, user_2: user_2}
  end

  def get_users(loader) do
    get_users()
    |> Defer.run(%{dataloader: loader})
  end
end

defmodule Meetup do
  alias Meetup.Database
  import Defer

  def resolve_user(id, loader) do
    loader
    |> Dataloader.load(:db, :get_user, id)
    |> on_load(fn loader ->
      user =
        Dataloader.get(
          loader,
          :db,
          :get_user,
          id
        )

      {:ok, user}
    end)
  end

  def on_load(loader, fun) do
    {:middleware, Absinthe.Middleware.Dataloader, {loader, fun}}
  end

  defmodule Users do
    def get(id) do
      Database.get_user(id)
    end

    def get_friend_ids(user_id) do
      Database.get_friend_ids(user_id)
    end
  end

  defmodule LazyUsers do
    import Defer

    defer def get(id) do
      Lazyloader.get(:db, :get_user, id)
    end

    defer def get_friend_ids(user_id) do
      Lazyloader.get(
        :db,
        :get_friend_ids,
        user_id
      )
    end
  end

  defer def lazy_load_user(id) do
    user = await LazyUsers.get(id)
    best_friend = await LazyUsers.get(user.best_friend_id)

    %{
      name: user.name,
      best_friend: %{
        name: best_friend.name
      }
    }
  end

  defer def lazy_load_profile(id) do
    me = await lazy_load_user(id)
    friend_ids = await LazyUsers.get_friend_ids(id)
    friends = await Enum.map(friend_ids, &lazy_load_user(&1))
    put_in(me[:friends], friends)
  end

  def load_user(id) do
    friend = Users.get(id)
    best_friend = Users.get(friend.best_friend_id)

    %{
      name: friend.name,
      best_friend: %{
        name: best_friend.name
      }
    }
  end

  def load_profile(id) do
    me = load_user(id)
    friend_ids = Users.get_friend_ids(id)
    friends = Enum.map(friend_ids, &load_user(&1))
    put_in(me[:friends], friends)
  end

  def output() do
    %{
      best_friend: %{name: "Leslie Russel"},
      friends: [
        %{
          best_friend: %{
            name: "Maximilian Leffler"
          },
          name: "Leslie Russel"
        },
        %{
          best_friend: %{name: "Jermain Hirthe"},
          name: "Magali Beatty"
        },
        %{
          best_friend: %{name: "Garfield Mills"},
          name: "Jermain Hirthe"
        },
        %{
          best_friend: %{name: "Leslie Russel"},
          name: "River Schuppe"
        },
        %{
          best_friend: %{name: "Bryon Hodkiewicz"},
          name: "Jeromy O'Reilly"
        }
      ],
      name: "Conrad Langosh"
    }
  end

  def main(["lazyloader"]) do
    source = Dataloader.KV.new(&query(&1, &2))

    loader =
      Dataloader.new()
      |> Dataloader.add_source(:db, source)

    lazy_load_profile(1)

    IO.inspect(
      Defer.run(lazy_load_profile(1), %{
        dataloader: loader
      })
    )
  end

  def main(_args) do
    IO.inspect(load_profile(1))
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
