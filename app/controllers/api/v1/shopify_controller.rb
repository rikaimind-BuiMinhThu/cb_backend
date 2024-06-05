class Api::V1::ShopifyController < ApplicationController
  skip_before_action :permision, only: [:cart_create, :cart_lines_add, :webhook]
  skip_before_action :verify_authenticity_token, only: [:cart_create, :cart_lines_add, :webhook]
  before_action :set_admin_client, only: [:product_variants, :product_variant]
  before_action :set_storefront_client, only: [:cart_create, :cart_lines_add]

  def product_variants
    cursor = params[:cursor]
    num_products = 10

    query = <<~QUERY
      query ($numProducts: Int!, $cursor: String) {
        productVariants(first: $numProducts, after: $cursor) {
          pageInfo {
            hasNextPage
            endCursor
          }
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

    response = @client.query(query:, variables: {
      numProducts: num_products,
      cursor: cursor,
    })
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
    uuid = params['uuid'] || ''
    email = params['email'] || ''
    phone = params['phone'] || ''
    first_name = params['first_name'] || ''
    last_name = params['last_name'] || ''
    lines = params['lines'] || []
    zip = params['zip'] || ""
    province = params['province'] || ''
    city = params['city'] || ''
    address1 = params['address1'] || ''
    address2 = params['address2'] || ''

    query = <<~GRAPHQL
      mutation cartCreate($cartInput: CartInput!) {
        cartCreate(input: $cartInput) {
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
                      title
                      product {
                        title
                      }
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
                  zip
                  city
                  province
                  provinceCode
                  countryCodeV2
                  address1
                  address2
                  firstName
                  lastName
                  name
                  formattedArea
                  phone
                }
              }
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
      cartInput: {
        lines: lines,
        buyerIdentity: {
          email: email,
          countryCode: "JP",
          deliveryAddressPreferences: {
            deliveryAddress: {
              country: "JP",
              firstName: first_name,
              lastName: last_name,
              zip: zip,
              province: province,
              city: city,
              address1: address1,
              address2: address2,
              phone: phone
            }
          }
        }
      }
    })

    if response.code == 200 && response.body['data'] && response.body['data']['cartCreate'] && response.body['data']['cartCreate']["cart"] && response.body['data']['cartCreate']["cart"]['id']
      cart_id = response.body['data']['cartCreate']["cart"]['id']
      cart_system = CartSystem.new(cart_token: cart_id, uid: uuid, user_id: @user.id)
      cart_system.save
    end

    handle_response(response)
  end

  def cart_lines_add
    cart_id = params['cart_id'] || ''
    lines = params['lines'] || []

    cart_system = CartSystem.new(cart_token: cart_id, uid: params[:uuid], user_id: @user.id)
    cart_system.save

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
    # ActionCable.server.broadcast 'ShopifyChannel', cart_token

    # cart_system = CartSystem.find_by_cart_token(cart_token)
    cart_system = CartSystem.where(cart_token: cart_token).first
    Rails.logger.info "Cart system: #{cart_system.inspect}"

    if cart_system
      user = User.find_by_id(cart_system.user_id)
      scenario_user_response = ScenarioUserResponse.find_by_user_input_id(cart_system.uid)

      Order.create(
        client_id: user.client_id,
        scenario_id: scenario_user_response.scenario_id,
        user_input_id: cart_system.uid,
        bot_type: 'web'
      )
      payment_system = PaymentSystem.find_by_name("Shopify Payment")
      cart_payment_system = CartPaymentSystem.find_by_user_id(cart_system.user_id)

      if cart_payment_system
        cart_payment_system.cart_system_ids += [cart_system.id]
        cart_payment_system.save
        ShopifyOrder.create(cart_payment_system_id: cart_payment_system.id, order_id: params["id"], data: data.inspect)
      else
        new_cart_payment_system = CartPaymentSystem.new(user_id: cart_system.user_id, payment_system_id: payment_system.id)
        new_cart_payment_system.cart_system_ids += [cart_system.id]
        new_cart_payment_system.save
        ShopifyOrder.create(cart_payment_system_id: new_cart_payment_system.id, order_id: params["id"], data: data.inspect)
      end
    end

    render json: { message: 'Received Shopify webhook' }, status: :ok
  end

  def set_admin_client
    user = User.find(current_user.id)
    shopify_api_key = user.shopify_api_key
    shop_name = user.shop_name

    #  Rikai Shopify
    # session = ShopifyAPI::Auth::Session.new(
    #   shop: 'deel-ja-store.myshopify.com',
    #   access_token: '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'
    # )

    # # AKS Shopify
    # session = ShopifyAPI::Auth::Session.new(
    #   shop: 'aks-teletherapy.myshopify.com',
    #   access_token: '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'
    # )

    # Playland Shopify
    session = ShopifyAPI::Auth::Session.new(
      shop: Rails.application.secrets.shop_name,
      access_token: Rails.application.secrets.access_token
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

    # Rikai Shopify
    # shop = 'deel-ja-store.myshopify.com'
    # storefront_access_token = '20788c67b5dcd406a24e6a19f063a013'
    # api_version = 'unstable'

    # AKS Shopify
    # shop = 'aks-teletherapy.myshopify.com'
    # storefront_access_token = '7fe4560ee50e5773276d45ed209ecb76'
    # api_version = 'unstable'

    # Playland Shopify
    shop = Rails.application.secrets.shop_name
    storefront_access_token = Rails.application.secrets.storefront_access_token
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
