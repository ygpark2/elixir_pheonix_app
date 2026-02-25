defmodule AinComBooking.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  alias AinComBooking.Repo
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.Changeset

  using do
    quote do
      import AinComBooking.DataCase
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      alias AinComBooking.Repo
    end
  end

  setup tags do
    :ok = Sandbox.checkout(Repo)

    if !tags[:async] do
      Sandbox.mode(Repo, {:shared, self()})
    end

    :ok
  end

  @doc """
  A helper that transform changeset errors to a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        rendered =
          if is_list(value) do
            Enum.map_join(value, ", ", &to_string/1)
          else
            to_string(value)
          end

        String.replace(acc, "%{#{key}}", rendered)
      end)
    end)
  end
end
