require 'test_helper'

class AsaptpTest < Test::Unit::TestCase
  def setup
    @gateway = AsaptpGateway.new(
                 :access_id => 'access_id',
                 :merch_id => 'merch_id',
                 :secure_hash => 'secure_hash',
                 :term_id => 'term_id'
               )

    @credit_card = credit_card
    @amount = 100
    
    @options = { 
      :order_id => '1',
      :description => 'Store Purchase'
    }
  end
  
  def test_successful_purchase
    @gateway.expects(:ssl_post).returns(successful_purchase_response)
    
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_instance_of Response, response 
    assert_success response
    
    # Replace with authorization number from the successful response
    puts response.inspect
    puts response.authorization
    assert_equal '102', response.authorization
    assert response.test?
  end

  def test_unsuccessful_request
    @gateway.expects(:ssl_post).returns(failed_purchase_response)
    
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert response.test?
  end

  private
  
  # Place raw successful response from gateway here
  def successful_purchase_response
    <<-RESPONSE
    <?xml version="1.0" encoding="UTF-8"?>

    <report>
      <txn_message>Transaction was accepted successfully</txn_message>
      <merch_id>merch_id</merch_id>
      <auth_id>135323</auth_id>
      <locale>en_us</locale>
      <term_id>TERM_0001</term_id>
      <merch_order_id>1</merch_order_id>
      <card_num>************1111</card_num>
      <txn_time>20110815143159</txn_time>
      <merch_txn_id>1</merch_txn_id>
      <currency>344</currency>
      <version>1.0</version>
      <amount>100</amount>
      <secure_hash>test</secure_hash>
      <pay_type>VC</pay_type>
      <txn_status>ACCEPTED</txn_status>
      <action>SALE_CARD</action>
      <txn_no>1001108154926028</txn_no>
      <txn_response_code>0</txn_response_code>
    </report>
    RESPONSE
  end
  
  # Place raw failed response from gateway here
  def failed_purchase_response
    <<-RESPONSE
    <?xml version="1.0" encoding="UTF-8"?>

    <report>
      <txn_message>Error from Novapay</txn_message>
      <merch_id>merch_id</merch_id>
      <locale>en_us</locale>
      <term_id>TERM_0001</term_id>
      <merch_order_id>2</merch_order_id>
      <card_num>************1111</card_num>
      <txn_time>20110811182130</txn_time>
      <merch_txn_id>2</merch_txn_id>
      <currency>344</currency>
      <version>1.0</version>
      <amount>100</amount>
      <secure_hash>test</secure_hash>
      <pay_type>VC</pay_type>
      <txn_status>ERROR</txn_status>
      <action>SALE_CARD</action>
      <txn_no>1001108114925894</txn_no>
      <txn_response_code>2000</txn_response_code>
    </report>
    RESPONSE
  end
end
