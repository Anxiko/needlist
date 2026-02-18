defmodule Needlist.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Changeset
  alias Needlist.Repo.User
  alias Needlist.Repo

  alias Needlist.Accounts.{Account, AccountToken, AccountNotifier}

  ## Database getters

  @doc """
  Gets a account by email.

  ## Examples

      iex> get_account_by_email("foo@example.com")
      %Account{}

      iex> get_account_by_email("unknown@example.com")
      nil

  """
  @spec get_account_by_email(String.t()) :: Account.t() | nil
  def get_account_by_email(email) when is_binary(email) do
    Repo.get_by(Account, email: email) |> Repo.preload([:user])
  end

  @doc """
  Gets a account by email and password.

  ## Examples

      iex> get_account_by_email_and_password("foo@example.com", "correct_password")
      %Account{}

      iex> get_account_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  @spec get_account_by_email_and_password(String.t(), String.t()) :: Account.t() | nil
  def get_account_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    account = Repo.get_by(Account, email: email) |> Repo.preload([:user])
    if Account.valid_password?(account, password), do: account
  end

  @doc """
  Gets a single account.

  Raises `Ecto.NoResultsError` if the Account does not exist.

  ## Examples

      iex> get_account!(123)
      %Account{}

      iex> get_account!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_account!(integer()) :: Account.t()
  def get_account!(id), do: Repo.get!(Account, id) |> Repo.preload([:user])

  ## Account registration

  @doc """
  Registers a account.

  ## Examples

      iex> register_account(%{field: value})
      {:ok, %Account{}}

      iex> register_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec register_account(map()) :: {:ok, Account.t()} | {:error, Changeset.t(Account.t())}
  def register_account(attrs) do
    %Account{}
    |> Account.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking account changes.

  ## Examples

      iex> change_account_registration(account)
      %Ecto.Changeset{data: %Account{}}

  """
  # credo:disable-for-next-line
  def change_account_registration(%Account{} = account, attrs \\ %{}) do
    Account.registration_changeset(account, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the account email.

  ## Examples

      iex> change_account_email(account)
      %Ecto.Changeset{data: %Account{}}

  """
  @spec change_account_email(Account.t(), map()) :: Changeset.t(Account.t())
  @spec change_account_email(Account.t()) :: Changeset.t(Account.t())
  def change_account_email(account, attrs \\ %{}) do
    Account.email_changeset(account, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_account_email(account, "valid password", %{email: ...})
      {:ok, %Account{}}

      iex> apply_account_email(account, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  @spec apply_account_email(Account.t(), String.t(), map()) :: {:ok, Account.t()} | {:error, Changeset.t(Account.t())}
  def apply_account_email(account, password, attrs) do
    account
    |> Account.email_changeset(attrs)
    |> Account.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the account email using the given token.

  If the token matches, the account email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  @spec update_account_email(Account.t(), String.t()) :: :ok | :error
  def update_account_email(account, token) do
    context = "change:#{account.email}"

    with {:ok, query} <- AccountToken.verify_change_email_token_query(token, context),
         %AccountToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(account_email_multi(account, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  @spec associate_with_user(account :: Account.t(), user :: User.t()) ::
          {:ok, Account.t()} | {:error, Changeset.t(Account.t())}
  def associate_with_user(account, %User{id: id}) do
    account
    |> Account.associate_user_changeset(%{user_id: id})
    |> Repo.update()
  end

  @spec remove_associated_user(account :: Account.t()) :: {:ok, Account.t()} | {:error, Changeset.t(Account.t())}
  def remove_associated_user(account) do
    account
    |> Account.associate_user_changeset(%{user_id: nil})
    |> Repo.update()
  end

  defp account_email_multi(account, email, context) do
    changeset =
      account
      |> Account.email_changeset(%{email: email})
      |> Account.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:account, changeset)
    |> Ecto.Multi.delete_all(:tokens, AccountToken.by_account_and_contexts_query(account, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given account.

  ## Examples

      iex> deliver_account_update_email_instructions(account, current_email, &url(~p"/accounts/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  # credo:disable-for-next-line
  def deliver_account_update_email_instructions(%Account{} = account, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, account_token} = AccountToken.build_email_token(account, "change:#{current_email}")

    Repo.insert!(account_token)
    AccountNotifier.deliver_update_email_instructions(account, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the account password.

  ## Examples

      iex> change_account_password(account)
      %Ecto.Changeset{data: %Account{}}

  """
  @spec change_account_password(Account.t(), map()) :: Changeset.t(Account.t())
  def change_account_password(account, attrs \\ %{}) do
    Account.password_changeset(account, attrs, hash_password: false)
  end

  @doc """
  Updates the account password.

  ## Examples

      iex> update_account_password(account, "valid password", %{password: ...})
      {:ok, %Account{}}

      iex> update_account_password(account, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_account_password(Account.t(), String.t(), map()) ::
          {:ok, Account.t()} | {:error, Changeset.t(Account.t())}
  def update_account_password(account, password, attrs) do
    changeset =
      account
      |> Account.password_changeset(attrs)
      |> Account.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:account, changeset)
    |> Ecto.Multi.delete_all(:tokens, AccountToken.by_account_and_contexts_query(account, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{account: account}} -> {:ok, account}
      {:error, :account, changeset, _} -> {:error, changeset}
    end
  end

  @spec update_account_admin_flag(Account.t(), boolean()) ::
          {:ok, Account.t()} | {:error, Changeset.t(Account.t())}
  def update_account_admin_flag(account, admin) when is_boolean(admin) do
    account
    |> Account.set_admin_flag(admin)
    |> Repo.update()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  @spec generate_account_session_token(Account.t()) :: String.t()
  def generate_account_session_token(account) do
    {token, account_token} = AccountToken.build_session_token(account)
    Repo.insert!(account_token)
    token
  end

  @doc """
  Gets the account with the given signed token.
  """
  @spec get_account_by_session_token(String.t()) :: Account.t() | nil
  def get_account_by_session_token(token) do
    {:ok, query} = AccountToken.verify_session_token_query(token)
    Repo.one(query) |> Repo.preload([:user])
  end

  @doc """
  Deletes the signed token with the given context.
  """
  @spec delete_account_session_token(String.t()) :: :ok
  def delete_account_session_token(token) do
    Repo.delete_all(AccountToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given account.

  ## Examples

      iex> deliver_account_confirmation_instructions(account, &url(~p"/accounts/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_account_confirmation_instructions(confirmed_account, &url(~p"/accounts/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  # credo:disable-for-next-line
  def deliver_account_confirmation_instructions(%Account{} = account, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if account.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, account_token} = AccountToken.build_email_token(account, "confirm")
      Repo.insert!(account_token)
      AccountNotifier.deliver_confirmation_instructions(account, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a account by the given token.

  If the token matches, the account account is marked as confirmed
  and the token is deleted.
  """
  @spec confirm_account(String.t()) :: {:ok, Account.t()} | :error
  def confirm_account(token) do
    with {:ok, query} <- AccountToken.verify_email_token_query(token, "confirm"),
         %Account{} = account <- Repo.one(query),
         {:ok, %{account: account}} <- Repo.transaction(confirm_account_multi(account)) do
      {:ok, account}
    else
      _ -> :error
    end
  end

  defp confirm_account_multi(account) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:account, Account.confirm_changeset(account))
    |> Ecto.Multi.delete_all(:tokens, AccountToken.by_account_and_contexts_query(account, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given account.

  ## Examples

      iex> deliver_account_reset_password_instructions(account, &url(~p"/accounts/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  # credo:disable-for-next-line
  def deliver_account_reset_password_instructions(%Account{} = account, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, account_token} = AccountToken.build_email_token(account, "reset_password")
    Repo.insert!(account_token)
    AccountNotifier.deliver_reset_password_instructions(account, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the account by reset password token.

  ## Examples

      iex> get_account_by_reset_password_token("validtoken")
      %Account{}

      iex> get_account_by_reset_password_token("invalidtoken")
      nil

  """
  # credo:disable-for-next-line
  def get_account_by_reset_password_token(token) do
    with {:ok, query} <- AccountToken.verify_email_token_query(token, "reset_password"),
         %Account{} = account <- Repo.one(query) do
      account
    else
      _ -> nil
    end
  end

  @doc """
  Resets the account password.

  ## Examples

      iex> reset_account_password(account, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Account{}}

      iex> reset_account_password(account, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  # credo:disable-for-next-line
  def reset_account_password(account, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:account, Account.password_changeset(account, attrs))
    |> Ecto.Multi.delete_all(:tokens, AccountToken.by_account_and_contexts_query(account, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{account: account}} -> {:ok, account}
      {:error, :account, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Forces a password update for the account with the given email.
  """
  @spec force_password_for_email(email :: String.t(), password :: String.t()) ::
          {:ok, Account.t()} | {:error, any()}
  def force_password_for_email(email, password) do
    case get_account_by_email(email) do
      %Account{} = account ->
        account
        |> Account.password_changeset(%{password: password, password_confirmation: password})
        |> Repo.update()

      nil ->
        {:error, :not_found}
    end
  end
end
