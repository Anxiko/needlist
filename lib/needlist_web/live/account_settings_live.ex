defmodule NeedlistWeb.AccountSettingsLive do
  require Logger
  alias Needlist.Discogs
  alias Needlist.Repo.User
  alias Needlist.Accounts.Account
  use NeedlistWeb, :live_view

  alias Needlist.Accounts

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Account Settings
      <:subtitle>Manage your account email address and password settings</:subtitle>
    </.header>

    <div class="space-y-12 divide-y">
      <div>
        <.link_to_discogs account={@current_account} />
      </div>
      <div>
        <.simple_form for={@email_form} id="email_form" phx-submit="update_email" phx-change="validate_email">
          <.input field={@email_form[:email]} type="email" label="Email" required />
          <.input
            field={@email_form[:current_password]}
            name="current_password"
            id="current_password_for_email"
            type="password"
            label="Current password"
            value={@email_form_current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Email</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form
          for={@password_form}
          id="password_form"
          action={~p"/accounts/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <input name={@password_form[:email].name} type="hidden" id="hidden_account_email" value={@current_email} />
          <.input field={@password_form[:password]} type="password" label="New password" required />
          <.input field={@password_form[:password_confirmation]} type="password" label="Confirm new password" />
          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label="Current password"
            id="current_password_for_password"
            value={@current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Password</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_account_email(socket.assigns.current_account, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/accounts/settings")}
  end

  def mount(_params, _session, socket) do
    account = socket.assigns.current_account
    email_changeset = Accounts.change_account_email(account)
    password_changeset = Accounts.change_account_password(account)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, account.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "account" => account_params} = params

    email_form =
      socket.assigns.current_account
      |> Accounts.change_account_email(account_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "account" => account_params} = params
    account = socket.assigns.current_account

    case Accounts.apply_account_email(account, password, account_params) do
      {:ok, applied_account} ->
        Accounts.deliver_account_update_email_instructions(
          applied_account,
          account.email,
          &url(~p"/accounts/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "account" => account_params} = params

    password_form =
      socket.assigns.current_account
      |> Accounts.change_account_password(account_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "account" => account_params} = params
    account = socket.assigns.current_account

    case Accounts.update_account_password(account, password, account_params) do
      {:ok, account} ->
        password_form =
          account
          |> Accounts.change_account_password(account_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("unlink", _params, socket) do
    socket =
      with {:ok, _account} <- Accounts.remove_associated_user(socket.assigns.current_account) do
        push_navigate(socket, to: ~p"/accounts/settings")
      else
        {:error, error} ->
          Logger.warning("Failed to unlink Discogs from account: #{inspect(error)}", error: error)
          put_flash(socket, :error, "Failed to unlink user")
      end

    {:noreply, socket}
  end

  defp link_to_discogs(%{account: %Account{user: nil}} = assigns) do
    ~H"""
    <div>
      <div class="text-zinc-800 block text-sm font-semibold leading-6 dark:text-white mb-8">
        No Discogs account linked
      </div>
      <a
        href={~p"/oauth/login"}
        class={[
          "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
          "text-sm font-semibold leading-6 text-white active:text-white/80"
        ]}
      >
        Link to Discogs
      </a>
    </div>
    """
  end

  defp link_to_discogs(%{account: %Account{user: %User{}}} = assigns) do
    ~H"""
    <div>
      <div class="text-zinc-800 block text-sm font-semibold leading-6 dark:text-white">
        Linked to Discogs account {@account.user.username}
      </div>
      <.button phx-click="unlink">
        Unlink Discogs
      </.button>
    </div>
    """
  end

  defp link_to_discogs(assigns) do
    ~H"""
    {inspect(assigns.account)}
    """
  end
end
