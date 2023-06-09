defmodule DemoWeb.Router do
  use DemoWeb, :router

  import DemoWeb.ArgonusersAuth

  pipeline :browser do
    plug :accepts, ["html", "text"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {DemoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_argonusers
    plug DemoWeb.Plugs.Locale, "en"
    plug :fetch_current_user
    plug :fetch_current_cart
  end

  pipeline :authreq do
    plug :fetch_current_argonusers
    plug :require_authenticated_argonusers
  end

  defp fetch_current_user(conn, _) do
    if user_uuid = get_session(conn, :current_uuid) do
      assign(conn, :current_uuid, user_uuid)
    else
      new_uuid = Ecto.UUID.generate()

      conn
      |> assign(:current_uuid, new_uuid)
      |> put_session(:current_uuid, new_uuid)
    end
  end

  alias Demo.ShoppingCart

  def fetch_current_cart(conn, _opts) do
    if cart = ShoppingCart.get_cart_by_user_uuid(conn.assigns.current_uuid) do
      assign(conn, :cart, cart)
    else
      {:ok, new_cart} = ShoppingCart.create_cart(conn.assigns.current_uuid)
      assign(conn, :cart, new_cart)
    end
  end
  # pipeline :auth do
  #   plug DemoWeb.Authentication
  # end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DemoWeb do
    pipe_through :browser

    get "/", PageController, :home

    pipe_through :authreq
    resources "/products", ProductController
    resources "/users", UserController
    get "/hello", HelloController, :index
    get "/hello/:messenger", HelloController, :show
    get "/redirect_test", PageController, :redirect_test
    resources "/cart_items", CartItemController, only: [:create, :delete]
    get "/cart", CartController, :show
    put "/cart", CartController, :update
    resources "/orders", OrderController, only: [:create, :show]

    #live "/", PageLive, :home

  end

  # Other scopes may use custom stacks.
  scope "/api", DemoWeb do
    pipe_through :api
    resources "/reviews", ReviewController
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:demo, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DemoWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", DemoWeb do
    pipe_through [:browser, :redirect_if_argonusers_is_authenticated]

    get "/argonusers/register", ArgonusersRegistrationController, :new
    post "/argonusers/register", ArgonusersRegistrationController, :create
    get "/argonusers/log_in", ArgonusersSessionController, :new
    post "/argonusers/log_in", ArgonusersSessionController, :create
    get "/argonusers/reset_password", ArgonusersResetPasswordController, :new
    post "/argonusers/reset_password", ArgonusersResetPasswordController, :create
    get "/argonusers/reset_password/:token", ArgonusersResetPasswordController, :edit
    put "/argonusers/reset_password/:token", ArgonusersResetPasswordController, :update
  end

  scope "/", DemoWeb do
    pipe_through [:browser, :require_authenticated_argonusers]

    get "/argonusers/settings", ArgonusersSettingsController, :edit
    put "/argonusers/settings", ArgonusersSettingsController, :update
    get "/argonusers/settings/confirm_email/:token", ArgonusersSettingsController, :confirm_email
  end

  scope "/", DemoWeb do
    pipe_through [:browser]

    delete "/argonusers/log_out", ArgonusersSessionController, :delete
    get "/argonusers/confirm", ArgonusersConfirmationController, :new
    post "/argonusers/confirm", ArgonusersConfirmationController, :create
    get "/argonusers/confirm/:token", ArgonusersConfirmationController, :edit
    post "/argonusers/confirm/:token", ArgonusersConfirmationController, :update
  end
end
