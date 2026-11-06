module SeleniumServices
  module Lexica
    module CartFlow
      private

      def open_shop
        step("open_shop", "ショップを開く") do
          raise LexicaStop.new("missing_product_url", "商品URLが未設定です") if @product_url.blank?

          navigate @product_url
          wait_page_load_complete
        end
      end

      def add_to_cart
        step("add_to_cart", "カートに入れる") do
          raise LexicaStop.new("missing_sku", "SKUが未設定です") if @cart_skus.blank?

          @cart_skus.each { |sku| add_sku_to_cart(sku) }
          # #cart-view is on the cart host, not the LP. After AddItemToCart, ensure we are there.
          unless element_present?(S::CART_VIEW)
            navigate "#{cart_base_url}/"
            wait_page_load_complete
          end
          wait_element_load S::CART_VIEW
          reject_unknown_sku
        end
      end

      def reject_unknown_sku
        return unless @driver.page_source.to_s.include?("商品が見つかりません")

        raise LexicaStop.new("missing_sku", "商品コード（#{@cart_skus.join(",")}）の商品が見つかりません")
      end

      def add_sku_to_cart(sku)
        href = add_to_cart_href_for(sku)
        # Prefer cart-host AddItemToCart navigation — LP often has no window.n / #cart-view.
        if click_if_present(%(a[href="#{href}"]), "Add SKU #{sku}")
          wait_page_load_complete
          return
        end
        if @driver.execute_script("return !!(window.n && n.addItemToCart);")
          execute_script("n.addItemToCart(#{sku.to_json}, 1);")
          wait_page_load_complete
          return
        end

        navigate href
        wait_page_load_complete
      end

      def proceed_to_checkout
        step("proceed_to_checkout", "レジへ") do
          wait_element_load S::CART_VIEW
          if element_present?(S::CHECKOUT_BUTTON)
            click S::CHECKOUT_BUTTON, "checkout"
          elsif element_present?(S::CHECKOUT_BUTTON_ALT)
            click S::CHECKOUT_BUTTON_ALT, "checkout alt"
          else
            raise LexicaStop.new("empty_cart", "カートが空のためレジに進めません")
          end
          wait_page_load_complete
        end
      end

      def shop_to_checkout
        open_shop
        add_to_cart
        proceed_to_checkout
      end

      def add_to_cart_href
        add_to_cart_href_for(@sku)
      end

      def add_to_cart_href_for(sku)
        "#{cart_base_url}/Service/AddItemToCart/#{sku}/1"
      end

      def cart_base_url
        return @cart_url.sub(%r{/+\z}, "") if @cart_url.present?
        uri = URI.parse(@product_url) rescue nil
        return "#{uri.scheme}://#{uri.host}" if uri&.host&.include?("cart")

        "https://cart.mirai-japan.co.jp"
      end

      def signup_url
        "#{cart_base_url}/signup"
      end
    end
  end
end
