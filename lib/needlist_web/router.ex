defmodule NeedlistWeb.Router do
  use NeedlistWeb, :router

  import Oban.Web.Router
  import NeedlistWeb.AccountAuth
  import NeedlistWeb.ApiAuth, only: [verify_api_conn: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {NeedlistWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_account
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :verify_api_conn
  end

  scope "/", NeedlistWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/needlist", NeedlistWeb do
    pipe_through [:browser, :require_authenticated_account]

    live_session :authenticated_with_linked_user, on_mount: {NeedlistWeb.AccountAuth, :authenticated_with_linked_user} do
      live "/:username", NeedlistLive
    end
  end

  scope "/oauth", NeedlistWeb do
    pipe_through [:browser, :require_authenticated_account]

    get "/login", OauthController, :request

    get "/callback", OauthController, :callback
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:needlist, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: NeedlistWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end

    scope "/" do
      pipe_through :browser

      oban_dashboard("/oban")
    end
  end

  ## Authentication routes

  scope "/", NeedlistWeb do
    pipe_through [:browser, :redirect_if_account_is_authenticated]

    live_session :redirect_if_account_is_authenticated,
      on_mount: [{NeedlistWeb.AccountAuth, :redirect_if_account_is_authenticated}] do
      live "/accounts/register", AccountRegistrationLive, :new
      live "/accounts/log_in", AccountLoginLive, :new
      live "/accounts/reset_password", AccountForgotPasswordLive, :new
      live "/accounts/reset_password/:token", AccountResetPasswordLive, :edit
    end

    post "/accounts/log_in", AccountSessionController, :create
  end

  scope "/", NeedlistWeb do
    pipe_through [:browser, :require_authenticated_account]

    live_session :require_authenticated_account,
      on_mount: [{NeedlistWeb.AccountAuth, :ensure_authenticated}] do
      live "/accounts/settings", AccountSettingsLive, :edit
      live "/accounts/settings/confirm_email/:token", AccountSettingsLive, :confirm_email
    end
  end

  scope "/", NeedlistWeb do
    pipe_through [:browser]

    delete "/accounts/log_out", AccountSessionController, :delete

    live_session :current_account,
      on_mount: [{NeedlistWeb.AccountAuth, :mount_current_account}] do
      live "/accounts/confirm/:token", AccountConfirmationLive, :edit
      live "/accounts/confirm", AccountConfirmationInstructionsLive, :new
    end
  end

  scope "/api/tasks", NeedlistWeb do
    pipe_through :api

    post "/wantlist", TasksController, :wantlist

    post "/listings", TasksController, :listings
  end
end
