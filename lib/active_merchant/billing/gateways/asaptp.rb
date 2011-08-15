module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class AsaptpGateway < Gateway
      URL = 'https://uat.novapay.net/ecommerce-web/pay2p'
      VERSION = '1.0'
      
      # The countries the gateway supports merchants from as 2 digit ISO country codes
      self.supported_countries = ['HK']
      
      # The card types supported by the payment gateway
      self.supported_cardtypes = [:visa, :master, :american_express, :discover]
      
      # The homepage URL of the gateway
      self.homepage_url = 'http://www.asaptp.net'
      
      # The name of the gateway
      self.display_name = 'ASAP Transaction Processing'

      self.default_currency = 'HKK'

      self.money_format = :cents
      
      def initialize(options = {})
        requires!(options, :access_id, :merch_id, :secure_hash, :term_id)
        @options = options
        super
      end  
      
      def authorize(money, credit_card, options = {})
        post = {}
        add_invoice(post, options)
        add_credit_card(post, credit_card)
        add_address(post, credit_card, options)
        add_customer_data(post, options)
        
        commit('authonly', money, post)
      end
      
      def purchase(money, credit_card, options = {})
        post = {}
        post[:action]     = 'SALE_CARD'
        post[:merch_order_id] = options[:order_id]
        post[:amount] = money
        post[:currency] = '344'
        add_invoice(post, options)
        add_credit_card(post, credit_card)
        add_address(post, credit_card, options)   
        add_customer_data(post, options)
             
        commit('sale', money, post)
      end
    
      def capture(money, authorization, options = {})
        commit('capture', money, post)
      end
    
      private                       
      
      def add_customer_data(post, options)
      end

      def add_address(post, credit_card, options)      
      end

      def add_invoice(post, options)
      end
      
      def add_credit_card(post, credit_card)
        post[:card_num]     = credit_card.number
        post[:csc]            = credit_card.verification_value
        post[:expiry_date]    = expdate(credit_card)
        post[:pay_type]        = 'CC'
      end

      def successful?(response)
        params = response.clone
        params.delete(:secure_hash)
        return false if OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new('sha1'), options[:secure_hash], Hash[params.sort].values.join) != response[:secure_hash]
        return true if response[:txn_status] == 'ACCEPTED'
        false
      end
      
      def parse(body)
        puts body
        response = {}
        xml = REXML::Document.new(body)
        xml.elements.each('//report/*') do |node|
          response[node.name.to_sym] = node.text
        end unless xml.root.nil?
        response
      end     
      
      def commit(action, money, parameters)
        response = parse(ssl_post(URL, post_data(action, parameters)))

        Response.new(successful?(response), message_from(response), response,
          :authorization => response[:merch_txn_id]
        )
      end

      def message_from(response)
        response[:txn_message]
      end
      
      def post_data(action, parameters = {})
        parameters[:access_id] = @options[:access_id]
        parameters[:merch_id] = @options[:merch_id]
        parameters[:term_id] = @options[:term_id]
        parameters[:version] = VERSION
        parameters[:secure_hash] = generate_secure_hash(parameters)

        parameters.collect { |key, value| "#{key}=#{CGI.escape(value.to_s)}" }.join("&")
      end


      def generate_secure_hash(parameters)
        OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new('sha1'), options[:secure_hash], Hash[parameters.sort].values.join )
      end

      def expdate(credit_card)
        year  = format(credit_card.year, :two_digits)
        month = format(credit_card.month, :two_digits)

        "#{month}#{year}"
      end

    end
  end
end

