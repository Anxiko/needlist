# credo:disable-for-this-file
defmodule NeedlistWeb.AccountAuth do
  use NeedlistWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias Needlist.Repo.User
  alias Needlist.Accounts
  alias Needlist.Accounts.Account

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in AccountToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_needlist_web_account_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the account in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_account(conn, account, params \\ %{}) do
    token = Accounts.generate_account_session_token(account)
    account_return_to = get_session(conn, :account_return_to)

    conn
    |> renew_session()
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: account_return_to || signed_in_path(conn))
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the account out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_account(conn) do
    account_token = get_session(conn, :account_token)
    account_token && Accounts.delete_account_session_token(account_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      NeedlistWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  @doc """
  Authenticates the account by looking into the session
  and remember me token.
  """
  def fetch_current_account(conn, _opts) do
    {account_token, conn} = ensure_account_token(conn)
    account = account_token && Accounts.get_account_by_session_token(account_token)
    assign(conn, :current_account, account)
  end

  defp ensure_account_token(conn) do
    if token = get_session(conn, :account_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Handles mounting and authenticating the current_account in LiveViews.

  ## `on_mount` arguments

    * `:mount_current_account` - Assigns current_account
      to socket assigns based on account_token, or nil if
      there's no account_token or no matching account.

    * `:ensure_authenticated` - Authenticates the account from the session,
      and assigns the current_account to socket assigns based
      on account_token.
      Redirects to login page if there's no logged account.

    * `:redirect_if_account_is_authenticated` - Authenticates the account from the session.
      Redirects to signed_in_path if there's a logged account.

  ## Examples

  Use the `on_mount` lifecycle macro in LiveViews to mount or authenticate
  the current_account:

      defmodule NeedlistWeb.PageLive do
        use NeedlistWeb, :live_view

        on_mount {NeedlistWeb.AccountAuth, :mount_current_account}
        ...
      end

  Or use the `live_session` of your router to invoke the on_mount callback:

      live_session :authenticated, on_mount: [{NeedlistWeb.AccountAuth, :ensure_authenticated}] do
        live "/profile", ProfileLive, :index
      end
  """
  def on_mount(:mount_current_account, _params, session, socket) do
    {:cont, mount_current_account(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_account(socket, session)

    if socket.assigns.current_account do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/accounts/log_in")

      {:halt, socket}
    end
  end

  def on_mount(:redirect_if_account_is_authenticated, _params, session, socket) do
    socket = mount_current_account(socket, session)

    if socket.assigns.current_account do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  def on_mount(:authenticated_with_linked_user, %{"username" => username}, session, socket) do
    socket = mount_current_account(socket, session)

    case socket.assigns.current_account do
      nil ->
        socket =
          socket
          |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
          |> Phoenix.LiveView.redirect(to: ~p"/accounts/log_in")

        {:halt, socket}

      %Account{user: nil} ->
        socket =
          socket
          |> Phoenix.LiveView.put_flash(:error, "You must first link your Discogs account.")
          |> Phoenix.LiveView.redirect(to: ~p"/accounts/settings")

        {:halt, socket}

      %Account{user: %User{username: ^username}} ->
        {:cont, socket}

      %Account{user: %User{username: other_username}} ->
        socket =
          socket
          |> Phoenix.LiveView.put_flash(:error, "You may only see your own needlist.")
          |> Phoenix.LiveView.redirect(to: ~p"/needlist/#{other_username}")

        {:halt, socket}
    end
  end

  defp mount_current_account(socket, session) do
    Phoenix.Component.assign_new(socket, :current_account, fn ->
      if account_token = session["account_token"] do
        Accounts.get_account_by_session_token(account_token)
      end
    end)
  end

  @doc """
  Used for routes that require the account to not be authenticated.
  """
  def redirect_if_account_is_authenticated(conn, _opts) do
    if conn.assigns[:current_account] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the account to be authenticated.

  If you want to enforce the account email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_account(conn, _opts) do
    if conn.assigns[:current_account] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/accounts/log_in")
      |> halt()
    end
  end

  def require_admin(conn, _opts) do
    case conn.assigns[:current_account] do
      %Account{admin: true} ->
        conn

      %Account{admin: false} ->
        conn
        |> put_flash(:error, "You must be an admin to access this page.")
        |> redirect(to: signed_in_path(conn))
        |> halt()

      nil ->
        conn
        |> put_flash(:error, "You must log in to access this page.")
        |> maybe_store_return_to()
        |> redirect(to: ~p"/accounts/log_in")
        |> halt()
    end
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:account_token, token)
    |> put_session(:live_socket_id, "accounts_sessions:#{Base.url_encode64(token)}")
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :account_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: ~p"/"
end
