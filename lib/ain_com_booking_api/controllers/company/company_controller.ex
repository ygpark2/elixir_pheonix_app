defmodule AinComBookingApi.Controllers.Company.CompanyController do
  use Phoenix.Controller
  use PhoenixSwagger

  import AinComBookingApi.Errors
  import Ecto.Query

  alias AinComBooking.Catalog.Company
  alias AinComBooking.Repo

  def swagger_paths do
    [
      :create,
      :update,
      :index,
      :delete
    ]
  end

  swagger_path :create do
    post("/company/companies")
    summary("Create company")
    description("Create a new company")
    produces("application/json")
    consumes("application/json")
    tag("Company / Company")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:company, :body, Schema.ref(:CompanyRequest), "Company attributes")

    response(201, "Company created", Schema.ref(:Company))
    response(422, "Invalid input")
  end

  def create(conn, params) do
    changeset = Company.changeset(%Company{}, params)

    case Repo.insert(changeset) do
      {:ok, company} ->
        conn
        |> put_status(:created)
        |> json(company)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
    end
  end

  swagger_path :update do
    patch("/company/companies/{id}")
    summary("Update a company")
    description("Updates company details")
    consumes("application/json")
    produces("application/json")
    tag("Company / Company")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:id, :path, :string, "Company ID", required: true)
    parameter(:company, :body, Schema.ref(:CompanyRequest), "Company attributes to update")

    response(200, "Company updated", Schema.ref(:Company))
    response(404, "Company not found")
    response(422, "Invalid input")
  end

  def update(conn, %{"id" => id} = params) do
    case Repo.get(Company, id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Company not found"})

      company ->
        changeset = Company.changeset(company, Map.delete(params, "id"))

        case Repo.update(changeset) do
          {:ok, updated_company} ->
            json(conn, updated_company)

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
        end
    end
  end

  swagger_path :index do
    get("/company/companies")
    produces("application/json")
    tag("Company / Company")

    AinComBookingApi.CommonParameters.authorization()
    AinComBookingApi.CommonParameters.sorting()
  end

  def index(conn, _params) do
    companies = Repo.all(Company)
    json(conn, companies)
  end

  swagger_path :delete do
    delete("/company/companies/{id}")
    summary("Delete company")
    produces("application/json")
    tag("Company / Company")

    AinComBookingApi.CommonParameters.authorization()

    parameter(:id, :path, :string, "Company ID", required: true)

    response(204, "Company deleted")
    response(404, "Company not found")
  end

  def remove(conn, %{"id" => id}) do
    case Repo.get(Company, id) do
      nil ->
        send_resp(conn, :not_found, "")

      company ->
        Repo.delete!(company)
        send_resp(conn, :no_content, "")
    end
  end

  def swagger_definitions do
    %{
      Company:
        swagger_schema do
          title("Company")
          description("Represents a company")

          properties do
            id(:string, "Company ID")
            name(:string)
            description_text(:string)
            address1(:string)
            email(:string)
            phone(:string)
            city(:string)
            country_id(:string)
            timezone(:string)
            logo(:string)
          end

          example(%{
            id: "abc123",
            name: "Acme Corp",
            description_text: "A leading provider of tech services",
            address1: "123 Main St",
            email: "contact@acme.com",
            phone: "123-456-7890",
            city: "Seoul",
            country_id: "KR",
            timezone: "Asia/Seoul",
            logo: "acme-logo.png"
          })
        end,
      CompanyRequest:
        swagger_schema do
          title("CompanyRequest")
          description("Payload for creating/updating a company")

          properties do
            name(:string, "Company name")
            description_text(:string, "Company description")
            address1(:string, "Company address1")
            email(:string, "Company email")
            phone(:string, "Company phone")
            city(:string, "Company address city")
            country_id(:string, "Company country code")
            timezone(:string, "Company timezone")
            logo(:string, "Company logo")
          end

          example(%{
            name: "Acme Corp",
            description_text: "A leading provider of tech services",
            address1: "123 Main St",
            email: "contact@acme.com",
            phone: "123-456-7890",
            city: "Seoul",
            country_id: "KR",
            timezone: "Asia/Seoul",
            logo: "acme-logo.png"
          })
        end
    }
  end
end
