require 'test_helper'

class RemoteAsaptpTest < Test::Unit::TestCase
  

  def setup
    @gateway = AsaptpGateway.new(fixtures(:asaptp))
    
    @amount = 100
    @credit_card = credit_card('4111111111111111', { :verification_value => '123', :month => '03', :year => '2012' } )
    @credit_card_invalid_csv = credit_card('4111111111111111', { :verification_value => '321', :month => '03', :year => '2012' } )
    @declined_card = credit_card('4000300011112220')
    
    @options = { 
      :order_id => '33',
      :billing_address => address,
      :description => 'Store Purchase'
    }
  end
  
  def test_successful_purchase
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_equal 'Transaction was accepted successfully', response.message
  end

  def test_unsuccessful_purchase_with_invalid_verification_value
    assert response = @gateway.purchase(@amount, @credit_card_invalid_csv, @options.update(:order_id => '833'))
    assert_success response
    assert_equal 'Invalid card number', response.message
  end

  def test_unsuccessful_purchase_with_invalid_card_number
    assert response = @gateway.purchase(@amount, @declined_card, @options.update(:order_id => '933'))
    assert_failure response
    assert_equal 'Invalid card number', response.message
  end

  def test_invalid_login
    gateway = AsaptpGateway.new(
                :access_id => '', :merch_id => '', :secure_hash => '', :term_id => ''
              )
    assert response = gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert_equal 'Invalid identity', response.message
  end
end