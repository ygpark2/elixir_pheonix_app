# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     AinCom.Repo.insert!(%AinCom.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias AinComBooking.Accounts.User
alias AinComBooking.CompanyConsole
alias AinComBooking.Repo

seed_users = [
  %{
    email: "user@ain.com",
    password: "12345",
    name: "YG Park",
    phone: "010-0000-0000",
    address: "Seoul",
    role: :user
  },
  %{
    email: "admin@ain.com",
    password: "admin!2026",
    name: "Seed Admin",
    phone: "010-1111-2222",
    address: "Busan",
    role: :admin
  },
  %{
    email: "company@ain.com",
    password: "company!2026",
    name: "Seed Company",
    phone: "010-2222-3333",
    address: "Incheon",
    role: :company
  }
]

legacy_email_typo = "ygaprk2@gmail.com"
canonical_email = "ygpark2@gmail.com"

case {Repo.get_by(User, email: legacy_email_typo), Repo.get_by(User, email: canonical_email)} do
  {%User{} = legacy_user, nil} ->
    legacy_user
    |> Ecto.Changeset.change(email: canonical_email)
    |> Repo.update!()

    IO.puts("Corrected legacy seed email: #{legacy_email_typo} -> #{canonical_email}")

  _ ->
    :ok
end

Enum.each(seed_users, fn attrs ->
  email = String.downcase(attrs.email)
  now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
  hashed_password = Bcrypt.hash_pwd_salt(attrs.password)

  seeded_user =
    case Repo.get_by(User, email: email) do
      nil ->
        user =
          %User{}
          |> Ecto.Changeset.change(%{
            email: email,
            hashed_password: hashed_password,
            name: attrs.name,
            phone: attrs.phone,
            address: attrs.address,
            role: attrs.role,
            feed_visibility: :public,
            confirmed_at: now
          })
          |> Repo.insert!()

        IO.puts("Inserted seed user: #{email}")
        user

      existing_user ->
        user =
          existing_user
          |> Ecto.Changeset.change(%{
            hashed_password: hashed_password,
            name: attrs.name,
            phone: attrs.phone,
            address: attrs.address,
            role: attrs.role,
            feed_visibility: :public,
            confirmed_at: now
          })
          |> Repo.update!()

        IO.puts("Updated seed user: #{email}")
        user
    end

  if attrs.role == :company do
    company = CompanyConsole.ensure_company!(seeded_user)

    IO.puts("Ensured seed company: #{company.name} (#{company.login})")
  end
end)
