class Api::V1::ShopifyController < ApplicationController
  skip_before_action :permision, only: [:cart_create, :cart_lines_add, :webhook]
  skip_before_action :verify_authenticity_token, only: [:cart_create, :cart_lines_add, :webhook]
  before_action :set_admin_client, only: [:product_variants, :product_variant]
  before_action :set_storefront_client, only: [:cart_create, :cart_lines_add]

  def product_variants
    query = <<~QUERY
      query {
        productVariants(first: 10) {
          edges {
            node {
              id
              price
              displayName
              availableForSale
              inventoryQuantity
              product {
                id
                description
                onlineStoreUrl
              }
            }
          }
        }
      }
    QUERY

    response = @client.query(query:)
    handle_response(response)
  end

  def product_variant
    id = params[:id]

    if id.present?
      query = <<~QUERY
        query {
          productVariant(id: "#{id}") {
            id
            price
            displayName
            availableForSale
            inventoryQuantity
            product {
              id
              description
              onlineStoreUrl
            }
          }
        }
      QUERY

      response = @client.query(query:)
      handle_response(response)
    else
      render json: { success: false, error: 'Missing parameter: id' }, status: :unprocessable_entity
    end
  end

  def cart_create
    email = params['email'] || ''
    first_name = params['first_name'] || ''
    last_name = params['last_name'] || ''

    query = <<~GRAPHQL
      mutation {
        cartCreate(
          input: {
            lines: [],
            buyerIdentity: {
              email: "#{email}",
              countryCode: JP,
              deliveryAddressPreferences: {
                deliveryAddress: {
                  country: "JP",
                  firstName: "#{first_name}",
                  lastName: "#{last_name}",
                },
              }
            }
          }
        ) {
          cart {
            id
            createdAt
            updatedAt
            lines(first: 10) {
              edges {
                node {
                  id
                  merchandise {
                    ... on ProductVariant {
                      id
                    }
                  }
                }
              }
            }
            buyerIdentity {
              email
              phone
              deliveryAddressPreferences {
                ... on MailingAddress {
                  address1
                  address2
                  city
                  provinceCode
                  countryCodeV2
                  zip
                  firstName
                  lastName
                  name
                }
              }
            }
            attributes {
              key
              value
            }
            checkoutUrl
            totalQuantity
            cost {
              totalAmount {
                amount
                currencyCode
              }
              subtotalAmount {
                amount
                currencyCode
              }
              totalTaxAmount {
                amount
                currencyCode
              }
              totalDutyAmount {
                amount
                currencyCode
              }
            }
          }
        }
      }
    GRAPHQL

    response = @client.query(query:)
    handle_response(response)
  end

  def cart_lines_add
    cart_id = params['cart_id'] || ''
    lines = params['lines'] || []

    CartSystem.create(cart_token: cart_id, uid: params[:uuid], user_id: @user.id)

    query = <<~GRAPHQL
      mutation cartLinesAdd($cartId: ID!, $lines: [CartLineInput!]!) {
        cartLinesAdd(cartId: $cartId, lines: $lines) {
          cart {
            id
            createdAt
            updatedAt
            lines(first: 10) {
              edges {
                node {
                  id
                  merchandise {
                    ... on ProductVariant {
                      id
                    }
                  }
                }
              }
            }
            buyerIdentity {
              email
              phone
              deliveryAddressPreferences {
                ... on MailingAddress {
                  address1
                  address2
                  city
                  provinceCode
                  countryCodeV2
                  zip
                  firstName
                  lastName
                  name
                }
              }
            }
            attributes {
              key
              value
            }
            checkoutUrl
            totalQuantity
            cost {
              totalAmount {
                amount
                currencyCode
              }
              subtotalAmount {
                amount
                currencyCode
              }
              totalTaxAmount {
                amount
                currencyCode
              }
              totalDutyAmount {
                amount
                currencyCode
              }
            }
          }
        }
      }
    GRAPHQL

    response = @client.query(query:, variables: {
      cartId: cart_id,
      lines: lines
    })
    handle_response(response)
  end

  def webhook
    data = JSON.parse(request.body.read)
    cart_token = "gid://shopify/Cart/#{params['cart_token']}"
    Rails.logger.info "Received Shopify order webhook: #{data.inspect}"
    ActionCable.server.broadcast 'ShopifyChannel', cart_token

    cart_system = CartSystem.find_by_cart_token(cart_token)
    Rails.logger.info cart_system.inspect


    render json: { message: 'Received Shopify webhook' }, status: :ok
  end

  def set_admin_client
    user = User.find(current_user.id)
    shopify_api_key = user.shopify_api_key
    shop_name = user.shop_name
    session = ShopifyAPI::Auth::Session.new(
      shop: 'deel-ja-store.myshopify.com',
      access_token: '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'
    )
    @client = ShopifyAPI::Clients::Graphql::Admin.new(
      session:
    )
  end

  def set_storefront_client
    @scenario = Scenario.find_by_id(params[:scenario_id])
    @user = @scenario.chatbot&.user
    shop_name = @user.shop_name
    storefront_access_token = @user.storefront_access_token
    shop = 'deel-ja-store.myshopify.com'
    storefront_access_token = '20788c67b5dcd406a24e6a19f063a013'
    api_version = 'unstable'

    @client = ShopifyAPI::Clients::Graphql::Storefront.new(
      shop,
      storefront_access_token,
      api_version:
    )
  end

  def handle_response(response)
    if response.code == 200
      return render json: { success: true, message: 'Successfully',
                            data: response.body['data'] } if response.body['data']

      render json: { success: false, message: 'Error', data: response.body['errors'] }
    else
      render json: { success: false, message: 'Failed' }
    end
  end
end
