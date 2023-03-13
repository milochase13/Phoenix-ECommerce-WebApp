defmodule Demo.Repo.Migrations.CreateArgonusersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:argonusers) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:argonusers, [:email])

    create table(:argonusers_tokens) do
      add :argonusers_id, references(:argonusers, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:argonusers_tokens, [:argonusers_id])
    create unique_index(:argonusers_tokens, [:context, :token])
  end
end
